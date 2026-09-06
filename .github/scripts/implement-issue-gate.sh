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
# GITHUB_REPOSITORY, GITHUB_OUTPUT.
#
# Writes the `title` step output, used as the pull request title.

set -euo pipefail

# 1. Verify the caller has write access to the repo. The workflow `if` only
#    looks at the comment body, and does not filter workflow_dispatch at all,
#    so this is the one authoritative permission check.
permission="$(gh api "repos/${GITHUB_REPOSITORY}/collaborators/${TRIGGER_ACTOR}/permission" --jq '.permission')"
if [[ ! "$permission" =~ ^(admin|maintain|write)$ ]]; then
  echo "${TRIGGER_ACTOR} has '${permission}' permission; write access is required." >&2
  exit 1
fi

# 2. Collect the instructions for the agent. On a comment the command is the
#    first line — the workflow `if` guarantees it — and the rest is guidance.
if [ "$EVENT_NAME" = "workflow_dispatch" ]; then
  additional="${ADDITIONAL_INPUT:-}"
else
  additional="$(printf '%s\n' "$COMMENT_BODY" | tail -n +2)"
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
