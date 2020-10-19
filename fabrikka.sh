#!/bin/sh

# TODO: https://wizardzines.com/comics/bash-errors/

FABRIKKA_HOME="$(cd "$(dirname "$0")" && pwd)"
COMMAND="$1"

if [ "$1" = "build" ]; then
  docker build --tag fabrikka "$FABRIKKA_HOME" && exit 0
fi

if [ -z "$3" ]; then
  # TODO consider reasonable defaults
  echo "Usage: fabrikka.sh [command] ./fabrikka-config.json ./target-network-dir [./chaincodes-dir"]
  exit 1
fi

fullPath() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

NETWORK_CONFIG="$(fullPath "$2")"
NETWORK_TARGET="$(mkdir -p "$(dirname "$3")" && fullPath "$3")"
CHAINCODES="$(mkdir -p "$(dirname "$4")" && fullPath "$4")"

docker run -i --rm \
  -v "$NETWORK_CONFIG":/network/config.json \
  -v "$NETWORK_TARGET":/network/docker \
  -v "$CHAINCODES":/network/chaincodes \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --env COMMAND="$COMMAND" \
  --env NETWORK_CONFIG="$NETWORK_CONFIG" \
  --env NETWORK_TARGET="$NETWORK_TARGET" \
  --env CHAINCODES="$CHAINCODES" \
  fabrikka
