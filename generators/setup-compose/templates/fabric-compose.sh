#!/bin/bash
function get_realpath() {
  [[ ! -f "$1" ]] && return 1 # failure : file does not exist.
  [[ -n "$no_symlinks" ]] && local pwdp='pwd -P' || local pwdp='pwd' # do symlinks.
  echo "$( cd "$( echo "${1%/*}" )" 2>/dev/null || exit; $pwdp )"/"${1##*/}" # echo result.
  return 0 # success
}

SCRIPT=$(get_realpath "$0")
BASEDIR=$(dirname "$SCRIPT")

source "$BASEDIR"/fabric-compose/scripts/base-help.sh
source "$BASEDIR"/fabric-compose/scripts/base-functions.sh
source "$BASEDIR"/fabric-compose/commands-generated.sh

source "$BASEDIR"/fabric-compose/.env

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
