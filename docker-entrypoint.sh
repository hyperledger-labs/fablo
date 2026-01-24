#!/usr/bin/env sh

set -e

executeOclifCommand() {
  command_with_params=$1
  if [ "$(id -u)" = 0 ]; then
    # root user detected, running as yeoman user (keeping for compatibility)
    sudo chown -R yeoman:yeoman "$target_dir"
    # shellcheck disable=SC2086
    (cd "$target_dir" && sudo -E -u yeoman node --no-warnings /fablo/bin/run.mjs $command_with_params)
    sudo chown -R root:root "$target_dir"
  else
    # shellcheck disable=SC2086
    (cd "$target_dir" && node --no-warnings /fablo/bin/run.mjs $command_with_params)
  fi
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
  shfmt -i=2 -l -w "$target_dir" >/dev/null

  for yaml in "$target_dir"/**/*.yaml; do

    # the expansion failed, no yaml files found
    if [ "$yaml" = "$target_dir/**/*.yaml" ]; then
      break
    fi

    # remove trailing spaces
    sed --in-place 's/[ \t]*$//' "$yaml"

    # remove duplicated empty/blank lines
    content="$(awk -v RS= -v ORS='\n\n' '1' "$yaml")"
    echo "$content" >"$yaml"
  done
}

target_dir="/network/workspace"
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
