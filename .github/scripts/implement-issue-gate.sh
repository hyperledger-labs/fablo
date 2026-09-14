#!/usr/bin/env bash

# Gate and prepare an `/implement` run. Called by
# .github/workflows/implement-issue.yml as its single validation step.
#
# It decides whether the run may proceed, and when it may, leaves the issue
# payload for the agent in .jaiph/tmp/issue.json and acknowledges on the issue.
# Every refusal exits non-zero, so the rest of the job is skipped.
#
# Reads from the environment: EVENT_NAME, COMMENT_BODY, ADDITIONAL_INPUT,
# ISSUE_NUMBER, TRIGGER_ACTOR, COMMENT_ID, RUN_URL, GH_TOKEN,
# GITHUB_REPOSITORY, GITHUB_OUTPUT, AI_ALLOWED_ACTORS.
#
# Writes the `title` step output, used as the pull request title.

set -euo pipefail

# 1. Verify the caller may drive the agent. The workflow `if` only looks at the
#    comment body, and does not filter workflow_dispatch at all, so this is the
#    one authoritative permission check.
#
#    Two ways to qualify: write access to the repository, or a listing in the
#    AI_ALLOWED_ACTORS repository variable — a comma-separated list of logins.
#    The variable lets a maintainer hand the bot to a contributor without also
#    handing them write access to the repository. Only a repository admin can
#    set it, so being on the list is a deliberate grant.
actor_allowed=0

IFS=',' read -ra allowed_actors <<< "${AI_ALLOWED_ACTORS:-}"
for allowed_actor in "${allowed_actors[@]:-}"; do
  # Tolerate spaces around the commas, and compare case-insensitively, as
  # GitHub logins are not case-sensitive.
  allowed_actor="${allowed_actor//[[:space:]]/}"
  if [ -n "$allowed_actor" ] && [ "${allowed_actor,,}" = "${TRIGGER_ACTOR,,}" ]; then
    actor_allowed=1
    echo "${TRIGGER_ACTOR} is listed in AI_ALLOWED_ACTORS."
    break
  fi
done

if [ "$actor_allowed" -eq 0 ]; then
  # A login with no relationship to the repository reports 'none'; a failed
  # call is treated the same way, so the refusal below stays readable.
  permission="$(gh api "repos/${GITHUB_REPOSITORY}/collaborators/${TRIGGER_ACTOR}/permission" \
    --jq '.permission' 2>/dev/null || echo "none")"
  if [[ "$permission" =~ ^(admin|maintain|write)$ ]]; then
    actor_allowed=1
  fi
fi

if [ "$actor_allowed" -eq 0 ]; then
  echo "${TRIGGER_ACTOR} may not run this workflow: write access to the" >&2
  echo "repository, or a listing in the AI_ALLOWED_ACTORS repository" >&2
  echo "variable, is required." >&2
  exit 1
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

# 3. Verify the issue number; on workflow_dispatch it is free-form input.
if [[ ! "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Invalid issue number: ${ISSUE_NUMBER}" >&2
  exit 1
fi

# 4. Verify the issue is open and has no implementation pull request yet.
mkdir -p .jaiph/tmp
gh issue view "$ISSUE_NUMBER" --json number,title,body,comments,labels,state,url \
  > .jaiph/tmp/issue.raw.json

if ! jq -e '.state == "OPEN"' .jaiph/tmp/issue.raw.json > /dev/null; then
  echo "Issue #${ISSUE_NUMBER} is not open." >&2
  exit 1
fi

existing_pr="$(gh pr list --state open --head "ai/issue-${ISSUE_NUMBER}" --json url --jq '.[0].url // empty')"
if [ -n "$existing_pr" ]; then
  gh issue comment "$ISSUE_NUMBER" \
    --body "An implementation pull request is already open: ${existing_pr}"
  echo "An implementation pull request already exists: ${existing_pr}" >&2
  exit 1
fi

# 5. Hand the issue to the agent, and its title to the pull request step.
jq --arg additional "$additional" --arg by "$TRIGGER_ACTOR" \
  '. + {additionalInstructions: $additional, triggeredBy: $by}' \
  .jaiph/tmp/issue.raw.json > .jaiph/tmp/issue.json

delimiter="GATE_$(openssl rand -hex 16)"
{
  printf 'title<<%s\n' "$delimiter"
  jq -r '.title' .jaiph/tmp/issue.json
  printf '%s\n' "$delimiter"
} >> "$GITHUB_OUTPUT"

# 6. Tell the issue that the run started.
if [ "$EVENT_NAME" = "issue_comment" ]; then
  gh api --method POST \
    "repos/${GITHUB_REPOSITORY}/issues/comments/${COMMENT_ID}/reactions" \
    -f content='eyes' || true
fi
gh issue comment "$ISSUE_NUMBER" --body "Working on this in ${RUN_URL}."
