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

yeomanGenerate() {
  echo "Generating network config"
  echo "    NETWORK_CONFIG: $NETWORK_CONFIG"
  echo "    NETWORK_TARGET: $NETWORK_TARGET"
  echo "    CHAINCODES:     $CHAINCODES"

  rm -rf "$NETWORK_TARGET" &&
    mkdir -p "$NETWORK_TARGET" &&
    docker run -i --rm \
      -v "$NETWORK_CONFIG":/network/fabrikka-config.json \
      -v "$NETWORK_TARGET":/network/docker \
      -v "$CHAINCODES":/network/chaincodes \
      -v /tmp:/home/yeoman \
      --env COMMAND="generate" \
      --env NETWORK_CONFIG="$NETWORK_CONFIG" \
      --env NETWORK_TARGET="$NETWORK_TARGET" \
      --env CHAINCODES="$CHAINCODES" \
      -u "$(id -u):$(id -g)" \
      fabrikka
}

executeNetworkCommand() {
  docker run -i --rm \
    -v "$NETWORK_CONFIG":/network/fabrikka-config.json \
    -v "$NETWORK_TARGET":/network/docker \
    -v "$CHAINCODES":/network \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --env COMMAND="$COMMAND" \
    --env NETWORK_CONFIG="$NETWORK_CONFIG" \
    --env NETWORK_TARGET="$NETWORK_TARGET" \
    --env CHAINCODES="$CHAINCODES" \
    fabrikka
}

if [ "$COMMAND" = "generate" ]; then
  yeomanGenerate
elif [ -z "$(ls -A "$NETWORK_TARGET")" ]; then
  echo "Network target directory is empty"
  yeomanGenerate
else
  echo "Use command 'generate' to overwrite network config"
fi

if [ "$COMMAND" != "generate" ]; then
  echo "Executing Fabrikka docker command: $COMMAND"
  executeNetworkCommand
fi
