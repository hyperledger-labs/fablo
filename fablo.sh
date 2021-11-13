#!/usr/bin/env bash

set -e

FABLO_VERSION="0.3.0-unstable"
FABLO_IMAGE_NAME="softwaremill/fablo"
FABLO_IMAGE="$FABLO_IMAGE_NAME:$FABLO_VERSION"

COMMAND="$1"
COMMAND_CALL_ROOT="$(pwd)"
FABLO_TARGET="$COMMAND_CALL_ROOT/fablo-target"

# Create temporary directory and remove it after script execution
FABLO_TEMP_DIR="$(mktemp -d -t fablo.XXXXXXXX)"
# shellcheck disable=SC2064
trap "rm -rf \"$FABLO_TEMP_DIR\"" EXIT

getDefaultFabloConfig() {
  local fablo_config_json="$COMMAND_CALL_ROOT/fablo-config.json"
  local fablo_config_yaml="$COMMAND_CALL_ROOT/fablo-config.yaml"

  if [ -f "$fablo_config_json" ]; then
    echo "$fablo_config_json"
  elif [ -f "$fablo_config_yaml" ]; then
    echo "$fablo_config_yaml"
  else
    echo "$fablo_config_json"
  fi
}

printHelp() {
  echo "Fablo -- kick-off and manage your Hyperledger Fabric network

Usage:
  fablo.sh init [node] [rest]
    Creates simple Fablo config in current directory with optional Node.js sample chaincode and REST API.

  fablo.sh generate [/path/to/fablo-config.json|yaml [/path/to/fablo/target]]
    Generates network configuration files in the given directory. Default config file path is '\$(pwd)/fablo-config.json' or '\$(pwd)/fablo-config.yaml', default (and recommended) directory '\$(pwd)/fablo-target'.

  fablo.sh up [/path/to/fablo-config.json|yaml]
    Starts the Hyperledger Fabric network for given Fablo configuration file, creates channels, installs and instantiates chaincodes. If there is no configuration, it will call 'generate' command for given config file.

  fablo.sh <down | start | stop>
    Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. This is similar to down, start and stop commands for Docker Compose.

  fablo.sh reboot
    Downs and ups the network. Network state is lost, but the configuration is kept intact.

  fablo.sh prune
    Downs the network and removes all generated files.

  fablo.sh recreate [/path/to/fablo-config.json|yaml]
    Prunes and ups the network. Default config file path is '\$(pwd)/fablo-config.json' or '\$(pwd)/fablo-config.yaml'.

  fablo.sh chaincode upgrade <chaincode-name> <version>
    Upgrades and instantiates chaincode on all relevant peers. Chaincode directory is specified in Fablo config file.

  fablo.sh channel --help
    To list available channel query options which can be executed on running network.

  fablo.sh use [version]
    Updates this Fablo script to specified version. Prints all versions if no version parameter is provided.

  fablo.sh <help | --help>
    Prints the manual.

  fablo.sh version [--verbose | -v]
    Prints current Fablo version, with optional details."
}

executeOnFabloDocker() {
  local command_with_params="$1"
  local fablo_workspace="${2:-$FABLO_TEMP_DIR}"
  local fablo_config="$3"

  local fablo_workspace_params=(
    -v "$fablo_workspace":/network/workspace
  )

  local fablo_config_params=()
  if [ -n "$fablo_config" ]; then
    if [ ! -f "$fablo_config" ]; then
      echo "File $fablo_config does not exist"
      exit 1
    fi

    fablo_config="$(cd "$(dirname "$fablo_config")" && pwd)/$(basename "$fablo_config")"
    local chaincodes_base_dir="$(dirname "$fablo_config")"
    fablo_config_params=(
      -v "$fablo_config":/network/fablo-config.json
      --env "FABLO_CONFIG=$fablo_config"
      --env "CHAINCODES_BASE_DIR=$chaincodes_base_dir"
    )
  fi

  docker run -i --rm \
    "${fablo_workspace_params[@]}" \
    "${fablo_config_params[@]}" \
    -u "$(id -u):$(id -g)" \
    $FABLO_IMAGE sh -c "/fablo/docker-entrypoint.sh \"$command_with_params\"" \
    2>&1
}

useVersion() {
  local version="$1"

  if [ -n "$version" ]; then
    echo "Updating '$0' to version $version..."
    set +e
    curl -Lf https://github.com/softwaremill/fablo/releases/download/"$version"/fablo.sh -o "$0" && chmod +x "$0"
  else
    executeOnFabloDocker "fablo:list-versions"
  fi
}

initConfig() {
  executeOnFabloDocker "fablo:init $1 $2"
  cp -R -i "$FABLO_TEMP_DIR/." "$COMMAND_CALL_ROOT/"
}

validateConfig() {
  local fablo_config=${1:-$(getDefaultFabloConfig)}
  executeOnFabloDocker "fablo:validate" "" "$fablo_config"
}

extendConfig() {
  local fablo_config=${1:-$(getDefaultFabloConfig)}
  executeOnFabloDocker "fablo:extend-config" "" "$fablo_config"
}

generateNetworkConfig() {
  local fablo_config=${1:-$(getDefaultFabloConfig)}
  local fablo_target=${2:-$FABLO_TARGET}

  echo "Generating network config"
  echo "    FABLO_VERSION:      $FABLO_VERSION"
  echo "    FABLO_CONFIG:       $fablo_config"
  echo "    FABLO_NETWORK_ROOT: $fablo_target"

  mkdir -p "$fablo_target"
  executeOnFabloDocker "fablo:setup-docker" "$fablo_target" "$fablo_config"
}

networkPrune() {
  if [ -f "$FABLO_TARGET/fabric-docker.sh" ]; then
    "$FABLO_TARGET/fabric-docker.sh" down
  fi
  echo "Removing $FABLO_TARGET"
  rm -rf "$FABLO_TARGET"
}

networkUp() {
  if [ ! -d "$FABLO_TARGET" ] || [ -z "$(ls -A "$FABLO_TARGET")" ]; then
    echo "Network target directory is empty"
    generateNetworkConfig "$1"
  fi
  "$FABLO_TARGET/fabric-docker.sh" up
}

if [ -z "$COMMAND" ]; then
  printHelp
  exit 1

elif [ "$COMMAND" = "help" ] || [ "$COMMAND" = "--help" ]; then
  printHelp

elif [ "$COMMAND" = "version" ]; then
  executeOnFabloDocker "fablo:version $2"

elif [ "$COMMAND" = "use" ]; then
  useVersion "$2"

elif [ "$COMMAND" = "init" ]; then
  initConfig "$2" "$3"

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
  echo "Executing Fablo docker command: $COMMAND"
  "$FABLO_TARGET/fabric-docker.sh" "$COMMAND" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
fi
