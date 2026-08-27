#!/usr/bin/env bash

set -e

# Test Harness & Workspace Scaffolding

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."

export FABLO_HOME

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS"
  docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  (for name in $(docker ps --format '{{.Names}}'); do dumpLogs "$name"; done)
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" down || true)
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

echo "Starting Fabric-X Network Initialization..."
"$FABLO_HOME/fablo-build.sh"

# Scaffold the network profile
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" init fabric-x)

# Validate the generated profile
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" validate)

# Generate artifacts and spin up Docker containers
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" up)

echo "Network started successfully."

# Artifact Verification & Container Health Checks
echo "Running Artifact Verification..."

assert_non_empty() {
  local file="$1"
  if [ -z "$file" ] || [ ! -s "$file" ]; then
    echo "Error: Artifact missing or empty."
    exit 1
  fi
  echo "Verified artifact exists and is non-empty: $file"
}

# Locate generated Fabric-X artifacts
CONFIG_BLOCK=$(find "$TEST_TMP/fablo-target" -name "config-block.pb.bin" | head -n 1)
SHARED_CONFIG=$(find "$TEST_TMP/fablo-target" -name "shared_config.binpb" | head -n 1)
CLIENT_TLS=$(find "$TEST_TMP/fablo-target" -name "client-tls-ca.pem" | head -n 1)

assert_non_empty "$CONFIG_BLOCK"
assert_non_empty "$SHARED_CONFIG"
assert_non_empty "$CLIENT_TLS"

echo "Running Container Health Checks..."
# Check that containers for this project are running
# Typically fablo networks use a common label or prefix. Here we verify that at least some orderer/peer components are up.
RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}')

if ! echo "$RUNNING_CONTAINERS" | grep -q "orderer"; then
  echo "Error: No orderer containers found running."
  exit 1
fi

if ! echo "$RUNNING_CONTAINERS" | grep -q "peer\|committer"; then
  echo "Error: No peer/committer containers found running."
  exit 1
fi

echo "All required Fabric-X containers are running."

# Namespace & Lifecycle Regression Validation
echo "Running Namespace & Lifecycle Regression Validation..."

run_fablo() {
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" "$@")
}

echo "1. Zero State"
NS_LIST=$(run_fablo namespace list 2>&1 || true)
if echo "$NS_LIST" | grep -q "mynamespace"; then
  echo "Error: Expected 0 namespaces in zero state. Found: $NS_LIST"
  exit 1
fi

echo "2. Commit State"
run_fablo namespace init

echo "3. Post-Init Query"
NS_LIST=$(run_fablo namespace list 2>&1)
if ! echo "$NS_LIST" | grep -q "mynamespace"; then
  echo "Error: mynamespace not found after init. Output: $NS_LIST"
  exit 1
fi

echo "4. Idempotency"
run_fablo namespace init

echo "5. Cache / Up Skip"
run_fablo up

echo "6. Stop / Start"
run_fablo stop
run_fablo start
NS_LIST=$(run_fablo namespace list 2>&1)
if ! echo "$NS_LIST" | grep -q "mynamespace"; then
  echo "Error: mynamespace not found after stop/start. Output: $NS_LIST"
  exit 1
fi

echo "7. Reset State"
run_fablo reset
# After reset, it might error if the target is deleted, or return an empty list.
# We just want to ensure it doesn't show 'mynamespace' anymore.
NS_LIST_RESET=$(run_fablo namespace list 2>&1 || true)
if echo "$NS_LIST_RESET" | grep -q "mynamespace"; then
  echo "Error: mynamespace should be gone after reset."
  exit 1
fi

echo "Test passed ✅"
