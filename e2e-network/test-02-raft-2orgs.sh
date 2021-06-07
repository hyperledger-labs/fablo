#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABRICA_HOME="$TEST_TMP/../.."

CONFIG="$FABRICA_HOME/samples/fabrica-config-hlf2-2orgs-raft.yaml"

networkUp() {
  # separate generate and up is intentional
  "$FABRICA_HOME/fabrica-build.sh"
  (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" generate "$CONFIG")
  (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" up)
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
  (cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  sh "$TEST_TMP/../wait-for-chaincode-tls.sh" "$1" "$2" "$3" "$4" "$5"
}

expectInvoke() {
  sh "$TEST_TMP/../expect-invoke-tls.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

# check if root org is ready
waitForContainer "ca.root.com" "Listening on http://0.0.0.0:7054"
waitForContainer "orderer0.root.com" "Starting Raft node channel=my-channel1"
waitForContainer "orderer0.root.com" "Starting Raft node channel=my-channel2"
waitForContainer "orderer1.root.com" "Starting Raft node channel=my-channel1"
waitForContainer "orderer1.root.com" "Starting Raft node channel=my-channel2"
waitForContainer "orderer2.root.com" "Starting Raft node channel=my-channel1"
waitForContainer "orderer2.root.com" "Starting Raft node channel=my-channel2"

# check if org1 is ready
waitForContainer "ca.org1.com" "Listening on http://0.0.0.0:7054"
waitForContainer "peer0.org1.com" "Joining gossip network of channel my-channel1 with 2 organizations"
waitForContainer "peer0.org1.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
waitForContainer "peer0.org1.com" "Anchor peer for channel my-channel1 with same endpoint, skipping connecting to myself"
waitForContainer "peer0.org1.com" "Membership view has changed. peers went online:.*peer0.org2.com:7070"
waitForContainer "peer1.org1.com" "Joining gossip network of channel my-channel2 with 2 organizations"
waitForContainer "peer1.org1.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel2"
waitForContainer "peer1.org1.com" "Membership view has changed. peers went online:.*peer1.org2.com:7071"

# check if org2 is ready
waitForContainer "ca.org2.com" "Listening on http://0.0.0.0:7054"
waitForContainer "peer0.org2.com" "Joining gossip network of channel my-channel1 with 2 organizations"
waitForContainer "peer0.org2.com" "Learning about the configured anchor peers of Org2MSP for channel my-channel1"
waitForContainer "peer0.org2.com" "Anchor peer for channel my-channel1 with same endpoint, skipping connecting to myself"
waitForContainer "peer0.org2.com" "Membership view has changed. peers went online:.*peer0.org1.com:7060"
waitForContainer "peer1.org2.com" "Joining gossip network of channel my-channel2 with 2 organizations"
waitForContainer "peer1.org2.com" "Learning about the configured anchor peers of Org2MSP for channel my-channel2"
waitForContainer "peer1.org2.com" "Anchor peer for channel my-channel2 with same endpoint, skipping connecting to myself"
waitForContainer "peer1.org2.com" "Membership view has changed. peers went online:.*peer1.org1.com:7061"

# check if chaincodes are instantiated on peers
waitForChaincode "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "cli.org2.com" "peer0.org2.com:7070" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "cli.org1.com" "peer1.org1.com:7061" "my-channel2" "chaincode2" "0.0.1"
waitForChaincode "cli.org2.com" "peer1.org2.com:7071" "my-channel2" "chaincode2" "0.0.1"

# invoke Node chaincode
expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "Jack Sparrow"]}' \
  '{\"success\":\"OK\"}'
expectInvoke "cli.org2.com" "peer0.org2.com:7070" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  '{\"success\":\"Jack Sparrow\"}'

# invoke Java chaincode
expectInvoke "cli.org1.com" "peer1.org1.com:7061" "my-channel2" "chaincode2" \
  '{"Args":["PokeballContract:createPokeball", "id1", "Pokeball 1"]}' \
  'status:200'
expectInvoke "cli.org2.com" "peer1.org2.com:7071" "my-channel2" "chaincode2" \
  '{"Args":["PokeballContract:readPokeball", "id1"]}' \
  '{\"value\":\"Pokeball 1\"}'

# restart the network and wait for chaincodes
(cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" stop && "$FABRICA_HOME/fabrica.sh" start)
waitForChaincode "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "cli.org2.com" "peer0.org2.com:7070" "my-channel1" "chaincode1" "0.0.1"

# upgrade chaincode
(cd "$TEST_TMP" && "$FABRICA_HOME/fabrica.sh" chaincode upgrade "chaincode1" "0.0.2")
waitForChaincode "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" "0.0.2"
waitForChaincode "cli.org2.com" "peer0.org2.com:7070" "my-channel1" "chaincode1" "0.0.2"

# check if state is kept after update
expectInvoke "cli.org1.com" "peer0.org1.com:7060" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  '{\"success\":\"Jack Sparrow\"}'
