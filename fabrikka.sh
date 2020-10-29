#!/bin/sh

COMMAND="$1"
FABRIKKA_NETWORK_ROOT="$(pwd)/fabrikka-target/network" # TODO https://github.com/softwaremill/fabrikka/issues/73

printHelp() {
  echo "Fabrikka -- kick-off and manage your Hyperledger Fabric network

Usage:

  fabrikka.sh generate [/path/to/fabrikka-config.json [/path/to/fabrikka/target]]
   Generates network configuration files in the given directory. Default config file path is '\$(pwd)/fabrikka-config.json', default (and recommended) directory '\$(pwd)/.fabrikka'.

  fabrikka.sh up [/path/to/fabrikka-config.json]
    Starts the Hyperledger Fabric network for configuration in the current directory. If there is no configuration, it will call 'generate' command for given config file.

  fabrikka.sh [down | start | stop]
    Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. (Similar to down, start and stop commands for Docker Compose).

  fabrikka.sh [help | --help]
    Prints the manual."
}

if [ -z "$COMMAND" ]; then
  printHelp
  exit 1

elif [ "$COMMAND" = "help" ] || [ "$COMMAND" = "--help" ]; then
  printHelp

elif [ "$COMMAND" = "generate" ]; then
  if [ -n "$3" ]; then
    FABRIKKA_NETWORK_ROOT="$3"
    mkdir -p "$FABRIKKA_NETWORK_ROOT"
  fi

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

  CHAINCODES_BASE_DIR="$(dirname "$FABRIKKA_CONFIG")"

  echo "Generating network config"
  echo "    FABRIKKA_CONFIG:       $FABRIKKA_CONFIG"
  echo "    CHAINCODES_BASE_DIR:   $CHAINCODES_BASE_DIR"
  echo "    FABRIKKA_NETWORK_ROOT: $FABRIKKA_NETWORK_ROOT"

  docker run -i --rm \
    -v "$FABRIKKA_CONFIG":/network/fabrikka-config.json \
    -v "$FABRIKKA_NETWORK_ROOT":/network/docker \
    -v /tmp:/home/yeoman \
    -u "$(id -u):$(id -g)" \
    fabrikka &&
    echo "FABRIKKA_CONFIG=$FABRIKKA_CONFIG" >>"$FABRIKKA_NETWORK_ROOT/fabric-docker/.env" &&
    echo "CHAINCODES_BASE_DIR=$CHAINCODES_BASE_DIR" >>"$FABRIKKA_NETWORK_ROOT/fabric-docker/.env"

elif [ "$COMMAND" = "up" ]; then
  if [ -z "$(ls -A "$FABRIKKA_NETWORK_ROOT")" ]; then
    echo "Network target directory is empty"
    "$FABRIKKA_NETWORK_ROOT/fabric-docker.sh" generate "$2"
  fi

  "$FABRIKKA_NETWORK_ROOT/fabric-docker.sh" up

else
  echo "Executing Fabrikka docker command: $COMMAND"
  "$FABRIKKA_NETWORK_ROOT/fabric-docker.sh" "$COMMAND" "$2" "$3" "$4"
fi
