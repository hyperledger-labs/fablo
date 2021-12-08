#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../.."

CONFIG="$FABLO_HOME/samples/fablo-config-hlf2-2orgs-2chaincodes-raft.yaml"

networkUp() {
  # separate generate and up is intentional just to check if it works
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
  sleep 2
  rm -rf "$TEST_LOGS"
  (for name in $(docker ps --format '{{.Names}}'); do dumpLogs "$name"; done)
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  sh "$TEST_TMP/../wait-for-chaincode-tls.sh" "$1" "$2" "$3" "$4" "$5"
}

expectInvokeRest() {
  sh "$TEST_TMP/../expect-invoke-rest.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

expectInvokeCli() {
  sh "$TEST_TMP/../expect-invoke-cli-tls.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

# check if orderers are ready
waitForContainer "orderer0.group1.orderer1.com" "Starting Raft node channel=my-channel1"
waitForContainer "orderer0.group1.orderer1.com" "Starting Raft node channel=my-channel2"
waitForContainer "orderer1.group1.orderer1.com" "Starting Raft node channel=my-channel1"
waitForContainer "orderer1.group1.orderer1.com" "Starting Raft node channel=my-channel2"
waitForContainer "orderer2.group1.orderer1.com" "Starting Raft node channel=my-channel1"
waitForContainer "orderer2.group1.orderer1.com" "Starting Raft node channel=my-channel2"

waitForContainer "orderer0.group2.orderer2.com" "Created and started new channel my-channel3"

# check if org1 is ready
waitForContainer "ca.org1.example.com" "Listening on http://0.0.0.0:7054"
waitForContainer "peer0.org1.example.com" "Joining gossip network of channel my-channel1 with 2 organizations"
waitForContainer "peer0.org1.example.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
waitForContainer "peer0.org1.example.com" "Anchor peer for channel my-channel1 with same endpoint, skipping connecting to myself"
waitForContainer "peer0.org1.example.com" "Membership view has changed. peers went online:.*peer0.org2.example.com:7081"
waitForContainer "peer1.org1.example.com" "Joining gossip network of channel my-channel2 with 2 organizations"
waitForContainer "peer1.org1.example.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel2"
waitForContainer "peer1.org1.example.com" "Membership view has changed. peers went online:.*peer1.org2.example.com:7082"

# check if org2 is ready
waitForContainer "ca.org2.example.com" "Listening on http://0.0.0.0:7054"
waitForContainer "peer0.org2.example.com" "Joining gossip network of channel my-channel1 with 2 organizations"
waitForContainer "peer0.org2.example.com" "Learning about the configured anchor peers of Org2MSP for channel my-channel1"
waitForContainer "peer0.org2.example.com" "Anchor peer for channel my-channel1 with same endpoint, skipping connecting to myself"
waitForContainer "peer0.org2.example.com" "Membership view has changed. peers went online:.*peer0.org1.example.com:7061"
waitForContainer "peer1.org2.example.com" "Joining gossip network of channel my-channel2 with 2 organizations"
waitForContainer "peer1.org2.example.com" "Learning about the configured anchor peers of Org2MSP for channel my-channel2"
waitForContainer "peer1.org2.example.com" "Anchor peer for channel my-channel2 with same endpoint, skipping connecting to myself"
waitForContainer "peer1.org2.example.com" "Membership view has changed. peers went online:.*peer1.org1.example.com:7062"

# check if chaincodes are instantiated on peers
waitForChaincode "cli.org1.example.com" "peer0.org1.example.com:7061" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "cli.org2.example.com" "peer0.org2.example.com:7081" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "cli.org1.example.com" "peer1.org1.example.com:7062" "my-channel2" "chaincode2" "0.0.1"
waitForChaincode "cli.org2.example.com" "peer1.org2.example.com:7082" "my-channel2" "chaincode2" "0.0.1"

fablo_rest_org1="localhost:8802"

# invoke Node chaincode
expectInvokeRest "$fablo_rest_org1" "my-channel1" "chaincode1" \
  "KVContract:put" '["name", "Jack Sparrow"]' \
  '{"response":{"success":"OK"}}'
expectInvokeCli "cli.org2.example.com" "peer0.org2.example.com:7081" "my-channel1" "chaincode1" "tlsca.orderer1.com-cert.pem" \
  '{"Args":["KVContract:get", "name"]}' \
  '{\"success\":\"Jack Sparrow\"}'

# invoke Java chaincode
expectInvokeRest "$fablo_rest_org1" "my-channel2" "chaincode2" \
  "PokeballContract:createPokeball" '["id1", "Pokeball 1"]' \
  '{"response":""}'
expectInvokeCli "cli.org2.example.com" "peer1.org2.example.com:7082" "my-channel2" "chaincode2" "tlsca.orderer1.com-cert.pem" \
  '{"Args":["PokeballContract:readPokeball", "id1"]}' \
  '{\"value\":\"Pokeball 1\"}'

# restart the network and wait for chaincodes
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" stop && "$FABLO_HOME/fablo.sh" start)
waitForChaincode "cli.org1.example.com" "peer0.org1.example.com:7061" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "cli.org2.example.com" "peer0.org2.example.com:7081" "my-channel1" "chaincode1" "0.0.1"

# upgrade chaincode
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" chaincode upgrade "chaincode1" "0.0.2")
waitForChaincode "cli.org1.example.com" "peer0.org1.example.com:7061" "my-channel1" "chaincode1" "0.0.2"
waitForChaincode "cli.org2.example.com" "peer0.org2.example.com:7081" "my-channel1" "chaincode1" "0.0.2"

# check if state is kept after update
expectInvokeRest "$fablo_rest_org1" "my-channel1" "chaincode1" \
  "KVContract:get" '["name"]' \
  '{"response":{"success":"Jack Sparrow"}}'
