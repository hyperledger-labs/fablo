#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../.."

FABLO_CONFIG="$FABLO_HOME/samples/fablo-config-hlf1.4-2orgs-2chaincodes-private-data.yaml"

networkUp() {
  "$FABLO_HOME/fablo-build.sh"
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" up "$FABLO_CONFIG")
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
  sh "$TEST_TMP/../wait-for-chaincode-v1.4.sh" "$1" "$2" "$3" "$4" "$5"
}

expectInvoke() {
  sh "$TEST_TMP/../expect-invoke-cli.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

# check if network is ready
waitForContainer "orderer0.group1.orderer.example.com" "Created and starting new chain my-channel1"
waitForContainer "ca.org1.example.com" "Listening on http://0.0.0.0:7054"
waitForContainer "peer0.org1.example.com" "Joining gossip network of channel my-channel1 with 2 organizations"
waitForContainer "ca.org2.example.com" "Listening on http://0.0.0.0:7054"
waitForContainer "peer0.org2.example.com" "Joining gossip network of channel my-channel1 with 2 organizations"

waitForChaincode "cli.org1.example.com" "peer0.org1.example.com:7041" "my-channel1" "or-policy-chaincode" "0.0.1"
waitForChaincode "cli.org2.example.com" "peer0.org2.example.com:7061" "my-channel1" "or-policy-chaincode" "0.0.1"
waitForChaincode "cli.org1.example.com" "peer0.org1.example.com:7041" "my-channel1" "and-policy-chaincode" "0.0.1"
waitForChaincode "cli.org2.example.com" "peer0.org2.example.com:7061" "my-channel1" "and-policy-chaincode" "0.0.1"

sleep 3 # extra time needed: peers need to discover themselves before private data call.

# Org1: Test chaincode with transient fields and private data
expectInvoke "cli.org1.example.com" "peer0.org1.example.com:7041" "my-channel1" "or-policy-chaincode" \
  '{"Args":["KVContract:putPrivateMessage", "org1-collection"]}' \
  '{\"success\":\"OK\"}' \
  '{"message":"VmVyeSBzZWNyZXQgbWVzc2FnZQ=="}'
expectInvoke "cli.org1.example.com" "peer0.org1.example.com:7041" "my-channel1" "or-policy-chaincode" \
  '{"Args":["KVContract:getPrivateMessage", "org1-collection"]}' \
  '{\"success\":\"Very secret message\"}'
expectInvoke "cli.org1.example.com" "peer0.org1.example.com:7041" "my-channel1" "or-policy-chaincode" \
  '{"Args":["KVContract:verifyPrivateMessage", "org1-collection"]}' \
  '{\"success\":\"OK\"}' \
  '{"message":"VmVyeSBzZWNyZXQgbWVzc2FnZQ=="}'

# Org2: Access private data from org1-collection
expectInvoke "cli.org2.example.com" "peer0.org2.example.com:7061" "my-channel1" "or-policy-chaincode" \
  '{"Args":["KVContract:verifyPrivateMessage", "org1-collection"]}' \
  '{\"success\":\"OK\"}' \
  '{"message":"VmVyeSBzZWNyZXQgbWVzc2FnZQ=="}'
expectInvoke "cli.org2.example.com" "peer0.org2.example.com:7061" "my-channel1" "or-policy-chaincode" \
  '{"Args":["KVContract:verifyPrivateMessage", "org1-collection"]}' \
  '{\"error\":\"VERIFICATION_FAILED\"}' \
  '{"message":"XXXXXSBzZWNyZXQgbWVzc2FnZQ=="}'
expectInvoke "cli.org2.example.com" "peer0.org2.example.com:7061" "my-channel1" "or-policy-chaincode" \
  '{"Args":["KVContract:getPrivateMessage", "org1-collection"]}' \
  'tx creator does not have read access permission on privatedata in chaincodeName:or-policy-chaincode collectionName: org1-collection'

# Warning: Org2 with no read access can override private data of Org1.
expectInvoke "cli.org2.example.com" "peer0.org2.example.com:7061" "my-channel1" "or-policy-chaincode" \
  '{"Args":["KVContract:putPrivateMessage", "org1-collection"]}' \
  '{\"success\":\"OK\"}' \
  '{"message":"Q29ycnVwdGVkIG1lc3NhZ2U="}'
# Read of corrupted message will fail with MVCC_READ_CONFLICT if the Org1 has one peer in the channel, but succeed otherwise
expectInvoke "cli.org1.example.com" "peer0.org1.example.com:7041" "my-channel1" "or-policy-chaincode" \
  '{"Args":["KVContract:getPrivateMessage", "org1-collection"]}' \
  '{\"success\":\"Corrupted message\"}'

# The issue exists even for chaincodes with AND endorsement policy
expectInvoke "cli.org1.example.com" "peer0.org1.example.com:7041,peer0.org2.example.com:7061" "my-channel1" "and-policy-chaincode" \
  '{"Args":["KVContract:putPrivateMessage", "org1-collection"]}' \
  '{\"success\":\"OK\"}' \
  '{"message":"RG9udCBjaGFuZ2UgbWUgcGx6"}'
expectInvoke "cli.org2.example.com" "peer0.org2.example.com:7061,peer0.org1.example.com:7041" "my-channel1" "and-policy-chaincode" \
  '{"Args":["KVContract:getPrivateMessage", "org1-collection"]}' \
  'tx creator does not have read access permission on privatedata in chaincodeName:and-policy-chaincode collectionName: org1-collection'
expectInvoke "cli.org2.example.com" "peer0.org2.example.com:7061,peer0.org1.example.com:7041" "my-channel1" "and-policy-chaincode" \
  '{"Args":["KVContract:putPrivateMessage", "org1-collection"]}' \
  '{\"success\":\"OK\"}' \
  '{"message":"QW5kIGFub3RoZXIgb25l"}'
expectInvoke "cli.org1.example.com" "peer0.org1.example.com:7041,peer0.org2.example.com:7061" "my-channel1" "and-policy-chaincode" \
  '{"Args":["KVContract:getPrivateMessage", "org1-collection"]}' \
  'Error: could not assemble transaction: ProposalResponsePayloads do not match'
