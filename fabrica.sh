#!/bin/bash

set -e

FABRICA_VERSION="0.0.1"
FABRICA_IMAGE_NAME="softwaremill/fabrica"
FABRICA_IMAGE="$FABRICA_IMAGE_NAME:$FABRICA_VERSION"

COMMAND="$1"
FABRICA_NETWORK_ROOT="$(pwd)/fabrica-target"

printHelp() {
  echo "Fabrica -- kick-off and manage your Hyperledger Fabric network

Usage:
  fabrica.sh init
    Creates simple Fabrica config in current directory.

  fabrica.sh generate [/path/to/fabrica-config.json [/path/to/fabrica/target]]
    Generates network configuration files in the given directory. Default config file path is '\$(pwd)/fabrica-config.json', default (and recommended) directory '\$(pwd)/fabrica-target'.

  fabrica.sh up [/path/to/fabrica-config.json]
    Starts the Hyperledger Fabric network for given Fabrica configuration file, creates channels, installs and instantiates chaincodes. If there is no configuration, it will call 'generate' command for given config file.

  fabrica.sh <down | start | stop>
    Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. This is similar to down, start and stop commands for Docker Compose.

  fabrica.sh reboot
    Downs and ups the network. Network state is lost, but the configuration is kept intact.

  fabrica.sh prune
    Downs the network and removes all generated files.

  fabrica.sh recreate [/path/to/fabrica-config.json]
    Prunes and ups the network. Default config file path is '\$(pwd)/fabrica-config.json'

  fabrica.sh chaincode upgrade <chaincode-name> <version>
    Upgrades and instantiates chaincode on all relevant peers. Chaincode directory is specified in Fabrica config file.

  fabrica.sh use [version]
    Updates this Fabrica script to specified version. Prints all versions if no version parameter is provided.

  fabrica.sh <help | --help>
    Prints the manual.

  fabrica.sh version [--verbose | -v]
    Prints current Fabrica version, with optional details."
}

executeOnFabricaDockerConsolePrintOnly() {
  passed_command=$1
  docker run -i --rm \
    -u "$(id -u):$(id -g)" \
    -v "$(pwd)":/network/target \
    $FABRICA_IMAGE sh -c "/fabrica/docker-entrypoint.sh $passed_command"
}

executeOnFabricaDockerMountedAllDirs() {
  local passed_command="$1"

  mkdir -p "$FABRICA_NETWORK_ROOT"
  docker run -i --rm \
    -v "$FABRICA_CONFIG":/network/fabrica-config.json \
    -v "$FABRICA_NETWORK_ROOT":/network/target \
    --env FABRICA_CONFIG="$FABRICA_CONFIG" \
    --env CHAINCODES_BASE_DIR="$CHAINCODES_BASE_DIR" \
    --env FABRICA_NETWORK_ROOT="$FABRICA_NETWORK_ROOT" \
    -u "$(id -u):$(id -g)" \
    $FABRICA_IMAGE sh -c "/fabrica/docker-entrypoint.sh $passed_command"
}

executeOnFabricaDockerMountedConfigFile() {
  local passed_command="$1"

  docker run -i --rm \
    -v "$FABRICA_CONFIG":/network/fabrica-config.json \
    -v $(pwd):/network/target \
    --env FABRICA_CONFIG="/network/fabrica-config.json" \
    -u "$(id -u):$(id -g)" \
    $FABRICA_IMAGE sh -c "/fabrica/docker-entrypoint.sh $passed_command"
}

printVersion() {
  optional_full_flag="$1"
  executeOnFabricaDockerConsolePrintOnly "version $optional_full_flag"
}

listVersions() {
  executeOnFabricaDockerConsolePrintOnly "list-versions"
}

init() {
  executeOnFabricaDockerConsolePrintOnly "init"
}

useVersion() {
  version=$1
  echo "Updating '$0' to version $version..."
  curl -Lf https://github.com/softwaremill/fabrica/releases/download/"$version"/fabrica.sh -o "$0" && chmod +x "$0"
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

  executeOnFabricaDockerMountedConfigFile "validate ../fabrica-config.json"
}

generateNetworkConfig() {
  mkdir -p "$FABRICA_NETWORK_ROOT"
  if [ -z "$1" ]; then
    FABRICA_CONFIG="$FABRICA_NETWORK_ROOT/../fabrica-config.json"
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
  echo "    FABRICA_VERSION:      $FABRICA_VERSION"
  echo "    FABRICA_CONFIG:       $FABRICA_CONFIG"
  echo "    CHAINCODES_BASE_DIR:  $CHAINCODES_BASE_DIR"
  echo "    FABRICA_NETWORK_ROOT: $FABRICA_NETWORK_ROOT"

  executeOnFabricaDockerMountedAllDirs ""
}

networkPrune() {
  if [ -f "$FABRICA_NETWORK_ROOT/fabric-docker.sh" ]; then
    "$FABRICA_NETWORK_ROOT/fabric-docker.sh" down
  fi
  echo "Removing $FABRICA_NETWORK_ROOT"
  rm -rf "$FABRICA_NETWORK_ROOT"
}

networkUp() {
  if [ ! -d "$FABRICA_NETWORK_ROOT" ] || [ -z "$(ls -A "$FABRICA_NETWORK_ROOT")" ]; then
    echo "Network target directory is empty"
    generateNetworkConfig "$1"
  fi
  "$FABRICA_NETWORK_ROOT/fabric-docker.sh" up
}

if [ -z "$COMMAND" ]; then
  printHelp
  exit 1

elif [ "$COMMAND" = "help" ] || [ "$COMMAND" = "--help" ]; then
  printHelp

elif [ "$COMMAND" = "version" ]; then
  printVersion "$2"

elif [ "$COMMAND" = "use" ] && [ -z "$2" ]; then
  listVersions

elif [ "$COMMAND" = "use" ] && [ -n "$2" ]; then
  useVersion "$2"

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
  networkUp "$2"

elif [ "$COMMAND" = "prune" ]; then
  networkPrune

elif [ "$COMMAND" = "recreate" ]; then
  networkPrune
  networkUp "$2"
else
  echo "Executing Fabrica docker command: $COMMAND"
  "$FABRICA_NETWORK_ROOT/fabric-docker.sh" "$COMMAND" "$2" "$3" "$4"
fi
