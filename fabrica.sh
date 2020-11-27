#!/bin/bash

set -e

FABRICA_IMAGE_TAG="0.0.1-alpha"
FABRICA_IMAGE_NAME="softwaremill/fabrica"
FABRICA_IMAGE="$FABRICA_IMAGE_NAME:$FABRICA_IMAGE_TAG"

COMMAND="$1"
FABRICA_NETWORK_ROOT="$(pwd)/fabrica-target"

#TODO 1 - how to store docker passwords
#TODO 2 - fabrica.sh prompt on compatible updates

printHelp() {
  echo "Fabrica -- kick-off and manage your Hyperledger Fabric network

Usage:
  fabrica.sh version [--verbose | -v]
    Prints current fabrica version, with optional details.

  fabrica.sh init
    Creates simple Fabrica config in current directory.

  fabrica.sh generate [/path/to/fabrica-config.json [/path/to/fabrica/target]]
    Generates network configuration files in the given directory. Default config file path is '\$(pwd)/fabrica-config.json', default (and recommended) directory '\$(pwd)/fabrica-target'.

  fabrica.sh up [/path/to/fabrica-config.json]
    Starts the Hyperledger Fabric network for given Fabrica configuration file, creates channels, installs and instantiates chaincodes. If there is no configuration, it will call 'generate' command for given config file.

  fabrica.sh [down | start | stop]
    Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. This is similar to down, start and stop commands for Docker Compose.

  fabrica.sh chaincode upgrade <chaincode-name> <version>
    Upgrades and instantiates chaincode on all relevant peers. Chaincode directory is specified in Fabrica config file.

  fabrica.sh [help | --help]
    Prints the manual.

  fabrica.sh updates
    Prints all newer versions available.

  fabrica.sh updateTo <version>
    Updates Fabrica to specified version."
}

printVersion() {
  optional_full_flag=$1
  docker run -it --rm \
    -u "$(id -u):$(id -g)" \
    -v $(pwd):/network/target \
    $FABRICA_IMAGE sh -c "/fabrica/docker-entrypoint.sh version $optional_full_flag"
}

printUpdates() {
    docker run -it --rm \
    -u "$(id -u):$(id -g)" \
    -v $(pwd):/network/target \
    $FABRICA_IMAGE sh -c "/fabrica/docker-entrypoint.sh check-updates"
}

init() {
    docker run -it --rm \
    -u "$(id -u):$(id -g)" \
    -v $(pwd):/network/target \
    $FABRICA_IMAGE sh -c "/fabrica/docker-entrypoint.sh init"
}

updateTo() {
  version=$1

  if [ -z "$version" ]; then
    echo "Please specify version number, ie:"
    echo "fabrica.sh updateTo 0.1.0"
    exit 1
  fi

  sudo curl -Lf https://github.com/softwaremill/fabrica/releases/download/"$version"/fabrica.sh -o /usr/local/bin/fabrica.sh && sudo chmod +x /usr/local/bin/fabrica.sh
}

validateConfig() {
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

  docker run -i --rm \
    -v "$FABRICA_CONFIG":/network/fabrica-config.json \
    -v $(pwd):/network/target \
    --env FABRICA_CONFIG="/network/fabrica-config.json" \
    -u "$(id -u):$(id -g)" \
    $FABRICA_IMAGE sh -c "/fabrica/docker-entrypoint.sh validate ../fabrica-config.json"
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
  echo "    FABRICA_IMAGE:       $FABRICA_IMAGE"
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
    $FABRICA_IMAGE
}

if [ -z "$COMMAND" ]; then
  printHelp
  exit 1

elif [ "$COMMAND" = "help" ] || [ "$COMMAND" = "--help" ]; then
  printHelp

elif [ "$COMMAND" = "version" ]; then
  printVersion "$2"
elif [ "$COMMAND" = "updates" ]; then
  printUpdates
elif [ "$COMMAND" = "updateTo" ]; then
  updateTo "$2"
elif [ "$COMMAND" = "init" ]; then
  init
elif [ "$COMMAND" = "validate" ]; then
  validateConfig "$2"
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
