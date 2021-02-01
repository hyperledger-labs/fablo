#!/bin/sh

set -e

executeYeomanCommand() {
  command=$1
  param=$2

  # cleanup yeoman files after execution
  # shellcheck disable=SC2064
  trap "rm -rf \"$yeoman_target_dir/.cache\" \"$yeoman_target_dir/.config\"" EXIT

  if [ "$(id -u)" = 0 ]; then
    # root user detected, running as yeoman user
    sudo chown -R yeoman:yeoman "$yeoman_target_dir"
    (cd "$yeoman_target_dir" && sudo -E -u yeoman yo --no-insight "fabrica:$command" "$param")
    sudo chown -R root:root "$yeoman_target_dir"
  else
    (cd "$yeoman_target_dir" && yo --no-insight "fabrica:$command" "$param")
  fi
}

formatGeneratedFiles() {
  # Additional script and yaml formatting
  #
  # Why? Yeoman output may contain some additional whitespaces or the formatting
  # might not be ideal. Keeping those whitespaces, however, might be useful
  # in templates to improve the brevity. That's why we need additional formatting.
  # Since the templates should obey good practices, we don't use linters here
  # (i.e. shellcheck and yamllint).
  echo "Formatting generated files"
  shfmt -i=2 -l -w "$yeoman_target_dir"

  for yaml in "$yeoman_target_dir"/**/*.yaml; do
    # remove trailing spaces
    sed --in-place 's/[ \t]*$//' "$yaml"

    # remove duplicated empty/blank lines
    content="$(awk -v RS= -v ORS='\n\n' '1' "$yaml")"
    echo "$content" >"$yaml"
  done
}

yeoman_target_dir="/network/workspace"
fabrica_config_path="../../network/fabrica-config.json"
yeoman_command=${1:-setup-docker}
yeoman_param=${2:-"$fabrica_config_path"}

executeYeomanCommand "$yeoman_command" "$yeoman_param"

if [ "$yeoman_command" = setup-docker ]; then
  formatGeneratedFiles
fi
