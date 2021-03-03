#!/usr/bin/env bash

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABRICA_HOME="$TEST_TMP/../.."

# testing absolute path
CONFIG="$FABRICA_HOME/samples/fabricaConfig-2orgs-2channels-1chaincode-tls-raft-private-data.json"

networkUpAsync() {
  "$FABRICA_HOME/fabrica-build.sh" &&
    (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" generate "$CONFIG") &&
    (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" up &)
}

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS" &&
    docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  rm -rf "$TEST_LOGS" &&
    (for name in $(docker ps --format '{{.Names}}') ; do dumpLogs "$name"; done) &&
    (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  sh "$TEST_TMP/../wait-for-chaincode.sh" "$1" "$2" "$3" "$4" "$5"
}

expectInvoke() {
  sh "$TEST_TMP/../expect-invoke-tls.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

networkUpAsync

# shellcheck disable=2015
waitForContainer "ca.root.com" "Listening on http://0.0.0.0:7054" &&
#  waitForContainer "orderer0.root.com" "Starting Raft node channel=my-channel1" &&
#  waitForContainer "orderer0.root.com" "Starting Raft node channel=my-channel2" &&
#  waitForContainer "orderer1.root.com" "Starting Raft node channel=my-channel1" &&
#  waitForContainer "orderer1.root.com" "Starting Raft node channel=my-channel2" &&
#  waitForContainer "orderer2.root.com" "Starting Raft node channel=my-channel1" &&
#  waitForContainer "orderer2.root.com" "Starting Raft node channel=my-channel2" &&

  waitForContainer "ca.org1.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "peer0.org1.com" "Joining gossip network of channel my-channel1 with 2 organizations" &&
  waitForContainer "ca.org2.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "peer0.org2.com" "Joining gossip network of channel my-channel1 with 2 organizations" &&

  waitForChaincode "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" "0.0.1" &&
  waitForChaincode "cli.org2.com" "peer0.org2.com:7070" "my-channel1" "chaincode1" "0.0.1" &&

  # Test Node chaincode
  expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:put", "name", "Jack Sparrow"]}' \
    '{\"success\":\"OK\"}' &&
  expectInvoke "cli.org2.com" "peer0.org2.com:7070" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:get", "name"]}' \
    '{\"success\":\"Jack Sparrow\"}' &&

  # Verify if private data works
  expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:putPrivateMessage", "privateDataOrg1"]}' \
    '{\"success\":\"OK\"}' \
    '{"message":"VmVyeSBzZWNyZXQgbWVzc2FnZQo="}' &&
  expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:verifyPrivateMessage", "privateDataOrg1"]}' \
    '{\"success\":\"OK\"}' \
    '{"message":"VmVyeSBzZWNyZXQgbWVzc2FnZQo="}' &&

  # Put private data by unpriviledged org
  expectInvoke "cli.org2.com" "peer0.org2.com:7070" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:putPrivateMessage", "privateDataOrg1"]}' \
    '{\"success\":\"OK\"}' \
    '{"message":"Tm90IHNvIHNlY3JldCBtZXNzYWdl"}' &&

  # Update to prove that the data was actually changed (should fail)
  expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:verifyPrivateMessage", "privateDataOrg1"]}' \
    '{\"success\":\"OK\"}' \
    '{"message":"Tm90IHNvIHNlY3JldCBtZXNzYWdl"}' &&

  # The invoke below fails but should pass
  expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:verifyPrivateMessage", "privateDataOrg1"]}' \
    '{\"success\":\"OK\"}' \
    '{"message":"VmVyeSBzZWNyZXQgbWVzc2FnZQo="}' &&

  networkDown || (networkDown && exit 1)
