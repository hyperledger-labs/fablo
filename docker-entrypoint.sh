#!/bin/sh

config="/network/config.json"
target="/network/docker"
chaincodes="/network/chaincodes"
command="$COMMAND"

generateConfig() {
  echo "NETWORK_CONFIG: $NETWORK_CONFIG"
  echo "NETWORK_TARGET: $NETWORK_TARGET"
  echo "CHAINCODES: $CHAINCODES"

  rm -rf "$target/*" &&
    chown -R yeoman:yeoman "$target" &&
    (
      cd "$target" &&
        sudo -u yeoman yo --no-insight fabrikka:setup-docker "../..$config"
    ) &&
    chown -R root:root "$target"
}

#
#
#

mkdir -p "$target"
mkdir -p "$chaincodes"

if [ "$command" = "generate" ]; then
  echo "Generating network in $NETWORK_TARGET for $NETWORK_CONFIG"
  generateConfig
elif [ -z "$(ls -A "$target")" ]; then
  echo "Target directory is empty, generating network config"
  generateConfig
else
  echo "Skipping generation of network config. Use command 'generate' to overwrite"
fi

if [ "$command" != "generate" ]; then
  echo "Executing Fabrikka docker command: $command"
  sh "$target/fabrikka-docker.sh" "$command"
fi
