#!/bin/sh

config="/network/fabrikka-config.json"
target="/network/target"

if [ "$(id -u)" = 0 ]; then
  echo "Root user detected, running as yeoman user"
  (sudo chown -R yeoman:yeoman "$target" &&
    (cd "$target" && sudo -u yeoman yo --no-insight fabrikka:setup-docker "../..$config") &&
    sudo chown -R root:root "$target")
else
  (cd "$target" && yo --no-insight fabrikka:setup-docker "../..$config")
fi

rm -rf "$target/.cache" "$target/.config"
