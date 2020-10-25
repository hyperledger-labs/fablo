#!/bin/bash

TEST_TMP="$(mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABRIKKA_HOME="$TEST_TMP/../.."

CONFIG="$FABRIKKA_HOME/samples/fabrikkaConfig-2orgs-2channels-1chaincode-tls-raft.json"

networkUpAsync() {
  (cd "$TEST_TMP" && "$FABRIKKA_HOME/fabrikka.sh" generate "$CONFIG") &&
    (cd "$TEST_TMP" && "$FABRIKKA_HOME/fabrikka.sh" up &)
}

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS" &&
    docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  rm -rf "$TEST_LOGS" &&
    dumpLogs "ca.root.com" &&
    dumpLogs "orderer0.root.com" &&
    dumpLogs "orderer1.root.com" &&
    dumpLogs "orderer2.root.com" &&
    dumpLogs "ca.org1.com" &&
    dumpLogs "peer0.org1.com" &&
    dumpLogs "peer1.org1.com" &&
    dumpLogs "ca.org2.com" &&
    dumpLogs "peer0.org2.com" &&
    dumpLogs "peer1.org2.com" &&
    dumpLogs "cli.org1.com" &&
    dumpLogs "cli.org2.com" &&
    (cd "$TEST_TMP" && "$FABRIKKA_HOME/fabrikka.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  sh "$TEST_TMP/../wait-for-chaincode.sh" "$1" "$2" "$3" "$4" "$5"
}

expectInvoke() {
  sh "$TEST_TMP/../expect-invoke-tls.sh" "$1" "$2" "$3" "$4" "$5" "$6"
}

networkUpAsync

waitForContainer "ca.root.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "orderer0.root.com" "Starting Raft node channel=my-channel1" &&
  waitForContainer "orderer0.root.com" "Starting Raft node channel=my-channel2" &&
  waitForContainer "orderer1.root.com" "Starting Raft node channel=my-channel1" &&
  waitForContainer "orderer1.root.com" "Starting Raft node channel=my-channel2" &&
  waitForContainer "orderer2.root.com" "Starting Raft node channel=my-channel1" &&
  waitForContainer "orderer2.root.com" "Starting Raft node channel=my-channel2" &&
  waitForContainer "ca.org1.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "peer0.org1.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  waitForContainer "peer1.org1.com" "Elected as a leader, starting delivery service for channel my-channel2" &&
  waitForContainer "ca.org2.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "peer0.org2.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  waitForContainer "peer1.org2.com" "Elected as a leader, starting delivery service for channel my-channel2" &&
  waitForChaincode "cli.org1.com" "peer1.org1.com" "my-channel2" "chaincode1" "0.0.1" &&
  waitForChaincode "cli.org2.com" "peer1.org2.com" "my-channel2" "chaincode1" "0.0.1" &&
  expectInvoke "cli.org1.com" "peer1.org1.com" "my-channel2" "chaincode1" \
    '{"Args":["KVContract:put", "name", "Jack Sparrow"]}' \
    '{\"success\":\"OK\"}' &&
  expectInvoke "cli.org2.com" "peer1.org2.com" "my-channel2" "chaincode1" \
    '{"Args":["KVContract:get", "name"]}' \
    '{\"success\":\"Jack Sparrow\"}' &&
  (cd "$TEST_TMP" && "$FABRIKKA_HOME/fabrikka.sh" chaincodes upgrade "chaincode1" "0.0.2") &&
  waitForChaincode "cli.org1.com" "peer1.org1.com" "my-channel2" "chaincode1" "0.0.2" &&
  waitForChaincode "cli.org2.com" "peer1.org2.com" "my-channel2" "chaincode1" "0.0.2" &&
  expectInvoke "cli.org1.com" "peer1.org1.com" "my-channel2" "chaincode1" \
    '{"Args":["KVContract:get", "name"]}' \
    '{\"success\":\"Jack Sparrow\"}' &&
  networkDown || (networkDown && exit 1)
