#!/usr/bin/env bash

set -eu

FABLO_NETWORK_ROOT="$(cd "$(dirname "$0")" && pwd)"

source "$FABLO_NETWORK_ROOT/fabric-docker/scripts/base-help.sh"
source "$FABLO_NETWORK_ROOT/fabric-docker/scripts/base-functions.sh"
source "$FABLO_NETWORK_ROOT/fabric-docker/scripts/chaincode-functions.sh"
source "$FABLO_NETWORK_ROOT/fabric-docker/channel-query-scripts.sh"
source "$FABLO_NETWORK_ROOT/fabric-docker/commands-generated.sh"
source "$FABLO_NETWORK_ROOT/fabric-docker/.env"

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
elif [ "$1" = "down" ]; then
  networkDown
elif [ "$1" = "reboot" ]; then
  networkDown
  networkUp
elif [ "$1" = "start" ]; then
  startNetwork
elif [ "$1" = "stop" ]; then
  stopNetwork
elif [ "$1" = "chaincode" ] && [ "$2" = "install" ]; then
  installChaincodes
elif [ "$1" = "chaincode" ] && [ "$2" = "upgrade" ]; then
  upgradeChaincode "$3" "$4"
elif [ "$1" = "channel" ]; then
  channelQuery "${@:2}"
elif [ "$1" = "help" ]; then
  printHelp
elif [ "$1" = "--help" ]; then
  printHelp
else
  echo "No command specified"
  echo "Basic commands are: up, down, start, stop, reboot"
  echo "To list channel query helper commands type: 'fablo channel --help'"
  echo "Also check: 'chaincode install'"
  echo "Use 'help' or '--help' for more information"
fi
