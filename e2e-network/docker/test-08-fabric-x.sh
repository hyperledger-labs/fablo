#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."
export FABLO_HOME

CONFIG="$FABLO_HOME/samples/fablo-config-fabric-x-2orgs.json"

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
  run_fablo validate "$CONFIG"
  run_fablo generate "$CONFIG"
  run_fablo up "$CONFIG"
}

trap networkDown EXIT
trap 'trap - EXIT ; networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

# verify artifacts
CONFIG_BLOCK="$TEST_TMP/fablo-target/fabric-x/crypto/config-block.pb.bin"
SHARED_CONFIG="$TEST_TMP/fablo-target/fabric-x/crypto/shared_config.binpb"
CLIENT_TLS="$TEST_TMP/fablo-target/fabric-x/crypto/client-tls-ca.pem"
FXCONFIG_ORG1="$TEST_TMP/fablo-target/fabric-x/fxconfig-org1.yaml"
FXCONFIG_ORG2="$TEST_TMP/fablo-target/fabric-x/fxconfig-org2.yaml"

if [ ! -s "$CONFIG_BLOCK" ] || [ ! -s "$SHARED_CONFIG" ] || [ ! -s "$CLIENT_TLS" ] || [ ! -s "$FXCONFIG_ORG1" ] || [ ! -s "$FXCONFIG_ORG2" ]; then
  echo "Error: Artifact missing or empty"
  exit 1
fi


# namespace zero state
expectNotCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "mynamespace"

# init namespace
run_fablo namespace init

# post-init query
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "mynamespace"
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "audit_ns"
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list Org1)" "mynamespace"
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list Org2)" "mynamespace"
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list | grep -cE '^[0-9]+\) .+: version')" "2"
# targeted init: creating an already-existing namespace by name should still succeed (idempotent)
run_fablo namespace init mynamespace
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list | grep -c \"mynamespace\")" "1"

# targeted init with an unknown name should fail, not hang or silently succeed
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace init does_not_exist 2>&1 || echo \"EXIT:\$?\")" "Namespace 'does_not_exist' not found"
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace init does_not_exist 2>&1 || echo \"EXIT:\$?\")" "EXIT:"

# idempotency
run_fablo namespace init
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list | grep -c \"mynamespace\")" "1"

# application transaction: submit to the namespace, wait for commit, query the state
FX_APP_DIR="$FABLO_HOME/samples/chaincodes/fabric-x-app"
FX_APP_LOG="$TEST_LOGS/fabric-x-app.log"
FX_CRYPTO="$TEST_TMP/fablo-target/fabric-x/crypto"
FXCONFIG="$FXCONFIG_ORG1"

fxconfig_value() {
  awk -v section="$1:" -v key="$2:" '
    /^[a-zA-Z]/ { in_section = ($1 == section) }
    in_section && $1 == key { print $2; exit }
  ' "$FXCONFIG"
}

FX_ORG_DOMAIN="$(jq -r '.orgs[0].organization.domain' "$CONFIG")"
FX_NAMESPACE="$(jq -r '.namespaces[] | select(.orgs == ["Org1"]) | .name' "$CONFIG" | head -n 1)"
FX_MSP_NAME="$(jq -r '.orgs[0].organization.mspName' "$CONFIG")"
FX_CHANNEL="$(jq -r '.channels[0].name' "$CONFIG")"
FX_ORDERER="$(fxconfig_value orderer address)"
FX_SIDECAR="$(fxconfig_value notifications address)"
for fx_value in FX_ORG_DOMAIN FX_NAMESPACE FX_MSP_NAME FX_CHANNEL FX_ORDERER FX_SIDECAR; do
  if [ -z "${!fx_value}" ] || [ "${!fx_value}" = "null" ]; then
    echo "❌ failed: could not read $fx_value from the config of the network"
    exit 1
  fi
done
mkdir -p "$FX_APP_DIR/.cache"

echo "Running the Fabric-X application fixture, output in $FX_APP_LOG"
docker run --rm --network fabric-x --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e GOCACHE=/cache/build \
  -e GOMODCACHE=/cache/mod \
  -e GOFLAGS=-buildvcs=false \
  -v "$FX_APP_DIR:/src:Z" \
  -v "$FX_APP_DIR/.cache:/cache:Z" \
  -v "$FX_CRYPTO/peerOrganizations/$FX_ORG_DOMAIN/peers/fxconfig.$FX_ORG_DOMAIN/tls:/tls:ro,Z" \
  -v "$FX_CRYPTO/peerOrganizations/$FX_ORG_DOMAIN/users/User1@$FX_ORG_DOMAIN/msp:/msp:ro,Z" \
  -v "$FX_CRYPTO/peerOrganizations/$FX_ORG_DOMAIN/msp/tlscacerts/tlsca.$FX_ORG_DOMAIN-cert.pem:/org-tls-ca.pem:ro,Z" \
  -v "$FX_CRYPTO/ordererOrganizations:/orderer-cas:ro,Z" \
  -w /src \
  golang:1.27.3 \
  go run . \
  -channel "$FX_CHANNEL" \
  -namespace "$FX_NAMESPACE" \
  -msp-name "$FX_MSP_NAME" \
  -orderer "$FX_ORDERER" \
  -sidecar "$FX_SIDECAR" \
  >"$FX_APP_LOG" 2>&1 || {
  echo "❌ failed: Fabric-X application fixture exited with a non-zero code"
  cat "$FX_APP_LOG"
  exit 1
}
expectCommand "cat \"$FX_APP_LOG\"" "FABRIC_X_APP_OK namespace=$FX_NAMESPACE key=fixture-key value=fixture-value"

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
