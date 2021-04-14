#!/usr/bin/env bash

set -e

FABRICA_VERSION="0.1.0-unstable"
FABRICA_IMAGE_NAME="softwaremill/fabrica"
FABRICA_IMAGE="$FABRICA_IMAGE_NAME:$FABRICA_VERSION"

COMMAND="$1"
COMMAND_CALL_ROOT="$(pwd)"
FABRICA_TARGET="$COMMAND_CALL_ROOT/fabrica-target"
DEFAULT_FABRICA_CONFIG="$COMMAND_CALL_ROOT/fabrica-config.json"

# Create temporary directory and remove it after script execution
FABRICA_TEMP_DIR="$(mktemp -d -t fabrica.XXXXXXXX)"
# shellcheck disable=SC2064
trap "rm -rf \"$FABRICA_TEMP_DIR\"" EXIT

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

  fabrica.sh channel --help
    To list available channel query options which can be executed on running network.

  fabrica.sh use [version]
    Updates this Fabrica script to specified version. Prints all versions if no version parameter is provided.

  fabrica.sh <help | --help>
    Prints the manual.

  fabrica.sh version [--verbose | -v]
    Prints current Fabrica version, with optional details."
}

executeOnFabricaDocker() {
  local passed_command="$1"
  local passed_param="$2"
  local fabrica_workspace="${3:-$FABRICA_TEMP_DIR}"
  local fabrica_config="$4"

  local fabrica_workspace_params=(
    -v "$fabrica_workspace":/network/workspace
  )

  local fabrica_config_params=()
  if [ -n "$fabrica_config" ]; then
    if [ ! -f "$fabrica_config" ]; then
      echo "File $fabrica_config does not exist"
      exit 1
    fi

    fabrica_config="$(cd "$(dirname "$fabrica_config")" && pwd)/$(basename "$fabrica_config")"
    local chaincodes_base_dir="$(dirname "$fabrica_config")"
    fabrica_config_params=(
      -v "$fabrica_config":/network/fabrica-config.json
      --env "FABRICA_CONFIG=$fabrica_config"
      --env "CHAINCODES_BASE_DIR=$chaincodes_base_dir"
    )
  fi

  docker run -i --rm \
    "${fabrica_workspace_params[@]}" \
    "${fabrica_config_params[@]}" \
    -u "$(id -u):$(id -g)" \
    $FABRICA_IMAGE sh -c "/fabrica/docker-entrypoint.sh \"$passed_command\" \"$passed_param\"" \
    2>&1
}

useVersion() {
  local version="$1"

  if [ -n "$version" ]; then
    echo "Updating '$0' to version $version..."
    set +e
    curl -Lf https://github.com/softwaremill/fabrica/releases/download/"$version"/fabrica.sh -o "$0" && chmod +x "$0"
  else
    executeOnFabricaDocker list-versions
  fi
}

initConfig() {
  executeOnFabricaDocker init
  cp -R -i "$FABRICA_TEMP_DIR/." "$COMMAND_CALL_ROOT/"
}

validateConfig() {
  local fabrica_config=${1:-$DEFAULT_FABRICA_CONFIG}
  executeOnFabricaDocker validate "" "" "$fabrica_config"
}

extendConfig() {
  local fabrica_config=${1:-$DEFAULT_FABRICA_CONFIG}
  executeOnFabricaDocker extend-config "" "" "$fabrica_config"
}

generateNetworkConfig() {
  local fabrica_config=${1:-$DEFAULT_FABRICA_CONFIG}
  local fabrica_target=${2:-$FABRICA_TARGET}

  echo "Generating network config"
  echo "    FABRICA_VERSION:      $FABRICA_VERSION"
  echo "    FABRICA_CONFIG:       $fabrica_config"
  echo "    FABRICA_NETWORK_ROOT: $fabrica_target"

  mkdir -p "$fabrica_target"
  executeOnFabricaDocker "" "" "$fabrica_target" "$fabrica_config"
}

networkPrune() {
  if [ -f "$FABRICA_TARGET/fabric-docker.sh" ]; then
    "$FABRICA_TARGET/fabric-docker.sh" down
  fi
  echo "Removing $FABRICA_TARGET"
  rm -rf "$FABRICA_TARGET"
}

networkUp() {
  if [ ! -d "$FABRICA_TARGET" ] || [ -z "$(ls -A "$FABRICA_TARGET")" ]; then
    echo "Network target directory is empty"
    generateNetworkConfig "$1"
  fi
  "$FABRICA_TARGET/fabric-docker.sh" up
}

if [ -z "$COMMAND" ]; then
  printHelp
  exit 1

elif [ "$COMMAND" = "help" ] || [ "$COMMAND" = "--help" ]; then
  printHelp

elif [ "$COMMAND" = "version" ]; then
  executeOnFabricaDocker version "$2"

elif [ "$COMMAND" = "use" ]; then
  useVersion "$2"

elif [ "$COMMAND" = "init" ]; then
  initConfig

elif [ "$COMMAND" = "validate" ]; then
  validateConfig "$2"

elif [ "$COMMAND" = "extend-config" ]; then
  extendConfig "$2"

elif [ "$COMMAND" = "generate" ]; then
  generateNetworkConfig "$2" "$3"

elif [ "$COMMAND" = "up" ]; then
  networkUp "$2"

elif [ "$COMMAND" = "prune" ]; then
  networkPrune

elif [ "$COMMAND" = "recreate" ]; then
  networkPrune
  networkUp "$2"

else
  echo "Executing Fabrica docker command: $COMMAND"
  "$FABRICA_TARGET/fabric-docker.sh" "$COMMAND" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
fi
