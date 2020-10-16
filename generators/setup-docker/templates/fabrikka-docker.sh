#!/bin/bash

FABRIKKA_DOCKER_ROOT="/network/docker"
FABRIKKA_CHAINCODES_ROOT="/network/chaincodes"
#FABRIKKA_DOCKER_ROOT="$(cd "$(dirname "./$0")" && pwd)"

source "$FABRIKKA_DOCKER_ROOT/fabric-docker/scripts/base-help.sh"
source "$FABRIKKA_DOCKER_ROOT/fabric-docker/scripts/base-functions.sh"
source "$FABRIKKA_DOCKER_ROOT/fabric-docker/commands-generated.sh"
source "$FABRIKKA_DOCKER_ROOT/fabric-docker/.env"

if [ "$1" = "up" ]; then
  generateArtifacts
  startNetwork
  generateChannelsArtifacts
  installChannels
  installChaincodes
  printHeadline "Done! Enjoy your fresh network" "U1F984"
elif [ "$1" = "recreate" ]; then
  networkDown
  generateArtifacts
  startNetwork
  generateChannelsArtifacts
  installChannels
  installChaincodes
  printHeadline "Done! Enjoy your fresh network" "U1F984"
elif [ "$1" = "down" ]; then
  networkDown
elif [ "$1" = "start" ]; then
  startNetwork
elif [ "$1" = "stop" ]; then
  stopNetwork
elif [ "$1" = "chaincodes" ] && [ "$2" = "install" ]; then
  installChaincodes
elif [ "$1" = "help" ]; then
  printHelp
elif [ "$1" = "--help" ]; then
  printHelp
else
  echo "No command specified"
  echo "Basic commands are: up, down, start, stop, recreate"
  echo "Also check: 'chaincodes install'"
  echo "Use 'help' or '--help' for more information"
fi
