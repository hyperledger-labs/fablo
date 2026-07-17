#!/usr/bin/env bash

set -e

TEST_TMP="$(rm -rf "$0.tmpdir" && mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABLO_HOME="$TEST_TMP/../../.."
FABLO_K8S_CONFIG="$FABLO_HOME/samples/fablo-config-hlf2-1org-1chaincode-k8s.json"

export FABLO_HOME
if command -v go >/dev/null 2>&1; then
  export PATH="$(go env GOPATH)/bin:$PATH"
fi

cleanup_done=false

networkUp() {
  "$FABLO_HOME/fablo-build.sh"
  (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" up "$FABLO_K8S_CONFIG")
}

dumpLogs() {
  mkdir -p "$TEST_LOGS"

  kubectl get fabricnetworks.fabricops.io -A -o yaml >"$TEST_LOGS/fabricnetworks.yaml" 2>&1 || true
  kubectl get pods,jobs,deployments,svc -A -o wide >"$TEST_LOGS/k8s-resources.txt" 2>&1 || true
  kubectl get events -A --sort-by=.lastTimestamp >"$TEST_LOGS/k8s-events.txt" 2>&1 || true

  while read -r namespace pod; do
    [ -n "$namespace" ] || continue
    echo "Saving logs of $namespace/$pod to $TEST_LOGS/$namespace-$pod.log"
    kubectl logs -n "$namespace" "$pod" --all-containers=true >"$TEST_LOGS/$namespace-$pod.log" 2>&1 || true
  done < <(kubectl get pods -A --no-headers -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name' 2>/dev/null || true)
}

networkDown() {
  if [ "$cleanup_done" = "true" ]; then
    return
  fi
  cleanup_done=true

  dumpLogs

  if [ -d "$TEST_TMP/fablo-target" ]; then
    (cd "$TEST_TMP" && "$FABLO_HOME/fablo.sh" down) || true
  fi
}

expectInvoke() {
  (cd "$TEST_TMP" && ../expect-invoke-cli.sh "$1" "$2" "$3" "$4" "$5" "${6:-}")
}

expectQuery() {
  (cd "$TEST_TMP" && ../expect-query-cli.sh "$1" "$2" "$3" "$4" "$5" "${6:-}")
}

trap networkDown EXIT
trap 'networkDown ; echo "Test failed" ; exit 1' ERR SIGINT

networkUp

fabricopsctl wait -n default --timeout 20m fablo-network

# Test simple chaincode through both peers, one after the other.
expectInvoke "peer0.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "Willy Wonka"]}' \
  'Chaincode invoke successful'
expectQuery "peer1.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  'Willy Wonka'

expectInvoke "peer1.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:put", "name", "Charlie Bucket"]}' \
  'Chaincode invoke successful'
expectQuery "peer0.org1.example.com" "my-channel1" "chaincode1" \
  '{"Args":["KVContract:get", "name"]}' \
  'Charlie Bucket'

echo "Test passed ✅"
