#!/bin/sh

TEST_TMP="$0.tmpdir"
FABRIKKA_HOME="$TEST_TMP/../../"
mkdir -p "$TEST_TMP"

CONFIG="$FABRIKKA_HOME/samples/fabrikkaConfig-2orgs-2channels-1chaincode-tls-raft.json"

networkUpAsync() {
  (sh "$FABRIKKA_HOME/docker-generate.sh" "$CONFIG" "$TEST_TMP" &&
    cd "$TEST_TMP" &&
    (sh fabric-compose.sh up &))
}

networkDown() {
  (cd "$TEST_TMP" && sh fabric-compose.sh down)
}

waitFor() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

networkUpAsync

waitFor "ca.root.com" "Listening on http://0.0.0.0:7054" &&
  waitFor "orderer0.root.com" "Starting Raft node channel=my-channel1" &&
  waitFor "orderer0.root.com" "Starting Raft node channel=my-channel2" &&
  waitFor "orderer1.root.com" "Starting Raft node channel=my-channel1" &&
  waitFor "orderer1.root.com" "Starting Raft node channel=my-channel2" &&
  waitFor "orderer2.root.com" "Starting Raft node channel=my-channel1" &&
  waitFor "orderer2.root.com" "Starting Raft node channel=my-channel2" &&
  waitFor "ca.org1.com" "Listening on http://0.0.0.0:7054" &&
  waitFor "peer0.org1.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  waitFor "peer1.org1.com" "Elected as a leader, starting delivery service for channel my-channel2" &&
  waitFor "ca.org2.com" "Listening on http://0.0.0.0:7054" &&
  waitFor "peer0.org2.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  waitFor "peer1.org2.com" "Elected as a leader, starting delivery service for channel my-channel2" &&
  networkDown
