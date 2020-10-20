#!/bin/sh

config="/network/config.json"
target="/network/docker"
chaincodes="/network/chaincodes"
command="$COMMAND"

if [ "$command" = "generate" ]; then
  (cd "$target" && yo --no-insight fabrikka:setup-docker "../..$config")
else
  sh "$target/fabrikka-docker.sh" "$command"
fi
