#!/usr/bin/env sh

set -e

# The Docker image runs this from /fablo; the npm package runs it from the
# package directory with FABLO_WORKSPACE pointing at the host workspace.
fablo_home="$(cd "$(dirname "$0")" && pwd)"

executeOclifCommand() {
  command_with_params=$1
  # shellcheck disable=SC2086
  (cd "$target_dir" && node --no-warnings "$fablo_home/bin/run.mjs" $command_with_params)
}

formatGeneratedFiles() {
  # Additional script and yaml formatting
  #
  # Why? Generated output may contain some additional whitespaces or the formatting
  # might not be ideal. Keeping those whitespaces, however, might be useful
  # in templates to improve the brevity. That's why we need additional formatting.
  # Since the templates should obey good practices, we don't use linters here
  # (i.e. shellcheck and yamllint).
  echo "Formatting generated files"
  if command -v shfmt >/dev/null 2>&1; then
    shfmt -i=2 -l -w "$target_dir" >/dev/null
  else
    echo "Warning: shfmt not found, generated scripts are left unformatted"
  fi

  for yaml in "$target_dir"/**/*.yaml; do

    # the expansion failed, no yaml files found
    if [ "$yaml" = "$target_dir/**/*.yaml" ]; then
      break
    fi

    # remove trailing spaces
    sed 's/[[:blank:]]*$//' "$yaml" >"$yaml.tmp" && mv "$yaml.tmp" "$yaml"

    # remove duplicated empty/blank lines
    content="$(awk -v RS= -v ORS='\n\n' '1' "$yaml")"
    echo "$content" >"$yaml"
  done
}

target_dir="${FABLO_WORKSPACE:-/network/workspace}"
oclif_command=${1:-setup-network}

# Map old yeoman command format to oclif format
case "$oclif_command" in
  "Fablo:setup-network"|"fablo:setup-network")
    oclif_command="setup-network"
    ;;
esac

# Build command with all arguments (mapped command + remaining args)
# Replace first argument with mapped command, then pass all args
if [ $# -gt 0 ]; then
  shift
  set -- "$oclif_command" "$@"
else
  set -- "$oclif_command"
fi
command_with_args="$*"

# Execute the command
executeOclifCommand "$command_with_args"

if echo "$oclif_command" | grep -q "setup-network"; then
  formatGeneratedFiles
fi
