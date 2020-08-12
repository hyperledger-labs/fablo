#!/bin/bash
set -e

source fabric-compose/scripts/base-help.sh
source fabric-compose/scripts/base-functions.sh
source fabric-compose/commands-generated.sh

source fabric-compose/.env

if [ "$1" = "up" ]; then
  generateArtifacts
  startNetwork
  generateChannelsArtifacts
  installChannels
  installChaincodes
elif [ "$1" = "down" ]; then
  networkDown
elif [ "$1" = "rerun" ]; then
  networkRerun
elif [ "$1" = "chaincodes" ] && [ "$2" = "install" ]; then
  installChaincodes
elif [ "$1" = "help" ]; then
  printHelp
elif [ "$1" = "--help" ]; then
  printHelp
else
  echo "No command specified"
  echo "Basic commands are: up, down, start, stop, rerun"
  echo "Also check: 'chaincodes install'"
  echo "Use 'help' or '--help' for more information"
fi
