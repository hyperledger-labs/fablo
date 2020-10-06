#!/bin/sh

TEST_TMP="$(mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
FABRIKKA_HOME="$TEST_TMP/../.."

CONFIG="$FABRIKKA_HOME/samples/fabrikkaConfig-1org-1channel-1chaincode.json"
CHAINCODE="$FABRIKKA_HOME/samples/chaincode-kv-node"

networkUpAsync() {
  (rm -rf "$TEST_TMP" &&
    mkdir -p "$TEST_TMP" &&
    sh "$FABRIKKA_HOME/docker-generate.sh" "$CONFIG" "$TEST_TMP" &&
    cd "$TEST_TMP" &&
    cp -R "$CHAINCODE" "$TEST_TMP" &&
    (sh fabrikka.sh up &))
}

networkDown() {
  (cd "$TEST_TMP" && sh fabrikka.sh down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  sh "$TEST_TMP/../wait-for-chaincode.sh" "$1" "$2"
}

networkUpAsync

waitForContainer "ca.root.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "orderer0.root.com" "Created and starting new chain my-channel1" &&
  waitForContainer "ca.org1.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "peer0.org1.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  waitForContainer "peer1.org1.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  waitForChaincode "chaincode1" "0.0.1" &&
  networkDown
