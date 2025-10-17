#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."

export FABLO_HOME

networkUp() {
  "$FABLO_HOME/fablo-build.sh"
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" init node dev)
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" up)
}

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS"
  docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  (for name in $(docker ps --format '{{.Names}}'); do dumpLogs "$name"; done)
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  (cd "$TEST_TMP" && sh ../wait-for-chaincode.sh "$1" "$2" "$3" "$4") 
}

expectInvoke() {
  (cd "$TEST_TMP" && sh ../expect-invoke-cli.sh "$1" "$2" "$3" "$4" "$5" "$6")
}

expectCommand() {
  sh "$TEST_TMP/../expect-command.sh" "$1" "$2"
}

expectQuery() {
  (cd "$TEST_TMP" && sh ../expect-query-cli.sh "$1" "$2" "$3" "$4" "$5")
}

expectQueryWithRetry() {
  local output=""
  for i in {1..20}; do
    output="$(expectQuery "$1" "$2" "$3" "$4" "$5" 2>&1 || true)"
    if ! echo "$output" | grep -q 'failed (cli)'; then
      echo "$output"
      return 0
    fi
    echo "Query failed, retrying... ($i)"
    sleep 1
  done
  echo "$output"
  exit 1
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

waitForContainer "orderer0.group1.orderer.example.com" "Channel created"
waitForContainer "orderer1.group1.orderer.example.com" "Channel created"
waitForContainer "ca.org1.example.com" "Listening on https://0.0.0.0:7054"
waitForContainer "peer0.org1.example.com" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForContainer "peer1.org1.example.com" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForContainer "peer0.org1.example.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
waitForContainer "peer0.org1.example.com" "Anchor peer.*with same endpoint, skipping connecting to myself"
waitForContainer "peer0.org1.example.com" "Membership view has changed. peers went online:.*peer1.org1.example.com:7042"
waitForContainer "peer1.org1.example.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
waitForContainer "peer1.org1.example.com" "Membership view has changed. peers went online:.*peer0.org1.example.com:7041"
waitForContainer "ccaas_peer0.org1.example.com_my-channel1_chaincode1_0.0.1" "Bootstrap process completed"
waitForContainer "ccaas_peer1.org1.example.com_my-channel1_chaincode1_0.0.1" "Bootstrap process completed"

# Test simple chaincode
expectInvoke "peer0.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "Willy Wonka"]}' \
  '{\"success\":\"OK\"}'
expectQuery "peer1.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  '{"success":"Willy Wonka"}'

# Test code reload (ccaas dev mode)
expectQuery "peer1.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "unknown"]}' \
  '{"error":"NOT_FOUND"}'
perl -i -pe 's/NOT_FOUND/SORRY_NOT_FOUND/g' "$TEST_TMP/chaincodes/chaincode-kv-node/index.js"
expectQueryWithRetry "peer1.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "unknown"]}' \
  '{"error":"SORRY_NOT_FOUND"}'

# Verify channel query scripts
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" channel fetch newest my-channel1 org1 peer1)
expectCommand "cat \"$TEST_TMP/newest.block\"" "KVContract:put"

(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" channel fetch 3 my-channel1 org1 peer1 "another.block")
expectCommand "cat \"$TEST_TMP/another.block\"" "KVContract:put"

(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" channel fetch config my-channel1 org1 peer1 "channel-config.json")
expectCommand "cat \"$TEST_TMP/channel-config.json\"" "\"mod_policy\": \"Admins\","

expectCommand "(cd \"$TEST_TMP\" && \"$FABLO_HOME/fablo.sh\" channel getinfo my-channel1 org1 peer1)" "\"height\":4"

# Reset and ensure the state is lost after reset
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" reset)
waitForChaincode "peer0.org1.example.com" "my-channel1" "chaincode1" "0.0.1"
waitForChaincode "peer1.org1.example.com" "my-channel1" "chaincode1" "0.0.1"
expectQueryWithRetry "peer0.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  '{"error":"SORRY_NOT_FOUND"}'

# Put some data again
expectInvoke "peer0.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "James Bond"]}' \
  '{\"success\":\"OK\"}'

# Test export-network-topology to Mermaid
cp -f "$FABLO_HOME/samples/fablo-config-hlf2-1org-1chaincode.json" "$TEST_TMP/simple-config.json"
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" export-network-topology simple-config.json simple-network-topology.mmd)
expectCommand "head -n 1 \"$TEST_TMP/simple-network-topology.mmd\"" "graph TD"
expectCommand "cat \"$TEST_TMP/simple-network-topology.mmd\"" "Org_Orderer"
expectCommand "cat \"$TEST_TMP/simple-network-topology.mmd\"" "Org_Org1"
expectCommand "cat \"$TEST_TMP/simple-network-topology.mmd\"" "Channel_my_channel1"