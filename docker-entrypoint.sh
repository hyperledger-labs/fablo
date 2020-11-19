#!/bin/sh

set -e

config="/network/fabrica-config.json"
target="/network/target"

default_command="yo --no-insight fabrica:setup-docker ../..$config"
command_to_execute=${1:-$default_command}

changeUserAndExecuteCommand() {
  command=$1
  param=$2
  if [ "$(id -u)" = 0 ]; then
    echo "Root user detected, running as yeoman user"
    command_to_execute="sudo -E -u yeoman yo --no-insight fabrica:$command $param"

    (sudo chown -R yeoman:yeoman "$target" &&
      (cd "$target" && eval "$command_to_execute") &&
      sudo chown -R root:root "$target")
  else
    command_to_execute="yo --no-insight fabrica:$command $param"
    (cd "$target" && eval "$command_to_execute")
  fi

  rm -rf "$target/.cache" "$target/.config"
}

if [ -z "$1" ]; then
    changeUserAndExecuteCommand "setup-docker ../..$config"

    # Additional script and yaml formatting
    #
    # Why? Yeoman output may contain some additional whitespaces or the formatting
    # might not be ideal. Keeping those whitespaces, however, might be useful
    # in templates to improve the brevity. That's why we need additional formatting.
    # Since the templates should obey good practices, we don't use linters here
    # (i.e. shellcheck and yamllint).
    echo "Formatting generated files"
    shfmt -i=2 -l -w "$target"

    for yaml in "$target"/**/*.yaml; do
      # remove trailing spaces
      sed --in-place 's/[ \t]*$//' "$yaml"

      # remove duplicated empty/blank lines
      content="$(awk -v RS= -v ORS='\n\n' '1' "$yaml")"
      echo "$content" >"$yaml"
    done
else
  changeUserAndExecuteCommand "$1" "$2"
fi


