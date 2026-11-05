#!/usr/bin/env bash

# Gate an `/implement` run. Called by the gate job of
# .github/workflows/implement-issue.yml.
#
# ISSUE_NUMBER is an issue or a pull request; GitHub numbers both from one
# sequence. On an issue the run implements it and opens a pull request. On a
# pull request the run revises that pull request, whoever opened it and whether
# or not it has an issue: the agent addresses the review on it and pushes to
# its branch, which must be in this repository.
#
# It decides whether the run may proceed, and when it may, writes the request
# for the agent to .jaiph/tmp/request.json and acknowledges on the issue or
# pull request. The request holds links, not content: the agent reads the
# issue, the pull request, and the review itself, with a read-only token.
# Every refusal exits non-zero, so the rest of the run is skipped.
#
# Reads from the environment: EVENT_NAME, COMMENT_BODY, ADDITIONAL_INPUT,
# ISSUE_NUMBER, TRIGGER_ACTOR, COMMENT_ID, RUN_URL, GH_TOKEN,
# GITHUB_REPOSITORY, GITHUB_OUTPUT, AI_ALLOWED_ACTORS.
#
# Writes these step outputs:
#   mode          `implement` for an issue, `revise` for a pull request
#   title         implement only: the issue title, used as the pull request title
#   issue_number  implement only: the issue being implemented
#   head_ref      revise only: the pull request branch to check out and push to

set -euo pipefail

# 1. Verify the caller has write access to the repo, or is listed in the
#    AI_ALLOWED_ACTORS variable — a comma-separated list of logins, which lets a
#    maintainer hand the bot to a contributor without write access. The workflow
#    `if` only looks at the comment body, and does not filter workflow_dispatch
#    at all, so this is the one authoritative permission check.
#    Spaces around the commas are tolerated, and logins compare case-insensitively.
allowed=",${AI_ALLOWED_ACTORS:-},"
allowed="${allowed//[[:space:]]/}"
if [[ "${allowed,,}" != *",${TRIGGER_ACTOR,,},"* ]]; then
  permission="$(gh api "repos/${GITHUB_REPOSITORY}/collaborators/${TRIGGER_ACTOR}/permission" --jq '.permission')"
  if [[ ! "$permission" =~ ^(admin|maintain|write)$ ]]; then
    echo "${TRIGGER_ACTOR} has '${permission}' permission and is not in AI_ALLOWED_ACTORS; write access is required." >&2
    exit 1
  fi
fi

# 2. Collect the instructions for the agent. On a comment, the first line is
#    the command; steering may follow it on that same line, on later lines, or
#    both. Comments written in the web UI arrive with CRLF line endings.
if [ "$EVENT_NAME" = "workflow_dispatch" ]; then
  additional="${ADDITIONAL_INPUT:-}"
else
  body="$(printf '%s\n' "$COMMENT_BODY" | tr -d '\r')"
  first_line="$(printf '%s\n' "$body" | head -n 1)"

  # The workflow `if` only tests the prefix, so `/implementation ...` reaches
  # this point. The command has to be the whole first word.
  if [[ ! "$first_line" =~ ^/implement([[:space:]]|$) ]]; then
    echo "Comment does not start with the /implement command." >&2
    exit 1
  fi

  # `sed '/./,$!d'` drops the blank first line left behind when the command
  # stands alone, so the payload does not open with empty steering.
  same_line="${first_line#/implement}"
  additional="$(printf '%s\n%s\n' "${same_line# }" \
    "$(printf '%s\n' "$body" | tail -n +2)" | sed '/./,$!d')"
fi

# 3. Verify the number; on workflow_dispatch it is free-form input. Then work
#    out whether it names an issue or a pull request.
if [[ ! "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Invalid issue number: ${ISSUE_NUMBER}" >&2
  exit 1
fi

# The issues endpoint answers for pull requests too, so one lookup tells the
# two apart; a number that is neither stops the run here.
if ! is_pr="$(gh api "repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}" --jq 'has("pull_request")')"; then
  echo "#${ISSUE_NUMBER} is not an issue or a pull request in ${GITHUB_REPOSITORY}." >&2
  exit 1
fi
if [ "$is_pr" = "true" ]; then
  mode="revise"
else
  mode="implement"
fi

mkdir -p .jaiph/tmp
if [ "$mode" = "implement" ]; then
  # 4. Verify the issue is open and has no implementation pull request yet.
  gh issue view "$ISSUE_NUMBER" --json number,title,state,url > .jaiph/tmp/issue.raw.json

  if ! jq -e '.state == "OPEN"' .jaiph/tmp/issue.raw.json > /dev/null; then
    echo "Issue #${ISSUE_NUMBER} is not open." >&2
    exit 1
  fi

  existing_pr="$(gh pr list --state open --head "ai/issue-${ISSUE_NUMBER}" --json url --jq '.[0].url // empty')"
  if [ -n "$existing_pr" ]; then
    gh issue comment "$ISSUE_NUMBER" \
      --body "An implementation pull request is already open: ${existing_pr}. Comment \`/implement\` on it to revise it."
    echo "An implementation pull request already exists: ${existing_pr}" >&2
    exit 1
  fi
  linked_issue="$ISSUE_NUMBER"
  head_ref=""
  issue_json="$(jq -c '{number, title, url}' .jaiph/tmp/issue.raw.json)"
  pr_json="null"
else
  # 4. Verify the pull request is open and its branch can be pushed to. Any
  #    pull request qualifies, whoever opened it and whether or not it has an
  #    issue: the agent works from the review and the comment's instructions.
  #    The workflow token can only push to a branch in this repository, and the
  #    default branch is never pushed to directly.
  gh pr view "$ISSUE_NUMBER" --json number,url,state,headRefName,baseRefName,isCrossRepository \
    > .jaiph/tmp/pr.raw.json

  if ! jq -e '.state == "OPEN"' .jaiph/tmp/pr.raw.json > /dev/null; then
    echo "Pull request #${ISSUE_NUMBER} is not open." >&2
    exit 1
  fi
  head_ref="$(jq -r '.headRefName' .jaiph/tmp/pr.raw.json)"
  default_branch="$(gh api "repos/${GITHUB_REPOSITORY}" --jq '.default_branch')"
  if jq -e '.isCrossRepository' .jaiph/tmp/pr.raw.json > /dev/null \
    || [ "$head_ref" = "$default_branch" ]; then
    gh pr comment "$ISSUE_NUMBER" \
      --body "\`/implement\` can only revise a pull request from a branch in this repository other than \`${default_branch}\`; the workflow cannot push to this one."
    echo "Pull request #${ISSUE_NUMBER} (${head_ref}) is from a fork or the default branch." >&2
    exit 1
  fi
  # The agent finds any issues the pull request closes on its own.
  linked_issue=""
  issue_json="null"
  pr_json="$(jq -c '{number, url, headRefName, baseRefName}' .jaiph/tmp/pr.raw.json)"
fi

# 5. Write the request for the agent, and the issue title for the pull request.
jq -n --arg mode "$mode" --arg repo "$GITHUB_REPOSITORY" \
  --arg additional "$additional" --arg by "$TRIGGER_ACTOR" \
  --argjson issue "$issue_json" --argjson pr "$pr_json" '{
    mode: $mode,
    repository: $repo,
    issue: $issue,
    pullRequest: $pr,
    additionalInstructions: $additional,
    triggeredBy: $by
  }' > .jaiph/tmp/request.json

delimiter="GATE_$(openssl rand -hex 16)"
{
  echo "mode=${mode}"
  echo "issue_number=${linked_issue}"
  echo "head_ref=${head_ref}"
  printf 'title<<%s\n' "$delimiter"
  jq -r '.issue.title // empty' .jaiph/tmp/request.json
  printf '%s\n' "$delimiter"
} >> "$GITHUB_OUTPUT"

# 6. Tell the issue or pull request that the run started. `gh issue comment`
#    posts to a pull request's conversation as well.
if [ "$EVENT_NAME" = "issue_comment" ]; then
  gh api --method POST \
    "repos/${GITHUB_REPOSITORY}/issues/comments/${COMMENT_ID}/reactions" \
    -f content='eyes' || true
fi
gh issue comment "$ISSUE_NUMBER" --body "Working on this in ${RUN_URL}."
