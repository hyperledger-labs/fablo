#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."

export FABLO_HOME

CONFIG="$FABLO_HOME/samples/fablo-config-hlf2-2orgs-2chaincodes-raft.yaml"

expectCommand() {
  sh "$TEST_TMP/../expect-command.sh" "$1" "$2"
}

networkUp() {
  # separate generate and up is intentional just to check if it works
  "$FABLO_HOME/fablo-build.sh"
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" generate "$CONFIG")


  # Check if the hook was executed (MaxMessageCount should be 1)
  expectCommand "cat \"$TEST_TMP/fablo-target/fabric-config/configtx.yaml\"" "MaxMessageCount: 1$"

  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" up)
  
  local container_logs
  container_logs=$(find "$TEST_TMP/fablo-target" -name 'container-list-*.log' | head -1)
  if [ -z "$container_logs" ]; then
    echo "Error: Container list log file not found in fablo-target directory"
    exit 1
  fi
  
  echo "Found container list log at: $container_logs"

  local expected_containers=(
    "peer0.org1.example.com"
    "peer0.org2.example.com"
    "orderer"
    "ca.org1.example.com"
    "ca.org2.example.com"
  )
  
  for container in "${expected_containers[@]}"; do
    if ! grep -q "$container" "$container_logs"; then
      echo "Error: Expected container '$container' not found in container list"
      echo "Container list content:"
      cat "$container_logs"
      exit 1
    fi
    echo "✓ Found container: $container"
  done
  
  echo "✅ All expected containers found in the log"
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
  (cd "$TEST_TMP" && sh ../wait-for-chaincode.sh "$1" "$2" "$3" "$4") 
}

expectInvokeRest() {
  sh "$TEST_TMP/../expect-invoke-rest.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

expectInvokeCli() {
  (cd "$TEST_TMP" && sh ../expect-invoke-cli.sh "$1" "$2" "$3" "$4" "$5" "$6")
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

waitForContainer "orderer0.group1.orderer1.com" "Created and started new channel my-channel1"
waitForContainer "orderer0.group1.orderer1.com" "Created and started new channel my-channel2"
waitForContainer "orderer0.group2.orderer2.com" "Created and started new channel my-channel3"

# check if org1 is ready
waitForContainer "ca.org1.example.com" "Listening on https://0.0.0.0:7054"
waitForContainer "peer0.org1.example.com" "Joining gossip network of channel my-channel1 with 2 organizations"
waitForContainer "peer0.org1.example.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
waitForContainer "peer0.org1.example.com" "Anchor peer for channel my-channel1 with same endpoint, skipping connecting to myself"
waitForContainer "peer0.org1.example.com" "Membership view has changed. peers went online:.*peer0.org2.example.com:7081"
waitForContainer "peer1.org1.example.com" "Joining gossip network of channel my-channel2 with 2 organizations"
waitForContainer "peer1.org1.example.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel2"
waitForContainer "peer1.org1.example.com" "Membership view has changed. peers went online:.*peer1.org2.example.com:7082"
waitForContainer "db.explorer.example.com" "database system is ready to accept connections" "200"
# // the next check is not working because explorer needs needs to be restarted first
# // see the issue: https://github.com/hyperledger-labs/fablo/issues/604
waitForContainer "explorer.example.com" "Successfully created channel event hub for \[my-channel1\]" "200"

# check if org2 is ready
waitForContainer "ca.org2.example.com" "Listening on https://0.0.0.0:7054"
waitForContainer "peer0.org2.example.com" "Joining gossip network of channel my-channel1 with 2 organizations"
waitForContainer "peer0.org2.example.com" "Learning about the configured anchor peers of Org2MSP for channel my-channel1"
waitForContainer "peer0.org2.example.com" "Anchor peer for channel my-channel1 with same endpoint, skipping connecting to myself"
waitForContainer "peer0.org2.example.com" "Membership view has changed. peers went online:.*peer0.org1.example.com:7061"
waitForContainer "peer1.org2.example.com" "Joining gossip network of channel my-channel2 with 2 organizations"
waitForContainer "peer1.org2.example.com" "Learning about the configured anchor peers of Org2MSP for channel my-channel2"
waitForContainer "peer1.org2.example.com" "Anchor peer for channel my-channel2 with same endpoint, skipping connecting to myself"
waitForContainer "peer1.org2.example.com" "Membership view has changed. peers went online:.*peer1.org1.example.com:7062"

# check if chaincodes are instantiated on peers
waitForChaincode "peer0.org1.example.com" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "peer0.org2.example.com" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "peer0.org1.example.com" "my-channel3" "chaincode2" "0.0.1"
waitForChaincode "peer1.org2.example.com" "my-channel3" "chaincode2" "0.0.1"

fablo_rest_org1="localhost:8802"

# invoke Node chaincode
expectInvokeRest "$fablo_rest_org1" "my-channel1" "chaincode1" \
  "KVContract:put" '["name", "Jack Sparrow"]' \
  '{"response":{"success":"OK"}}'
expectInvokeCli "peer0.org2.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  '{\"success\":\"Jack Sparrow\"}'

# invoke Java chaincode
expectInvokeRest "$fablo_rest_org1" "my-channel3" "chaincode2" \
  "PokeballContract:createPokeball" '["id1", "Pokeball 1"]' \
  '{"response":""}'
expectInvokeCli "peer1.org2.example.com" "my-channel3" "chaincode2" \
  '{"Args":["PokeballContract:readPokeball", "id1"]}' \
  '{\"value\":\"Pokeball 1\"}'

# restart the network and wait for chaincodes
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" stop && "$FABLO_HOME/fablo.sh" start)
waitForChaincode "peer0.org1.example.com" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "peer0.org2.example.com" "my-channel1" "chaincode1" "0.0.1"
waitForContainer "explorer.example.com" "Successfully created channel event hub for \[my-channel1\]" "200"

# upgrade chaincode
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" chaincode upgrade "chaincode1" "0.0.2")
waitForChaincode "peer0.org1.example.com" "my-channel1" "chaincode1" "0.0.2"
waitForChaincode "peer0.org2.example.com" "my-channel1" "chaincode1" "0.0.2"

# check if state is kept after update
expectInvokeRest "$fablo_rest_org1" "my-channel1" "chaincode1" \
  "KVContract:get" '["name"]' \
  '{"response":{"success":"Jack Sparrow"}}'
