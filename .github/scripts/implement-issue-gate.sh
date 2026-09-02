#!/usr/bin/env bash

# Gate and prepare an `@fablo-bot implement` run. Called by
# .github/workflows/implement-issue.yml as its single validation step.
#
# It decides whether the run may proceed, and when it may, leaves the issue
# payload for the agent in .jaiph/tmp/issue.json and acknowledges on the issue.
#
# Reads from the environment: EVENT_NAME, COMMENT_BODY, EXTRA_INPUT,
# ISSUE_NUMBER, TRIGGER_ACTOR, COMMENT_ID, RUN_URL, GH_TOKEN,
# GITHUB_REPOSITORY, GITHUB_OUTPUT.
#
# Writes the `run` and `title` step outputs. A refusal is not a failure: it
# sets `run=false` and exits 0 so the rest of the job is skipped quietly.

set -euo pipefail

output() {
  printf '%s=%s\n' "$1" "$2" >> "$GITHUB_OUTPUT"
}

output_multiline() {
  local delimiter="JAIPH_$(openssl rand -hex 16)"
  {
    printf '%s<<%s\n' "$1" "$delimiter"
    printf '%s\n' "$2"
    printf '%s\n' "$delimiter"
  } >> "$GITHUB_OUTPUT"
}

refuse() {
  echo "$1"
  output run false
  exit 0
}

extra="${EXTRA_INPUT:-}"

# 1. The command. Only the first line counts, so an implement command quoted
#    inside a longer comment does not trigger a run.
if [ "$EVENT_NAME" != "workflow_dispatch" ]; then
  first="$(printf '%s\n' "$COMMENT_BODY" | sed -n '1p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  case "$first" in
    '@fablo-bot implement' | '/implement') ;;
    *) refuse "Not an implement command on the first line; skipping." ;;
  esac

  # 2. The caller. author_association is checked in the workflow `if`; this is
  #    the authoritative check against the repository's collaborator list.
  permission="$(gh api "repos/${GITHUB_REPOSITORY}/collaborators/${TRIGGER_ACTOR}/permission" --jq '.permission')"
  case "$permission" in
    admin | maintain | write) ;;
    *) refuse "${TRIGGER_ACTOR} has '${permission}' permission; write access is required." ;;
  esac

  extra="$(printf '%s\n' "$COMMENT_BODY" | tail -n +2)"
fi

# 3. The issue number, which reaches us as free-form workflow_dispatch input.
if [[ ! "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Invalid issue number: ${ISSUE_NUMBER}" >&2
  exit 1
fi

# 4. The issue itself, and whether it already has an implementation open.
mkdir -p .jaiph/tmp
gh issue view "$ISSUE_NUMBER" --json number,title,body,comments,labels,state,url \
  > .jaiph/tmp/issue.raw.json

if ! jq -e '.state == "OPEN"' .jaiph/tmp/issue.raw.json > /dev/null; then
  refuse "Issue #${ISSUE_NUMBER} is not open."
fi

existing_pr="$(gh pr list --state open --head "ai/issue-${ISSUE_NUMBER}" --json url --jq '.[0].url // empty')"
if [ -n "$existing_pr" ]; then
  gh issue comment "$ISSUE_NUMBER" \
    --body "An implementation pull request is already open: ${existing_pr}"
  refuse "An implementation pull request already exists: ${existing_pr}"
fi

jq --arg extra "$extra" --arg by "$TRIGGER_ACTOR" \
  '. + {extraInstructions: $extra, triggeredBy: $by}' \
  .jaiph/tmp/issue.raw.json > .jaiph/tmp/issue.json

output run true
output_multiline title "$(jq -r '.title' .jaiph/tmp/issue.json)"

# 5. Tell the issue that the run started.
if [ "$EVENT_NAME" = "issue_comment" ]; then
  gh api --method POST \
    "repos/${GITHUB_REPOSITORY}/issues/comments/${COMMENT_ID}/reactions" \
    -f content='eyes' || true
fi
gh issue comment "$ISSUE_NUMBER" --body "Working on this in ${RUN_URL}."
