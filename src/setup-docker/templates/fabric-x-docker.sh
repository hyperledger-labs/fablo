#!/usr/bin/env bash
set -eu

FABLO_NETWORK_ROOT="$(cd "$(dirname "$0")" && pwd)"
FABRIC_X_ROOT="$FABLO_NETWORK_ROOT/fabric-x"

source "$FABLO_NETWORK_ROOT/fabric-x/scripts/base-help.sh"
source "$FABLO_NETWORK_ROOT/fabric-x/scripts/commands-generated.sh"

if [ "$1" = "up" ]; then
  networkUp
elif [ "$1" = "down" ]; then
  networkDown
elif [ "$1" = "reset" ]; then
  networkDown
  networkUp
elif [ "$1" = "start" ]; then
  startNetwork
elif [ "$1" = "stop" ]; then
  stopNetwork
elif [ "$1" = "namespace" ] && [ "$2" = "list" ]; then
  namespaceList
elif [ "$1" = "namespace" ] && [ "$2" = "init" ]; then
  namespaceInit
elif [ "$1" = "help" ]; then
  printHelp
elif [ "$1" = "--help" ]; then
  printHelp
else
  echo "No command specified"
  echo "Basic commands are: up, down, start, stop, reset"
  echo "Also check: 'namespace list', 'namespace init'"
  echo "Use 'help' or '--help' for more information"
fi