#!/usr/bin/env bash

# Gate and prepare an `/implement` run. Called by
# .github/workflows/implement-issue.yml as its single validation step.
#
# ISSUE_NUMBER is an issue or a pull request; GitHub numbers both from one
# sequence. On an issue the run implements it and opens a pull request. On a
# pull request the run revises that pull request: it must be one this workflow
# opened, on an ai/issue-<n> branch, and the agent addresses the review on it.
#
# It decides whether the run may proceed, and when it may, leaves the payload
# for the agent in .jaiph/tmp/issue.json and acknowledges on the issue or pull
# request. Every refusal exits non-zero, so the rest of the job is skipped.
#
# Reads from the environment: EVENT_NAME, COMMENT_BODY, ADDITIONAL_INPUT,
# ISSUE_NUMBER, TRIGGER_ACTOR, COMMENT_ID, RUN_URL, GH_TOKEN,
# GITHUB_REPOSITORY, GITHUB_OUTPUT, AI_ALLOWED_ACTORS.
#
# Writes these step outputs:
#   mode          `implement` for an issue, `revise` for a pull request
#   title         the issue title, used as the pull request title
#   issue_number  the issue being implemented (on a revise, the one in the branch name)
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

mkdir -p .jaiph/tmp
if gh api "repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}" --jq 'has("pull_request")' | grep -qx true; then
  mode="revise"
else
  mode="implement"
fi

if [ "$mode" = "implement" ]; then
  # 4. Verify the issue is open and has no implementation pull request yet.
  gh issue view "$ISSUE_NUMBER" --json number,title,body,comments,labels,state,url \
    > .jaiph/tmp/issue.raw.json

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

  # 5. Hand the issue to the agent, and its title to the pull request step.
  jq --arg additional "$additional" --arg by "$TRIGGER_ACTOR" \
    '. + {mode: "implement", additionalInstructions: $additional, triggeredBy: $by}' \
    .jaiph/tmp/issue.raw.json > .jaiph/tmp/issue.json
  linked_issue="$ISSUE_NUMBER"
  head_ref=""
else
  # 4. Verify the pull request is open and is one this workflow opened. Only a
  #    branch in this repository can be pushed to, and only an ai/issue-<n>
  #    branch holds agent work: a human's pull request is never rewritten.
  gh pr view "$ISSUE_NUMBER" \
    --json number,title,body,url,state,headRefName,baseRefName,isCrossRepository,comments,reviews \
    > .jaiph/tmp/pr.raw.json

  if ! jq -e '.state == "OPEN"' .jaiph/tmp/pr.raw.json > /dev/null; then
    echo "Pull request #${ISSUE_NUMBER} is not open." >&2
    exit 1
  fi
  head_ref="$(jq -r '.headRefName' .jaiph/tmp/pr.raw.json)"
  if jq -e '.isCrossRepository' .jaiph/tmp/pr.raw.json > /dev/null \
    || [[ ! "$head_ref" =~ ^ai/issue-([0-9]+)$ ]]; then
    gh pr comment "$ISSUE_NUMBER" \
      --body "\`/implement\` only revises pull requests opened by the implement workflow (branch \`ai/issue-<n>\` in this repository)."
    echo "Pull request #${ISSUE_NUMBER} (${head_ref}) was not opened by this workflow." >&2
    exit 1
  fi
  linked_issue="${BASH_REMATCH[1]}"

  # Review comments left on lines of the diff live in threads, which only the
  # GraphQL API returns. A resolved thread is settled, so it is left out.
  owner="${GITHUB_REPOSITORY%%/*}"
  name="${GITHUB_REPOSITORY#*/}"
  # shellcheck disable=SC2016 # $owner and friends are GraphQL variables.
  gh api graphql -F owner="$owner" -F name="$name" -F number="$ISSUE_NUMBER" -f query='
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          reviewThreads(first: 100) {
            nodes {
              isResolved
              isOutdated
              path
              line
              originalLine
              comments(first: 50) { nodes { author { login } body } }
            }
          }
        }
      }
    }' --jq '[.data.repository.pullRequest.reviewThreads.nodes[]
      | select(.isResolved | not)
      | {path, line, originalLine, isOutdated, comments: [.comments.nodes[] | {author: .author.login, body}]}]' \
    > .jaiph/tmp/review-threads.json

  gh issue view "$linked_issue" --json number,title,body,url > .jaiph/tmp/issue.raw.json

  # 5. Hand the pull request, its review, and the issue behind it to the agent.
  #    The workflow's own progress comments are noise, so they are dropped.
  jq -n --arg additional "$additional" --arg by "$TRIGGER_ACTOR" \
    --slurpfile pr .jaiph/tmp/pr.raw.json \
    --slurpfile threads .jaiph/tmp/review-threads.json \
    --slurpfile issue .jaiph/tmp/issue.raw.json '
    def human: .author.login != "github-actions";
    {
      mode: "revise",
      number: $issue[0].number,
      title: $issue[0].title,
      body: $issue[0].body,
      url: $issue[0].url,
      pullRequest: ($pr[0] | {
        number, title, body, url, headRefName, baseRefName,
        comments: [.comments[] | select(human) | {author: .author.login, body}],
        reviews: [.reviews[] | select(human) | select(.body != "") | {author: .author.login, state, body}]
      }),
      reviewThreads: $threads[0],
      additionalInstructions: $additional,
      triggeredBy: $by
    }' > .jaiph/tmp/issue.json
fi

delimiter="GATE_$(openssl rand -hex 16)"
{
  echo "mode=${mode}"
  echo "issue_number=${linked_issue}"
  echo "head_ref=${head_ref}"
  printf 'title<<%s\n' "$delimiter"
  jq -r '.title' .jaiph/tmp/issue.json
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
