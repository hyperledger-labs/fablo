#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."

export FABLO_HOME

CONFIG="$FABLO_HOME/samples/fablo-config-hlf2-1org-1chaincode-peer-dev-mode.json"
NODECHAINCODE="$FABLO_HOME/samples/chaincodes/chaincode-kv-node"

networkUp() {
  "$FABLO_HOME/fablo-build.sh"
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" up "$CONFIG")
}

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS"
  docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  sleep 2
  (for name in $(docker ps --format '{{.Names}}'); do dumpLogs "$name"; done)
  # (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  (cd "$TEST_TMP" && sh ../wait-for-chaincode.sh "$1" "$2" "$3" "$4")
}

expectInvoke() {
  (cd "$TEST_TMP" && sh ../expect-invoke-cli.sh "$1" "$2" "$3" "$4" "$5" "$6")
}

expectCommand() {
  sh "$TEST_TMP/../expect-command.sh" "$1" "$2"
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

# check if all nodes are ready
waitForContainer "orderer0.group1.orderer.example.com" "Beginning to serve requests"
waitForContainer "db.ca.org1.example.com" "database system is ready to accept connections"
waitForContainer "ca.org1.example.com" "Listening on http://0.0.0.0:7054"
waitForContainer "couchdb.peer0.org1.example.com" "Apache CouchDB has started. Time to relax."
waitForContainer "peer0.org1.example.com" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForChaincode "peer0.org1.example.com" "my-channel1" "chaincode1" "0.0.1"

echo "All nodes are ready"
echo "Starting chaincode in development mode..."
# make sure nodemon is installed and Install if not
if ! command -v nodemon &> /dev/null; then
  echo "nodemon could not be found, installing..."
  npm install -g nodemon
else
  echo "nodemon is already installed"
fi
# start the chaincode in development mode
(cd "$NODECHAINCODE" && npm i && npm run start:watch) &

sleep 5

# Test simple chaincode
expectInvoke "peer0.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "Willy Wonka"]}' \
  '{\"success\":\"OK\"}'