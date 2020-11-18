#!/bin/bash

set -e

COMMAND="$1"
FABRICA_NETWORK_ROOT="$(pwd)/fabrica-target"

printHelp() {
  echo "Fabrica -- kick-off and manage your Hyperledger Fabric network

Usage:

  fabrica.sh generate [/path/to/fabrica-config.json [/path/to/fabrica/target]]
    Generates network configuration files in the given directory. Default config file path is '\$(pwd)/fabrica-config.json', default (and recommended) directory '\$(pwd)/fabrica-target'.

  fabrica.sh up [/path/to/fabrica-config.json]
    Starts the Hyperledger Fabric network for given Fabrica configuration file, creates channels, installs and instantiates chaincodes. If there is no configuration, it will call 'generate' command for given config file.

  fabrica.sh [down | start | stop]
    Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. This is similar to down, start and stop commands for Docker Compose.

  fabrica.sh chaincode upgrade <chaincode-name> <version>
    Upgrades and instantiates chaincode on all relevant peers. Chaincode directory is specified in Fabrica config file.

  fabrica.sh [help | --help]
    Prints the manual."
}

generateNetworkConfig() {
  if [ -z "$1" ]; then
    FABRICA_CONFIG="$FABRICA_NETWORK_ROOT/fabrica-config.json"
    if [ ! -f "$FABRICA_CONFIG" ]; then
      echo "File $FABRICA_CONFIG does not exist"
      exit 1
    fi
  else
    if [ ! -f "$1" ]; then
      echo "File $1 does not exist"
      exit 1
    fi
    FABRICA_CONFIG="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  fi

  CHAINCODES_BASE_DIR="$(dirname "$FABRICA_CONFIG")"

  echo "Generating network config"
  echo "    FABRICA_CONFIG:       $FABRICA_CONFIG"
  echo "    CHAINCODES_BASE_DIR:   $CHAINCODES_BASE_DIR"
  echo "    FABRICA_NETWORK_ROOT: $FABRICA_NETWORK_ROOT"

  mkdir -p "$FABRICA_NETWORK_ROOT"

  docker run -i --rm \
    -v "$FABRICA_CONFIG":/network/fabrica-config.json \
    -v "$FABRICA_NETWORK_ROOT":/network/target \
    --env FABRICA_CONFIG="$FABRICA_CONFIG" \
    --env CHAINCODES_BASE_DIR="$CHAINCODES_BASE_DIR" \
    --env FABRICA_NETWORK_ROOT="$FABRICA_NETWORK_ROOT" \
    -u "$(id -u):$(id -g)" \
    fabrica
}

if [ -z "$COMMAND" ]; then
  printHelp
  exit 1

elif [ "$COMMAND" = "help" ] || [ "$COMMAND" = "--help" ]; then
  printHelp

elif [ "$COMMAND" = "version" ]; then
  docker run -it --rm \
    -u "$(id -u):$(id -g)" \
    fabrica sh -c "yo --no-insight fabrica:version"

elif [ "$COMMAND" = "generate" ]; then
  generateNetworkConfig "$2"
  if [ -n "$3" ]; then
    mkdir -p "$3" && mv -R "$FABRICA_NETWORK_ROOT" "$3/*"
  fi

elif [ "$COMMAND" = "up" ]; then
  if [ -z "$(ls -A "$FABRICA_NETWORK_ROOT")" ]; then
    echo "Network target directory is empty"
    generateNetworkConfig "$2"
  fi
  "$FABRICA_NETWORK_ROOT/fabric-docker.sh" up

else
  echo "Executing Fabrica docker command: $COMMAND"
  "$FABRICA_NETWORK_ROOT/fabric-docker.sh" "$COMMAND" "$2" "$3" "$4"
fi
