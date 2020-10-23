#!/bin/bash

FABRIKKA_NETWORK_ROOT="$(cd "$(dirname "$0")" && pwd)"

source "$FABRIKKA_NETWORK_ROOT/fabric-docker/scripts/base-help.sh"
source "$FABRIKKA_NETWORK_ROOT/fabric-docker/scripts/base-functions.sh"
source "$FABRIKKA_NETWORK_ROOT/fabric-docker/scripts/base-peer-channel-functions.sh"
source "$FABRIKKA_NETWORK_ROOT/fabric-docker/commands-generated.sh"
source "$FABRIKKA_NETWORK_ROOT/fabric-docker/.env"

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
<%- include('fabrikka-docker-channelScipts.sh.ejs', {orgs: orgs, channels: channels}); -%>
elif [ "$1" = "help" ]; then
  printHelp
elif [ "$1" = "--help" ]; then
  printHelp
else
  echo "No command specified"
  echo "Basic commands are: up, down, start, stop, recreate"
  echo "To list channel query helper commands type: './fabrikka-docker.sh channel --help'"
  echo "Also check: 'chaincodes install'"
  echo "Use 'help' or '--help' for more information"
fi
