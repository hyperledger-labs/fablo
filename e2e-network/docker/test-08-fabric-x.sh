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
  (for name in $(docker ps -a --format '{{.Names}}'); do dumpLogs "$name"; done)
  run_fablo down
}

waitForHealthy() {
  local container="$1"
  local max_attempts="${2:-90}"
  
  for i in $(seq 1 "$max_attempts"); do
    echo "➜ verifying if container $container is healthy ($i)..."
    local status
    status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$container" 2>/dev/null || echo "not_found")
    
    if [ "$status" = "healthy" ]; then
      echo "✅ ok: Container $container is healthy!"
      return 0
    fi
    sleep 1
  done

  echo "❌ failed: Container $container did not become healthy within timeout."
  docker logs "$container" | tail -n 30
  exit 1
}

expectCommand() {
  sh "$TEST_TMP/../expect-command.sh" "$1" "$2"
}

expectNotCommand() {
  local command="$1"
  local expected="$2"
  echo ""
  echo "➜ testing not contains: $command"
  local response
  response="$(eval "$command" 2>&1)"
  echo "$response"
  if echo "$response" | grep -a -E "$expected"; then
    echo "❌ failed (cli): $command | expected not to contain: $expected"
    exit 1
  else
    echo "✅ ok (cli - not found): $command"
  fi
}

networkUp() {
  "$FABLO_HOME/fablo-build.sh"
  run_fablo init fabric-x
  run_fablo validate

  run_fablo up
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

# verify artifacts
CONFIG_BLOCK="$TEST_TMP/fablo-target/fabric-x/crypto/config-block.pb.bin"
SHARED_CONFIG="$TEST_TMP/fablo-target/fabric-x/crypto/shared_config.binpb"
CLIENT_TLS="$TEST_TMP/fablo-target/fabric-x/crypto/client-tls-ca.pem"

if [ ! -s "$CONFIG_BLOCK" ] || [ ! -s "$SHARED_CONFIG" ] || [ ! -s "$CLIENT_TLS" ]; then
  echo "Error: Artifact missing or empty"
  exit 1
fi

# check if ready
waitForHealthy "orderer-router"
waitForHealthy "orderer-batcher"
waitForHealthy "orderer-consenter"
waitForHealthy "orderer-assembler"
waitForHealthy "fabric-x-committer-org1-db-1"
waitForHealthy "fabric-x-committer-org1-verifier-1"
waitForHealthy "fabric-x-committer-org1-validator-1"
waitForHealthy "fabric-x-committer-org1-coordinator-1"
waitForHealthy "fabric-x-committer-org1-query-service-1"
waitForHealthy "fabric-x-committer-org1-sidecar-1"

# namespace zero state
expectNotCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "mynamespace"

# init namespace
run_fablo namespace init

# post-init query
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "mynamespace"

# idempotency
run_fablo namespace init
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list | grep -c \"mynamespace\")" "1"

# cache skip check
CONFIG_HASH_BEFORE=$(sha256sum "$CONFIG_BLOCK" | awk '{print $1}')
run_fablo up
CONFIG_HASH_AFTER=$(sha256sum "$CONFIG_BLOCK" | awk '{print $1}')
if [ "$CONFIG_HASH_BEFORE" != "$CONFIG_HASH_AFTER" ]; then
  echo "Error: Artifacts were regenerated during a cached 'up' command."
  exit 1
fi

# stop start persistence
run_fablo stop
run_fablo start
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "mynamespace"

# reset state
run_fablo reset
expectNotCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "mynamespace"

echo "Test passed ✅"
