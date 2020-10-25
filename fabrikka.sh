#!/bin/sh

# TODO: https://wizardzines.com/comics/bash-errors/

if [ -z "$1" ]; then
  echo "Usage: fabrikka.sh command [./fabrikka-config.json"]
  exit 1
fi

FABRIKKA_HOME="$(cd "$(dirname "$0")" && pwd)"
COMMAND="$1"
FABRIKKA_NETWORK_ROOT="$(pwd)"

if [ "$COMMAND" = "build" ]; then
  docker build --tag fabrikka "$FABRIKKA_HOME" &&
    exit 0

elif [ "$COMMAND" = "help" ] || [ "$COMMAND" = "--help" ]; then
  cat "$FABRIKKA_HOME/fabrikka-help.txt"

elif [ "$COMMAND" = "generate" ]; then
  if [ -z "$2" ]; then
    FABRIKKA_CONFIG="$FABRIKKA_NETWORK_ROOT/fabrikka-config.json"
    if [ ! -f "$FABRIKKA_CONFIG" ]; then
      echo "File $FABRIKKA_CONFIG does not exist"
      exit 1
    fi
  else
    if [ ! -f "$2" ]; then
      echo "File $2 does not exist"
      exit 1
    fi
    FABRIKKA_CONFIG="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
  fi

  FABRIKKA_CHAINCODES_ROOT="$(dirname "$FABRIKKA_CONFIG")"

  echo "Generating network config"
  echo "    FABRIKKA_CONFIG:          $FABRIKKA_CONFIG"
  echo "    FABRIKKA_CHAINCODES_ROOT: $FABRIKKA_CHAINCODES_ROOT"
  echo "    FABRIKKA_NETWORK_ROOT:    $FABRIKKA_NETWORK_ROOT"

  docker run -i --rm \
    -v "$FABRIKKA_CONFIG":/network/fabrikka-config.json \
    -v "$FABRIKKA_NETWORK_ROOT":/network/docker \
    -v /tmp:/home/yeoman \
    -u "$(id -u):$(id -g)" \
    fabrikka &&
    echo "FABRIKKA_NETWORK_ROOT=$FABRIKKA_NETWORK_ROOT" >>"$FABRIKKA_NETWORK_ROOT/fabric-docker/.env" &&
    echo "FABRIKKA_CHAINCODES_ROOT=$FABRIKKA_CHAINCODES_ROOT" >>"$FABRIKKA_NETWORK_ROOT/fabric-docker/.env" &&
    exit 0

elif [ "$COMMAND" = "up" ]; then
  if [ -z "$(ls -A "$FABRIKKA_NETWORK_ROOT")" ]; then
    echo "Network target directory is empty"
    "$FABRIKKA_NETWORK_ROOT/fabrikka-docker.sh" generate "$2"
  fi

  "$FABRIKKA_NETWORK_ROOT/fabrikka-docker.sh" up &&
    exit 0

else
  echo "Executing Fabrikka docker command: $COMMAND"
  "$FABRIKKA_NETWORK_ROOT/fabrikka-docker.sh" "$COMMAND" &&
    exit 0
fi
