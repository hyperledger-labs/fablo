#!/bin/sh

TEST_TMP="$0.tmpdir"
FABRIKKA_HOME="$TEST_TMP/../../"

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
  exit 1
  #  (cd "$TEST_TMP" && sh fabrikka.sh down)
}

waitFor() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

networkUpAsync

waitFor "ca.root.com" "Listening on http://0.0.0.0:7054" &&
  waitFor "orderer0.root.com" "Created and starting new chain my-channel1" &&
  waitFor "ca.org1.com" "Listening on http://0.0.0.0:7054" &&
  waitFor "peer0.org1.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  waitFor "peer1.org1.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  networkDown
