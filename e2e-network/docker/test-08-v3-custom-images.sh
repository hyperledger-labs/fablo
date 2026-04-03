

set -eu

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."

export FABLO_HOME

CUSTOM_ORG_PREFIX="customorg"
FABRIC_VERSION="3.1"
FABRIC_VERSION_TAG="3.1.0"

tag_mock_custom_images() {
  local hl_prefix="hyperledger"
  local components=("peer" "orderer" "ca" "tools" "ccenv" "baseos" "javaenv" "nodeenv")

  echo "Tagging standard hyperledger images as custom images..."
  for component in "${components[@]}"; do
    local img_name="fabric-$component"

  done
}

CONFIG="$FABLO_HOME/samples/fablo-config-hlf3-1org-1chaincode-custom-images.json"

pull_and_retag() {
 
  for type in peer orderer tools ccenv baseos; do
    docker pull hyperledger/fabric-$type:$FABRIC_VERSION >/dev/null 2>&1 || true
    docker tag hyperledger/fabric-$type:$FABRIC_VERSION customorg/fabric-$type:$FABRIC_VERSION_TAG >/dev/null 2>&1 || true
  done


  docker pull hyperledger/fabric-ca:1.5 >/dev/null 2>&1 || true
  docker tag hyperledger/fabric-ca:1.5 customorg/fabric-ca:1.5.0 >/dev/null 2>&1 || true
  docker tag hyperledger/fabric-ca:1.5 customorg/fabric-ca:$FABRIC_VERSION_TAG >/dev/null 2>&1 || true


  docker pull hyperledger/fabric-nodeenv:$FABRIC_VERSION >/dev/null 2>&1 || true
  docker tag hyperledger/fabric-nodeenv:$FABRIC_VERSION customorg/fabric-nodeenv:$FABRIC_VERSION_TAG >/dev/null 2>&1 || true
}

networkUp() {
  pull_and_retag
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
  rm -rf "$TEST_LOGS"
  (for name in $(docker ps --format '{{.Names}}'); do dumpLogs "$name"; done)
  dumpLogs orderer0.group1.orderer.example.com
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  (cd "$TEST_TMP" && sh ../wait-for-chaincode.sh "$1" "$2" "$3" "$4") 
}

expectInvoke() {
  (cd "$TEST_TMP" && sh ../expect-invoke-cli.sh "$1" "$2" "$3" "$4" "$5" "")
}

expectQuery() {
  (cd "$TEST_TMP" && sh ../expect-query-cli.sh "$1" "$2" "$3" "$4" "$5")
}

expectCommand() {
  sh "$TEST_TMP/../expect-command.sh" "$1" "$2"
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT


networkUp

waitForContainer "orderer0.group1.orderer.example.com" "Starting raft node as part of a new channel channel=my-channel1"
waitForContainer "ca.org1.example.com" "Listening on https://0.0.0.0:7054"
waitForContainer "peer0.org1.example.com" "Joining gossip network of channel my-channel1 with 1 organizations"
waitForContainer "peer0.org1.example.com" "Learning about the configured anchor peers of Org1MSP for channel my-channel1"


expectInvoke "peer0.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "Willy Wonka"]}' \
  '{\"success\":\"OK\"}'
expectQuery "peer0.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  '{"success":"Willy Wonka"}'

echo "🎉 Custom images CI test passed! 🎉"
