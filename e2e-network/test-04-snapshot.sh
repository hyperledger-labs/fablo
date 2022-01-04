#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../.."

CONFIG="$FABLO_HOME/samples/fablo-config-hlf2-1org-1chaincode-raft-explorer.json"

networkUp() {
  "$FABLO_HOME/fablo-build.sh"
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" up "$CONFIG")
}

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS"
  docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  sleep 2
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

expectCARest() {
  sh "$TEST_TMP/../expect-ca-rest.sh" "$1" "$2" "$3" "$4"
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

# check if all nodes are ready
waitForContainer "orderer0.group1.orderer.example.com" "Starting Raft node channel=my-channel1"
waitForContainer "db.ca.org1.example.com" "database system is ready to accept connections"
waitForContainer "ca.org1.example.com" "Listening on http://0.0.0.0:7054"
waitForContainer "couchdb.peer0.org1.example.com" "Apache CouchDB has started. Time to relax."
waitForContainer "peer0.org1.example.com" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForContainer "db.explorer.example.com" "database system is ready to accept connections" "200"
waitForContainer "explorer.example.com" "Successfully created channel event hub for \[my-channel1\]" "200"
waitForChaincode "cli.org1.example.com" "peer0.org1.example.com:7041" "my-channel1" "chaincode1" "0.0.1"

fablo_rest_org1="localhost:8801"
snapshot_name="fablo-snapshot-$(date -u +"%Y%m%d%H%M%S")"

# register and enroll test user
admin_token_response="$(expectCARest "$fablo_rest_org1/user/enroll" '' '{"id": "admin", "secret": "adminpw"}' 'token')"
echo "$admin_token_response"
admin_token="$(echo "$admin_token_response" | jq -r '.token')"

register_response="$(expectCARest "$fablo_rest_org1/user/register" "$admin_token" '{"id": "gordon", "secret": "gordonpw"}' 'ok')"
echo "$register_response"

user_token_response="$(expectCARest "$fablo_rest_org1/user/enroll" '' '{"id": "gordon", "secret": "gordonpw"}' 'token')"
echo "$user_token_response"
user_token="$(echo "$user_token_response" | jq -r '.token')"

# save some data
expectInvokeRest "$fablo_rest_org1 $user_token" "my-channel1" "chaincode1" \
  "KVContract:put" '["name", "Mr Freeze"]' \
  '{"response":{"success":"OK"}}'
expectInvokeRest "$fablo_rest_org1 $user_token" "my-channel1" "chaincode1" \
  "KVContract:putPrivateMessage" '["_implicit_org_Org1MSP"]' \
  '{"success":"OK"}' \
  '{"message":"RHIgVmljdG9yIEZyaWVz"}'

# create snapshot
(cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" snapshot "$snapshot_name")

# overwrite the data
expectInvokeRest "$fablo_rest_org1 $user_token" "my-channel1" "chaincode1" \
  "KVContract:put" '["name", "Poison Ivy"]' \
  '{"response":{"success":"OK"}}'
expectInvokeRest "$fablo_rest_org1 $user_token" "my-channel1" "chaincode1" \
  "KVContract:putPrivateMessage" '["_implicit_org_Org1MSP"]' \
  '{"success":"OK"}' \
  '{"message":"RHIgUGFtZWxhIElzbGV5"}'

# verify it is updated
expectInvokeRest "$fablo_rest_org1 $user_token" "my-channel1" "chaincode1" \
  "KVContract:get" '["name"]' \
  '{"response":{"success":"Poison Ivy"}}'
expectInvokeRest "$fablo_rest_org1 $user_token" "my-channel1" "chaincode1" \
  "KVContract:getPrivateMessage" '["_implicit_org_Org1MSP"]' \
  '{"success":"RHIgUGFtZWxhIElzbGV5"}'

# prune the network and restore from snapshot
(cd "$TEST_TMP" &&
  "$FABLO_HOME/fablo.sh" prune &&
  "$FABLO_HOME/fablo.sh" restore "$snapshot_name" &&
  "$FABLO_HOME/fablo.sh" start
)
waitForChaincode "cli.org1.example.com" "peer0.org1.example.com:7041" "my-channel1" "chaincode1" "0.0.1"

sleep 5

user_token_response="$(expectCARest "$fablo_rest_org1/user/enroll" '' '{"id": "gordon", "secret": "gordonpw"}' 'token')"
echo "$user_token_response"
user_token="$(echo "$user_token_response" | jq -r '.token')"

# check if state is kept after restoration
expectInvokeRest "$fablo_rest_org1 $user_token" "my-channel1" "chaincode1" \
  "KVContract:get" '["name"]' \
  '{"response":{"success":"Mr Freeze"}}'
expectInvokeRest "$fablo_rest_org1 $user_token" "my-channel1" "chaincode1" \
  "KVContract:getPrivateMessage" '["_implicit_org_Org1MSP"]' \
  '{"success":"RHIgVmljdG9yIEZyaWVz"}'
