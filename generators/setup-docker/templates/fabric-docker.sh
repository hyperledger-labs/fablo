#!/usr/bin/env bash

set -eu

FABRICA_NETWORK_ROOT="$(cd "$(dirname "$0")" && pwd)"

source "$FABRICA_NETWORK_ROOT/fabric-docker/scripts/base-help.sh"
source "$FABRICA_NETWORK_ROOT/fabric-docker/scripts/base-functions.sh"
source "$FABRICA_NETWORK_ROOT/fabric-docker/scripts/chaincode-functions.sh"
source "$FABRICA_NETWORK_ROOT/fabric-docker/scripts/channel-functions.sh"
source "$FABRICA_NETWORK_ROOT/fabric-docker/commands-generated.sh"
source "$FABRICA_NETWORK_ROOT/fabric-docker/.env"

function networkUp() {
  generateArtifacts
  prepareChaincodeDirs
  startNetwork
  generateChannelsArtifacts
  installChannels
  installChaincodes
  notifyOrgsAboutChannels
  printHeadline "Done! Enjoy your fresh network" "U1F984"
}

if [ "$1" = "up" ]; then
  networkUp
elif [ "$1" = "down" ]; then
  networkDown
elif [ "$1" = "reboot" ]; then
  networkDown
  networkUp
elif [ "$1" = "start" ]; then
  startNetwork
elif [ "$1" = "stop" ]; then
  stopNetwork
elif [ "$1" = "chaincode" ] && [ "$2" = "upgrade" ]; then
  upgradeChaincode "$3" "$4"
elif [ "$1" = "help" ]; then
  printHelp
elif [ "$1" = "--help" ]; then
  printHelp
else
  echo "No command specified"
  echo "Basic commands are: up, down, start, stop, reboot"
  echo "To list channel query helper commands type: './fabrikka-docker.sh channel --help'"
  echo "Also check: 'chaincodes install'"
  echo "Use 'help' or '--help' for more information"
fi
