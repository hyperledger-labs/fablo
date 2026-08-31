#!/usr/bin/env bash

set -euo pipefail
[ "${FABLO_TEST_DEBUG:-0}" = "1" ] && set -x # Enable verbose tracing in CI to pinpoint exact failing lines

# Test Harness & Workspace Scaffolding
TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."
export FABLO_HOME

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS"
  docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1 || true
}

networkDown() {
  local exit_code=$?
  set +e
  echo "Executing teardown. Capturing container logs..."
  docker ps -a --filter "label=com.docker.compose.project=fabric-x" --format '{{.Names}}' | while read -r name; do
    [ -n "$name" ] && dumpLogs "$name"
  done
  ( cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" down ) || true
  if [ $exit_code -ne 0 ]; then
    echo "❌ Test failed with exit code $exit_code"
  fi
  exit $exit_code
}

trap networkDown EXIT SIGINT

echo "Starting Fabric-X Network Initialization..."
"$FABLO_HOME/fablo-build.sh"

(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" init fabric-x)
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" validate)

# Helper function to run Fablo inside temp directory
run_fablo() {
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" "$@")
}

# Spin up Docker containers with retry loop to handle transient startup flakes
UP_SUCCESS=false
for i in {1..5}; do
  if run_fablo up; then
    UP_SUCCESS=true
    break
  fi
  if [ "$i" -lt 5 ]; then
    echo "fablo up failed (attempt $i). Cleaning and retrying in 10s..."
    run_fablo down || true
    sleep 10
  else
    echo "fablo up failed (attempt $i). Final attempt failed."
  fi
done

if [ "$UP_SUCCESS" = false ]; then
  echo "Error: fablo up failed after 5 attempts."
  exit 1
fi

echo "Network started successfully."

# Artifact Verification
echo "Running Artifact Verification..."
assert_non_empty() {
  local file="$1"
  if [ -z "$file" ] || [ ! -s "$file" ]; then
    echo "Error: Artifact missing or empty: $file"
    exit 1
  fi
  echo "Verified artifact exists and is non-empty: $file"
}

CONFIG_BLOCK=$(find "$TEST_TMP/fablo-target" -name "config-block.pb.bin" | head -n 1 || true)
SHARED_CONFIG=$(find "$TEST_TMP/fablo-target" -name "shared_config.binpb" | head -n 1 || true)
CLIENT_TLS=$(find "$TEST_TMP/fablo-target" -name "client-tls-ca.pem" | head -n 1 || true)

assert_non_empty "$CONFIG_BLOCK"
assert_non_empty "$SHARED_CONFIG"
assert_non_empty "$CLIENT_TLS"

# Container Health Checks: explicitly verify readiness messages in stdout logs
echo "Running Container Health Checks using wait-for-container.sh..."

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

# Wait for orderer nodes
waitForContainer "orderer-router" "Router network service is starting"
waitForContainer "orderer-batcher" "Batcher network service is starting"
waitForContainer "orderer-consenter" "Consensus network service is starting"
waitForContainer "orderer-assembler" "Assembler network service is starting"

# Wait for committer stack
waitForContainer "fabric-x-committer-org1-db-1" "database system is ready to accept connections"
waitForContainer "fabric-x-committer-org1-verifier-1" "Serving gRPC on"
waitForContainer "fabric-x-committer-org1-validator-1" "Serving gRPC on"
waitForContainer "fabric-x-committer-org1-coordinator-1" "Serving gRPC on"
waitForContainer "fabric-x-committer-org1-query-service-1" "Serving gRPC on"
waitForContainer "fabric-x-committer-org1-sidecar-1" "Updated dynamic TLS"

echo "All required Fabric-X containers are ready."

# Namespace & Lifecycle Regression Validation
echo "Running Namespace & Lifecycle Regression Validation..."

echo "1. Zero State"
NS_LIST=$(run_fablo namespace list 2>&1 || true)
if echo "$NS_LIST" | grep -q "mynamespace"; then
  echo "Error: Expected 0 namespaces in zero state. Found: $NS_LIST"
  exit 1
fi

echo "2. Commit State"
run_fablo namespace init

echo "3. Post-Init Query"
NS_LIST=$(run_fablo namespace list 2>&1 || true)
if ! echo "$NS_LIST" | grep -q "mynamespace"; then
  echo "Error: mynamespace not found after init. Output: $NS_LIST"
  exit 1
fi

echo "4. Idempotency"
run_fablo namespace init
NS_LIST_IDEMPOTENT=$(run_fablo namespace list 2>&1 || true)
MYNAMESPACE_COUNT=$(echo "$NS_LIST_IDEMPOTENT" | grep -c "mynamespace" || true)
if [ "$MYNAMESPACE_COUNT" -ne 1 ]; then
  echo "Error: Expected exactly 1 mynamespace after idempotent init, found $MYNAMESPACE_COUNT"
  exit 1
fi

echo "5. Cache / Up Skip"
# Verify idempotent behavior (skip generating artifacts if they already exist)
CONFIG_MTIME_BEFORE=$(stat -c %Y "$CONFIG_BLOCK")

UP_SUCCESS=false
for i in {1..3}; do
  if run_fablo up; then
    UP_SUCCESS=true
    break
  fi
  echo "fablo up failed (attempt $i). Retrying in 10s..."
  sleep 10
done

if [ "$UP_SUCCESS" = false ]; then
  echo "Error: fablo up failed after cached up attempts."
  exit 1
fi

CONFIG_MTIME_AFTER=$(stat -c %Y "$CONFIG_BLOCK")
if [ "$CONFIG_MTIME_BEFORE" != "$CONFIG_MTIME_AFTER" ]; then
  echo "Error: Artifacts were regenerated during a cached 'up' command."
  exit 1
fi

echo "6. Stop / Start"
run_fablo stop
run_fablo start
NS_LIST=$(run_fablo namespace list 2>&1 || true)
if ! echo "$NS_LIST" | grep -q "mynamespace"; then
  echo "Error: mynamespace not found after stop/start. Output: $NS_LIST"
  exit 1
fi

echo "7. Reset State"
run_fablo reset
NS_LIST_RESET=$(run_fablo namespace list 2>&1 || true)
if echo "$NS_LIST_RESET" | grep -q "mynamespace"; then
  echo "Error: mynamespace should be gone after reset."
  exit 1
fi

echo "Test passed ✅"
