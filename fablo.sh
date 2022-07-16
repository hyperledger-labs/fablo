#!/usr/bin/env bash

set -e

FABLO_VERSION="1.1.0"
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

getSnapshotPath() {
  path="${1:-'snapshot'}"
  if echo "$path" | grep -q "tar.gz$"; then
    echo "$path"
  else
    echo "$path.fablo.tar.gz"
  fi
}

printSplash() {
  darkGray=$'\e[90m'
  end=$'\e[0m'
  echo ""
  echo "┌──────      .─.       ┌─────.    ╷           .────."
  echo "│           /   \      │      │   │         ╱        ╲ "
  echo "├─────     /     \     ├─────:    │        │          │"
  echo "│         /───────\    │      │   │         ╲        ╱ "
  printf "╵        /         \   └─────'    └──────     '────'    %24s\n" "v$FABLO_VERSION"
  echo "${darkGray}┌┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┐"
  echo "│ https://fablo.io | created at SoftwareMill | backed by Hyperledger Foundation│"
  echo "└┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘${end}"
}

printHelp() {
  printSplash
  echo "Usage:
  fablo init [node] [rest] [dev]
    Creates simple Fablo config in current directory with optional Node.js, chaincode and REST API and dev mode.

  fablo generate [/path/to/fablo-config.json|yaml [/path/to/fablo/target]]
    Generates network configuration files in the given directory. Default config file path is '\$(pwd)/fablo-config.json' or '\$(pwd)/fablo-config.yaml', default (and recommended) directory '\$(pwd)/fablo-target'.

  fablo up [/path/to/fablo-config.json|yaml]
    Starts the Hyperledger Fabric network for given Fablo configuration file, creates channels, installs and instantiates chaincodes. If there is no configuration, it will call 'generate' command for given config file.

  fablo <down | start | stop>
    Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. This is similar to down, start and stop commands for Docker Compose.

  fablo reset
    Downs and ups the network. Network state is lost, but the configuration is kept intact.

  fablo prune
    Downs the network and removes all generated files.

  fablo recreate [/path/to/fablo-config.json|yaml]
    Prunes and ups the network. Default config file path is '\$(pwd)/fablo-config.json' or '\$(pwd)/fablo-config.yaml'.

  fablo chaincodes install
    Installs all chaincodes on relevant peers. Chaincode directory is specified in Fablo config file.

  fablo chaincode install <chaincode-name> <version>
    Installs chaincode on all relevant peers. Chaincode directory is specified in Fablo config file.

  fablo chaincode upgrade <chaincode-name> <version>
    Upgrades chaincode on all relevant peers. Chaincode directory is specified in Fablo config file.

  fablo channel --help
    To list available channel query options which can be executed on running network.

  fablo snapshot <target-snapshot-path>
    Creates a snapshot of the network in target path. The snapshot contains all network state, including transactions and identities.

  fablo restore <source-snapshot-path>
    Restores the network from a snapshot.

  fablo use [version]
    Updates this Fablo script to specified version. Prints all versions if no version parameter is provided.

  fablo <help | --help>
    Prints the manual.

  fablo version [--verbose | -v]
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
  printSplash
  local version="$1"

  if [ -n "$version" ]; then
    echo "Updating '$0' to version $version..."
    set +e
    curl -Lf https://github.com/hyperledger-labs/fablo/releases/download/"$version"/fablo.sh -o "$0" && chmod +x "$0"
  else
    executeOnFabloDocker "fablo:list-versions"
  fi
}

initConfig() {
  printSplash
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
  printSplash
  local fablo_config=${1:-$(getDefaultFabloConfig)}
  local fablo_target=${2:-$FABLO_TARGET}

  echo "Generating network config"
  echo "    FABLO_VERSION:      $FABLO_VERSION"
  echo "    FABLO_CONFIG:       $fablo_config"
  echo "    FABLO_NETWORK_ROOT: $fablo_target"

  mkdir -p "$fablo_target"
  executeOnFabloDocker "fablo:setup-docker" "$fablo_target" "$fablo_config"
  ("$fablo_target/hooks/post-generate.sh")
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

executeFabloDockerCommand() {
  if [ ! -d "$FABLO_TARGET" ]; then
    echo "Error: This command needs the network to be generated at '$FABLO_TARGET'! Execute 'generate' or 'up' command."
    exit 1
  fi

  echo "Executing Fablo docker command: $1"
  "$FABLO_TARGET/fabric-docker.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
}

createSnapshot() {
  archive="$(getSnapshotPath "$1")"
  echo "Creating network snapshot in '$archive'"

  if [ -f "$archive" ]; then
    echo "Error: Snapshot file '$archive' already exists!"
    exit 1
  fi

  executeFabloDockerCommand snapshot "$FABLO_TEMP_DIR"
  (cd "$FABLO_TEMP_DIR" && tar czf tmp.tar.gz *)
  mv "$FABLO_TEMP_DIR/tmp.tar.gz" "$archive"
  echo "📦 Created snapshot at '$archive'!"
}

restoreSnapshot() {
  archive="$(getSnapshotPath "$1")"
  hook_command="$2"
  echo "📦 Restoring network from '$archive'"

  if [ ! -f "$archive" ]; then
    echo "Fablo snapshot file '$archive' does not exist!"
    exit 1
  fi

  tar -xf "$archive" -C "$FABLO_TEMP_DIR"
  "$FABLO_TEMP_DIR/fablo-target/fabric-docker.sh" clone-to "$COMMAND_CALL_ROOT" "$hook_command"
  echo "📦 Network restored from '$archive'! Execute 'start' command to run it."
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

elif [ "$COMMAND" = "snapshot" ]; then
  createSnapshot "$2"

elif [ "$COMMAND" = "restore" ]; then
  restoreSnapshot "$2" "${3:-""}"

else
  executeFabloDockerCommand "$COMMAND" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
fi
