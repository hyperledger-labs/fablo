#!/bin/sh

set -e

executeYeomanCommand() {
  target_dir=$1
  command=$2
  param=$3

  if [ "$(id -u)" = 0 ]; then
    echo "Root user detected, running as yeoman user"
    command_to_execute="sudo -E -u yeoman yo --no-insight fabrica:$command $param"

    (sudo chown -R yeoman:yeoman "$target_dir" &&
      (cd "$target_dir" && eval "$command_to_execute") &&
      sudo chown -R root:root "$target_dir")
  else
    command_to_execute="yo --no-insight fabrica:$command $param"
    (cd "$target_dir" && eval "$command_to_execute")
  fi

  rm -rf "$target_dir/.cache" "$target_dir/.config"
}

formatGeneratedFiles() {
  target_dir=$1
  # Additional script and yaml formatting
  #
  # Why? Yeoman output may contain some additional whitespaces or the formatting
  # might not be ideal. Keeping those whitespaces, however, might be useful
  # in templates to improve the brevity. That's why we need additional formatting.
  # Since the templates should obey good practices, we don't use linters here
  # (i.e. shellcheck and yamllint).
  echo "Formatting generated files"
  shfmt -i=2 -l -w "$target_dir"

  for yaml in "$target_dir"/**/*.yaml; do
    # remove trailing spaces
    sed --in-place 's/[ \t]*$//' "$yaml"

    # remove duplicated empty/blank lines
    content="$(awk -v RS= -v ORS='\n\n' '1' "$yaml")"
    echo "$content" >"$yaml"
  done
}

yeoman_target_dir="/network/target"

if [ -n "$1" ]; then
  executeYeomanCommand "$yeoman_target_dir" "$1" "$2"
else
  # by default entrypoint generates files from fabrica config
  config_path="/network/fabrica-config.json"

  executeYeomanCommand "$yeoman_target_dir" "setup-docker ../..$config_path"
  formatGeneratedFiles "$yeoman_target_dir"
fi
