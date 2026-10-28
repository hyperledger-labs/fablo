#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."
export FABLO_HOME

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS"
  docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1 || true
}

run_fablo() {
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" "$@")
}

networkDown() {
  sleep 2
  (for name in $(docker ps -a --filter "label=com.docker.compose.project=fabric-x" --format '{{.Names}}'); do dumpLogs "$name"; done)
  run_fablo down
}

expectCommand() {
  sh "$TEST_TMP/../expect-command.sh" "$1" "$2"
}

networkUp() {
  run_fablo init fabric-x
  # four orderer parties, each with its own organization
  jq '.fabricX.orderer.parties = [range(1;5) | {organization: {name: "OrdererOrg\(.)", domain: "orderer-org-\(.)", mspName: "OrdererOrg\(.)MSP"}}]' \
    "$TEST_TMP/fablo-config.json" >"$TEST_TMP/fablo-config.json.tmp"
  mv "$TEST_TMP/fablo-config.json.tmp" "$TEST_TMP/fablo-config.json"
  run_fablo validate
  run_fablo up
}

trap networkDown EXIT
trap 'trap - EXIT ; networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network with four orderer parties
networkUp

# verify artifacts
CONFIG_BLOCK="$TEST_TMP/fablo-target/fabric-x/crypto/config-block.pb.bin"
SHARED_CONFIG="$TEST_TMP/fablo-target/fabric-x/crypto/shared_config.binpb"

if [ ! -s "$CONFIG_BLOCK" ] || [ ! -s "$SHARED_CONFIG" ]; then
  echo "Error: Artifact missing or empty"
  exit 1
fi

# one router, batcher, consenter and assembler for each of the four parties
expectCommand "docker ps --filter 'label=com.docker.compose.project=fabric-x' --format '{{.Names}}' | grep -cE '^orderer-party[1-4]-(router|batcher|consenter|assembler)$'" "^16$"

# the sidecar watches the orderer in BFT mode
expectCommand "grep fault-tolerance-level \"$TEST_TMP/fablo-target/fabric-x/config/sidecar.yaml\"" "BFT"

# a transaction is ordered by the four parties and committed
run_fablo namespace init
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "mynamespace"

echo "Test passed ✅"