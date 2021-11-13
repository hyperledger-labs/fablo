#!/usr/bin/env bash

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABRICA_HOME="$TEST_TMP/../.."

networkUpAsync() {
  "$FABRICA_HOME/fabrica-build.sh" &&
    (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" init) &&
    (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" up &)
}

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS" &&
    docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  rm -rf "$TEST_TEST_LOGS" &&
    dumpLogs "ca.root.com" &&
    dumpLogs "orderer0.root.com" &&
    dumpLogs "ca.org1.com" &&
    dumpLogs "peer0.org1.com" &&
    dumpLogs "peer1.org1.com" &&
    dumpLogs "cli.org1.com" &&
    (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  sh "$TEST_TMP/../wait-for-chaincode.sh" "$1" "$2" "$3" "$4" "$5"
}

expectInvoke() {
  sh "$TEST_TMP/../expect-invoke.sh" "$1" "$2" "$3" "$4" "$5" "$6"
}

networkUpAsync

# shellcheck disable=2015
waitForContainer "ca.root.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "orderer0.root.com" "Created and starting new.*my-channel1" &&
  waitForContainer "ca.org1.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "peer0.org1.com" "Joining gossip network of channel my-channel1 with 1 organizations" &&
  waitForContainer "peer1.org1.com" "Joining gossip network of channel my-channel1 with 1 organizations" &&

  waitForContainer "peer0.org1.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1" &&
  waitForContainer "peer0.org1.com" "Anchor peer for channel my-channel1 with same endpoint, skipping connecting to myself" &&
  waitForContainer "peer0.org1.com" "Membership view has changed. peers went online:.*peer1.org1.com:7061" &&
  waitForContainer "peer1.org1.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1" &&
  waitForContainer "peer1.org1.com" "Membership view has changed. peers went online:.*peer0.org1.com:7060" &&

  waitForChaincode "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" "0.0.1" &&
  waitForChaincode "cli.org1.com" "peer1.org1.com:7061" "my-channel1" "chaincode1" "0.0.1" &&

  expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:put", "name", "Willy Wonka"]}' \
    '{\"success\":\"OK\"}' &&
  expectInvoke "cli.org1.com" "peer1.org1.com:7061" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:get", "name"]}' \
    '{\"success\":\"Willy Wonka\"}' &&

  (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" reboot) &&
  waitForChaincode "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" "0.0.1" &&
  waitForChaincode "cli.org1.com" "peer1.org1.com:7061" "my-channel1" "chaincode1" "0.0.1" &&

  expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:get", "name"]}' \
    '{\"error\":\"NOT_FOUND\"}' &&
  expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:put", "name", "James Bond"]}' \
    '{\"success\":\"OK\"}' &&

  (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" chaincode upgrade "chaincode1" "0.0.2") &&
  waitForChaincode "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" "0.0.2" &&
  waitForChaincode "cli.org1.com" "peer1.org1.com:7061" "my-channel1" "chaincode1" "0.0.2" &&

  expectInvoke "cli.org1.com" "peer1.org1.com:7061" "my-channel1" "chaincode1" \
    '{"Args":["KVContract:get", "name"]}' \
    '{\"success\":\"James Bond\"}' &&

  networkDown || (networkDown && exit 1)
