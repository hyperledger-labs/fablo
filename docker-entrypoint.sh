#!/bin/sh

config="/network/config.json"
target="/network/target"

sudo rm -rf "$target/*" &&
  sudo mkdir -p "$target" &&
  sudo chown -R yeoman:yeoman "$target" &&
  (
    cd "$target" &&
      yo --no-insight fabrikka:setup-compose "../../$config"
  ) &&
  sudo chown -R root:root "$target"
