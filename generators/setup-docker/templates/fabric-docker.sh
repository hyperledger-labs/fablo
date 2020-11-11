#!/bin/bash

set -eu

FABRIKKA_NETWORK_ROOT="$(cd "$(dirname "$0")" && pwd)"

source "$FABRIKKA_NETWORK_ROOT/fabric-docker/scripts/base-help.sh"
source "$FABRIKKA_NETWORK_ROOT/fabric-docker/scripts/base-functions.sh"
source "$FABRIKKA_NETWORK_ROOT/fabric-docker/commands-generated.sh"
source "$FABRIKKA_NETWORK_ROOT/fabric-docker/.env"

function networkUp() {
  generateArtifacts
  startNetwork
  generateChannelsArtifacts
  installChannels
  installChaincodes
  notifyOrgsAboutChannels
  printHeadline "Done! Enjoy your fresh network" "U1F984"
}

if [ "$1" = "up" ]; then
  networkUp
elif [ "$1" = "recreate" ]; then
  networkDown
  networkUp
elif [ "$1" = "down" ]; then
  networkDown
elif [ "$1" = "start" ]; then
  startNetwork
elif [ "$1" = "stop" ]; then
  stopNetwork
elif [ "$1" = "help" ]; then
  printHelp
elif [ "$1" = "--help" ]; then
  printHelp
else
  echo "No command specified"
  echo "Basic commands are: up, down, start, stop, recreate"
  echo "Use 'help' or '--help' for more information"
fi
