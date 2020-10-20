#!/bin/sh

config="/network/config.json"
target="/network/docker"
chaincodes="/network/chaincodes"
command="$COMMAND"

if [ "$command" = "generate" ]; then
  if [ "$(id -u)" = 0 ]; then
    echo "Root user detected, running as yeoman user"
    (sudo chown -R yeoman:yeoman "$target" &&
      (cd "$target" && sudo -u yeoman yo --no-insight fabrikka:setup-docker "../../$config") &&
      sudo chown -R root:root "$target")
  else
    (cd "$target" && yo --no-insight fabrikka:setup-docker "../..$config")
  fi
else
  sh "$target/fabrikka-docker.sh" "$command"
fi
