#!/usr/bin/env bash
# Write a binary git patch of the working tree and, on GitHub Actions, publish
# its path as the step output patch_file.
#
# The patch lands in .jaiph/tmp, which is gitignored, so a later pull-request
# step does not commit it. Intent-to-add is reset so the index stays as the
# caller left it; untracked files are still included in the patch.
#
# Usage, from the repository root:
#   .jaiph/git/save-worktree-patch.sh "No git diff produced by implement run"
set -euo pipefail

note="${1:?empty-patch note required}"
run_id="${GITHUB_RUN_ID:-local}"
mkdir -p .jaiph/tmp
patch_file=".jaiph/tmp/worktree-${run_id}.patch"

git add -N . || true
git diff --binary > "${patch_file}" || true
git reset -q

if [ ! -s "${patch_file}" ]; then
  printf '# %s\n' "${note}" > "${patch_file}"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "patch_file=${patch_file}" >> "${GITHUB_OUTPUT}"
fi
printf '%s\n' "${patch_file}"
