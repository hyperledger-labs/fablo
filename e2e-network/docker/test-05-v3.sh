#!/usr/bin/env bash

set -eu

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."

export FABLO_HOME

CONFIG="$FABLO_HOME/samples/fablo-config-hlf3-1orgs-1chaincode.json"

networkUp() {
  "$FABLO_HOME/fablo-build.sh"
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" generate "$CONFIG")
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" up)
}

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS"
  docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  rm -rf "$TEST_LOGS"
  (for name in $(docker ps --format '{{.Names}}'); do dumpLogs "$name"; done)
  dumpLogs orderer0.group1.orderer.example.com
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  (cd "$TEST_TMP" && sh ../wait-for-chaincode.sh "$1" "$2" "$3" "$4") 
}

expectInvoke() {
  (cd "$TEST_TMP" && sh ../expect-invoke-cli.sh "$1" "$2" "$3" "$4" "$5" "")
}

expectQuery() {
  (cd "$TEST_TMP" && sh ../expect-query-cli.sh "$1" "$2" "$3" "$4" "$5")
}

expectCommand() {
  sh "$TEST_TMP/../expect-command.sh" "$1" "$2"
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

waitForContainer "orderer0.group1.orderer.example.com" "Starting raft node as part of a new channel channel=my-channel1"
waitForContainer "ca.org1.example.com" "Listening on https://0.0.0.0:7054"
waitForContainer "peer0.org1.example.com" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForContainer "peer1.org1.example.com" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForContainer "peer0.org1.example.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
waitForContainer "peer0.org1.example.com" "Anchor peer.*with same endpoint, skipping connecting to myself"
waitForContainer "peer0.org1.example.com" "Membership view has changed. peers went online:.*peer1.org1.example.com:7042"
waitForContainer "peer1.org1.example.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
waitForContainer "peer1.org1.example.com" "Membership view has changed. peers went online:.*peer0.org1.example.com:7041"

# Gateway client test
GATEWAY_CLIENT_DIR="$FABLO_HOME/samples/gateway/node"
GATEWAY_CLIENT_OUTPUT_FILE="$TEST_LOGS/gateway_client.log"
echo "Testing Node.js Gateway client..."

echo "Installing gateway client dependencies..."
(cd "$GATEWAY_CLIENT_DIR" && npm install --silent --no-progress)

echo "Running Node.js Gateway client and checking output..."
(
  cd "$GATEWAY_CLIENT_DIR" &&
    export \
      CHANNEL_NAME="my-channel1" \
      CONTRACT_NAME="chaincode1" \
      MSP_ID="Org1MSP" \
      PEER_ORG_NAME="peer0.org1.example.com" \
      PEER_GATEWAY_URL="localhost:7041" \
      TLS_ROOT_CERT="$TEST_TMP/fablo-target/fabric-config/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
      CREDENTIALS="$TEST_TMP/fablo-target/fabric-config/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts/User1@org1.example.com-cert.pem" \
      PRIVATE_KEY_PEM="$TEST_TMP/fablo-target/fabric-config/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore/priv-key.pem" &&
  node server.js > "$GATEWAY_CLIENT_OUTPUT_FILE" 2>&1
)
GATEWAY_EXIT_CODE=$?

if [ $GATEWAY_EXIT_CODE -ne 0 ]; then
  echo "❌ failed: Node.js Gateway client script failed with exit code $GATEWAY_EXIT_CODE."
  cat "$GATEWAY_CLIENT_OUTPUT_FILE"
  exit 1
fi

expectCommand "cat \"$GATEWAY_CLIENT_OUTPUT_FILE\"" "\"success\":\"OK\""

echo "🎉 Node.js Gateway client test complete 🎉"


# Test simple chaincode
expectInvoke "peer0.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "Willy Wonka"]}' \
  '{\"success\":\"OK\"}'
expectQuery "peer1.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  '{"success":"Willy Wonka"}'

# Verify channel query scripts
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" channel fetch newest my-channel1 org1 peer1)
expectCommand "cat \"$TEST_TMP/newest.block\"" "KVContract:put"

(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" channel fetch 3 my-channel1 org1 peer1 "another.block")
expectCommand "cat \"$TEST_TMP/another.block\"" "KVContract:put"

(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" channel fetch config my-channel1 org1 peer1 "channel-config.json")
expectCommand "cat \"$TEST_TMP/channel-config.json\"" "\"mod_policy\": \"Admins\","

expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" channel getinfo my-channel1 org1 peer1)" "\"height\":4"

echo "🎉 Test passed! 🎉"