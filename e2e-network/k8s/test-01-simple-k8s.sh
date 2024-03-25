#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."

networkUp() {
  "$FABLO_HOME/fablo-build.sh"
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" init kubernetes node)
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" up)
}

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS"
  docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  (cd "$TEST_TMP" && "$(find . -type f -iname 'fabric-k8s.sh')" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  sh "$TEST_TMP/../wait-for-chaincode.sh" "$1" "$2" "$3" "$4" "$5"
}

expectInvoke() {
  sh "$TEST_TMP/../expect-invoke-cli.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

# start the network
networkUp

ca_orderer="$(kubectl get pods | grep ca-orderer | tr -s ' ' | cut -d ':' -f 1 | cut -d ' ' -f 1)"
ca_org1="$(kubectl get pods | grep ca-org1 | tr -s ' ' | cut -d ':' -f 1 | cut -d ' ' -f 1)"
waitForContainer "$ca_orderer" "Listening on https://0.0.0.0:7054"
waitForContainer "$ca_org1" "Listening on https://0.0.0.0:7054"

peer0="$(kubectl get pods | grep peer0 | tr -s ' ' | cut -d ':' -f 1 | cut -d ' ' -f 1)"
peer1="$(kubectl get pods | grep peer1 | tr -s ' ' | cut -d ':' -f 1 | cut -d ' ' -f 1)"
orderer="$(kubectl get pods | grep orderer0 | tr -s ' ' | cut -d ':' -f 1 | cut -d ' ' -f 1)"

waitForContainer "$orderer" "Beginning to serve requests"
waitForContainer "$peer0" "grpc.peer_subject=\"CN=peer,OU=peer\" grpc.code=OK"
waitForContainer "$peer1" "grpc.peer_subject=\"CN=peer,OU=peer\" grpc.code=OK"
#waitForContainer "$orderer" "Starting raft node as part of a new channel channel=my-channel1 node=1"
waitForContainer "$peer0" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForContainer "$peer1" "Joining gossip network of channel my-channel1 with 1 organizations"
#waitForContainer "$peer0" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"
#waitForContainer "$peer1" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"


#Test simple chaincode
#expectInvoke "admin" "peer1.default" "my-channel1" "chaincode1" \
# "put" "[\"name\"]" "Willy Wonka" "{\"success\":\"OK\"}"
#expectInvoke "admin" "peer1.default" "my-channel1" "chaincode1" \
# "get" "[\"name\"]" "" '{"success":"Willy Wonka"}'


# Reset and ensure the state is lost after reset
#(cd "$TEST_TMP" && "$(find . -type f -iname 'fabric-k8s.sh')" reset)
#waitForChaincode "admin" "peer0.default" "my-channel1" "chaincode1" "1.0"
#waitForChaincode "admin" "peer1.default" "my-channel1" "chaincode1" "1.0"
#
#expectInvoke "admin" "peer1.default" "my-channel1" "chaincode1" \
#  "get" "[\"name\"]" "" '{"error":"NOT_FOUND"}'
#
## Put some data again
#expectInvoke "admin" "peer1.default" "my-channel1" "chaincode1" \
#  "put" "[\"name\"]" "James Bond" "{\"success\":\"OK\"}"
