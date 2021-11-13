#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../.."

networkUp() {
  "$FABLO_HOME/fablo-build.sh"
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" init node)
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
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  sh "$TEST_TMP/../wait-for-chaincode.sh" "$1" "$2" "$3" "$4" "$5"
}

expectInvoke() {
  sh "$TEST_TMP/../expect-invoke-cli.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

waitForContainer "orderer0.group1.orderer.com" "Created and started new.*my-channel1"
waitForContainer "ca.org1.com" "Listening on http://0.0.0.0:7054"
waitForContainer "peer0.org1.com" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForContainer "peer1.org1.com" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForContainer "peer0.org1.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
waitForContainer "peer0.org1.com" "Anchor peer.*with same endpoint, skipping connecting to myself"
waitForContainer "peer0.org1.com" "Membership view has changed. peers went online:.*peer1.org1.com:7072"
waitForContainer "peer1.org1.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
waitForContainer "peer1.org1.com" "Membership view has changed. peers went online:.*peer0.org1.com:7071"

# Test simple chaincode
expectInvoke "cli.org1.com" "peer0.org1.com:7071" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "Willy Wonka"]}' \
  '{\"success\":\"OK\"}'
expectInvoke "cli.org1.com" "peer1.org1.com:7072" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  '{\"success\":\"Willy Wonka\"}'

# Reboot and ensure the state is lost after reboot
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" reboot)
waitForChaincode "cli.org1.com" "peer0.org1.com:7071" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "cli.org1.com" "peer1.org1.com:7072" "my-channel1" "chaincode1" "0.0.1"
expectInvoke "cli.org1.com" "peer0.org1.com:7071" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  '{\"error\":\"NOT_FOUND\"}'

# Put some data again
expectInvoke "cli.org1.com" "peer0.org1.com:7071" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "James Bond"]}' \
  '{\"success\":\"OK\"}'
