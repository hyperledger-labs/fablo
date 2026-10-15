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
ENDORSER_PID=""
networkDown() {
   [ -n "$ENDORSER_PID" ] && kill "$ENDORSER_PID" 2>/dev/null || true
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
  "$FABLO_HOME/fablo-build.sh"
  run_fablo init fabric-x
  jq '.namespaces += [{"name": "audit_ns", "orgs": ["Org1"]}]' "$TEST_TMP/fablo-config.json" >"$TEST_TMP/fablo-config.json.tmp"
  mv "$TEST_TMP/fablo-config.json.tmp" "$TEST_TMP/fablo-config.json"
  run_fablo validate
  run_fablo up
}

trap networkDown EXIT
trap 'trap - EXIT ; networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

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


# namespace zero state
expectNotCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "mynamespace"

# init namespace
run_fablo namespace init

# post-init query
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "mynamespace"
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list)" "audit_ns"
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace list | grep -cE '^[0-9]+\) .+: version')" "2"
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace init does_not_exist 2>&1 || echo \"EXIT:\$?\")" "Namespace 'does_not_exist' not found"
expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" namespace init does_not_exist 2>&1 || echo \"EXIT:\$?\")" "EXIT:"
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
# uses the custom-endorser from fabric-x-samples (needs Go and git on the host)
SAMPLES_REF="e97194ea7e56f126efccebf2bd163de903652660"
SAMPLES_DIR="$TEST_TMP/fabric-x-samples"
CRYPTO="$TEST_TMP/fablo-target/fabric-x/crypto"
ORG="$CRYPTO/peerOrganizations/org1.example.com"
ORG_TLS_CA="$ORG/msp/tlscacerts/tlsca.org1.example.com-cert.pem"
ORDERER_TLS_CA="$CRYPTO/ordererOrganizations/orderer.example.com/msp/tlscacerts/tlsca.orderer.example.com-cert.pem"
CLIENT_TLS="$ORG/peers/fxconfig.org1.example.com/tls"
USER_MSP="$ORG/users/User1@org1.example.com/msp"

mkdir -p "$SAMPLES_DIR"
(cd "$SAMPLES_DIR" && git init -q && git fetch -q --depth 1 https://github.com/hyperledger/fabric-x-samples.git "$SAMPLES_REF" && git checkout -q FETCH_HEAD)
(cd "$SAMPLES_DIR/custom-endorser" && make build)
APP_BIN="$SAMPLES_DIR/custom-endorser/bin"

cat >"$TEST_TMP/endorser.yaml" <<EOF
channel-id: mychannel
protocol: fabric-x
database:
  connection-string: file:endorser.sqlite?mode=memory&cache=shared
server:
  endpoint: { host: localhost, port: 9001 }
  tls: { mode: none }
identity:
  msp-id: Org1MSP
  msp-dir: $USER_MSP
committer:
  endpoint: { host: localhost, port: 4001 }
  tls:
    mode: mtls
    cert-path: $CLIENT_TLS/server.crt
    key-path: $CLIENT_TLS/server.key
    ca-cert-paths: [ "$ORG_TLS_CA" ]
logging:
  logSpec: info
EOF

cat >"$TEST_TMP/client.yaml" <<EOF
channel-id: mychannel
namespace: mynamespace
protocol: fabric-x
identity:
  msp-id: Org1MSP
  msp-dir: $USER_MSP
endorsers:
  - endpoint: { host: localhost, port: 9001 }
    tls: { mode: none }
orderer:
  endpoint: { host: localhost, port: 7050 }
  tls:
    mode: mtls
    cert-path: $CLIENT_TLS/server.crt
    key-path: $CLIENT_TLS/server.key
    ca-cert-paths: [ "$ORDERER_TLS_CA", "$ORG_TLS_CA" ]
EOF

"$APP_BIN/endorser" -c "$TEST_TMP/endorser.yaml" >"$TEST_LOGS/endorser.log" 2>&1 &
ENDORSER_PID=$!

APP_QUERY="\"$APP_BIN/client\" -c \"$TEST_TMP/client.yaml\" query '{\"Args\":[\"get\",\"fixture-key\"]}'"

# the endorser accepts connections only after it has synced with the sidecar
for _ in $(seq 1 60); do
  eval "$APP_QUERY" >/dev/null 2>&1 && break
  sleep 1
done

"$APP_BIN/client" -c "$TEST_TMP/client.yaml" invoke '{"Args":["set","fixture-key","fixture-value"]}'

# invoke does not wait for commit, so poll the state for a bounded time
for _ in $(seq 1 30); do
  eval "$APP_QUERY" 2>&1 | grep -q "fixture-value" && break
  sleep 1
done
expectCommand "$APP_QUERY" "fixture-value"

kill "$ENDORSER_PID" 2>/dev/null || true
ENDORSER_PID=""
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