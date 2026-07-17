#!/usr/bin/env bash

set -euo pipefail

FABLO_NETWORK_ROOT="$(cd "$(dirname "$0")" && pwd)"
FABRICOPS_MANIFEST="$FABLO_NETWORK_ROOT/fabric-k8s/fabricnetwork.yaml"
FABRICNETWORK_NAME="<%= fabricNetworkName %>"
NAMESPACE="${NAMESPACE:-default}"
FABRICOPS_NAMESPACE="${FABRICOPS_NAMESPACE:-fabricops-system}"
FABRICOPS_WAIT_TIMEOUT="${FABRICOPS_WAIT_TIMEOUT:-20m}"
FABRICOPS_OPERATION_TIMEOUT="${FABRICOPS_OPERATION_TIMEOUT:-180s}"
FABRICOPS_INSTALL_URL="https://github.com/dpereowei/FabricOps#installation"

KUBECTL_ARGS=()
FABRICOPSCTL_ARGS=()
if [ -n "${FABLO_KUBECONFIG:-}" ]; then
  KUBECTL_ARGS+=(--kubeconfig "$FABLO_KUBECONFIG")
  FABRICOPSCTL_ARGS+=(--kubeconfig "$FABLO_KUBECONFIG")
fi
if [ -n "${FABLO_KUBECONTEXT:-}" ]; then
  KUBECTL_ARGS+=(--context "$FABLO_KUBECONTEXT")
  FABRICOPSCTL_ARGS+=(--context "$FABLO_KUBECONTEXT")
fi

printHelp() {
  echo "usage: ./fabric-k8s.sh <command>"
  echo ""
  echo "Commands:"
  echo "  up       Apply the generated FabricOps FabricNetwork and wait until it is ready"
  echo "  start    Re-apply the generated FabricOps FabricNetwork and wait until it is ready"
  echo "  down     Delete the generated FabricOps FabricNetwork"
  echo "  reset    Delete, then re-apply the generated FabricOps FabricNetwork"
  echo "  status   Show the generated FabricOps FabricNetwork status"
  echo "  chaincode invoke <peers> <channel> <chaincode> <payload> [transient]"
  echo "           Invoke chaincode through FabricOps/fabricopsctl"
  echo "  chaincode query <peer> <channel> <chaincode> <payload> [transient]"
  echo "           Query chaincode through FabricOps/fabricopsctl"
  echo "  help     Print this help"
  echo ""
  echo "Environment:"
  echo "  FABLO_KUBECONTEXT       Kubeconfig context to target. Defaults to the current kubectl context."
  echo "  FABLO_KUBECONFIG        Kubeconfig path. Defaults to kubectl/fabricopsctl defaults."
  echo "  NAMESPACE               FabricNetwork namespace. Defaults to default."
  echo "  FABRICOPS_NAMESPACE     FabricOps controller namespace. Defaults to fabricops-system."
  echo "  FABRICOPS_WAIT_TIMEOUT  Readiness wait timeout. Defaults to 20m."
  echo "  FABRICOPS_OPERATION_TIMEOUT  Chaincode operation timeout. Defaults to 180s."
}

kubectlCmd() {
  kubectl "${KUBECTL_ARGS[@]}" "$@"
}

fabricopsctlCmd() {
  local command="$1"
  shift
  fabricopsctl "$command" "${FABRICOPSCTL_ARGS[@]}" "$@"
}

requireFabricOpsctl() {
  if ! command -v fabricopsctl >/dev/null 2>&1; then
    echo "Error: fabricopsctl is required for Fablo Kubernetes chaincode operations"
    echo "Install it with: go install github.com/dpereowei/fabricops/cmd/fabricopsctl@latest"
    echo 'If go install succeeds but fabricopsctl is still not found, add Go binaries to PATH:'
    echo '  export PATH="$(go env GOPATH)/bin:$PATH"'
    echo "Then rerun the command."
    exit 1
  fi
}

chaincodeSubmitterOrg() {
  local first_peer="${1%%,*}"
  case "$first_peer" in
    <% orgs.forEach((org) => { -%>
      <% org.peers.forEach((peer) => { -%>
        "<%= peer.address %>") echo "<%= org.name %>"; return 0 ;;
      <% }) -%>
    <% }) -%>
    *)
      echo "Unknown peer: $first_peer" >&2
      return 1
      ;;
  esac
}

chaincodePeerRef() {
  local peer_domain="$1"
  case "$peer_domain" in
    <% orgs.forEach((org) => { -%>
      <% org.peers.forEach((peer) => { -%>
        "<%= peer.address %>") echo "<%= org.name %>/<%= peer.name %>"; return 0 ;;
      <% }) -%>
    <% }) -%>
    *)
      echo "Unknown peer: $peer_domain" >&2
      return 1
      ;;
  esac
}

fabricNetworkPhase() {
  kubectlCmd get \
    -n "$NAMESPACE" \
    "fabricnetworks.fabricops.io/$FABRICNETWORK_NAME" \
    -o jsonpath='{.status.phase}' 2>/dev/null || true
}

fabricNetworkGeneration() {
  kubectlCmd get \
    -n "$NAMESPACE" \
    "fabricnetworks.fabricops.io/$FABRICNETWORK_NAME" \
    -o jsonpath='{.metadata.generation}' 2>/dev/null || true
}

fabricNetworkReadyCondition() {
  kubectlCmd get \
    -n "$NAMESPACE" \
    "fabricnetworks.fabricops.io/$FABRICNETWORK_NAME" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true
}

fabricNetworkReadyObservedGeneration() {
  kubectlCmd get \
    -n "$NAMESPACE" \
    "fabricnetworks.fabricops.io/$FABRICNETWORK_NAME" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].observedGeneration}' 2>/dev/null || true
}

fabricNetworkMessage() {
  kubectlCmd get \
    -n "$NAMESPACE" \
    "fabricnetworks.fabricops.io/$FABRICNETWORK_NAME" \
    -o jsonpath='{.status.message}' 2>/dev/null || true
}

fabricOpsWaitTimeoutSeconds() {
  local value="$FABRICOPS_WAIT_TIMEOUT"

  if [[ "$value" =~ ^([0-9]+)s$ ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi

  if [[ "$value" =~ ^([0-9]+)m$ ]]; then
    echo "$((BASH_REMATCH[1] * 60))"
    return
  fi

  if [[ "$value" =~ ^([0-9]+)h$ ]]; then
    echo "$((BASH_REMATCH[1] * 3600))"
    return
  fi

  echo ""
}

printFabricNetworkDiagnostics() {
  local message
  message="$(fabricNetworkMessage)"

  if [ -n "$message" ]; then
    echo "FabricNetwork status message:"
    echo "  $message"
  fi

  echo "FabricNetwork details:"
  kubectlCmd get -n "$NAMESPACE" "fabricnetworks.fabricops.io/$FABRICNETWORK_NAME" -o wide || true

  echo "Recent FabricNetwork events:"
  kubectlCmd get events \
    -n "$NAMESPACE" \
    --field-selector "involvedObject.kind=FabricNetwork,involvedObject.name=$FABRICNETWORK_NAME" \
    --sort-by=.lastTimestamp || true
}

targetContext() {
  if [ -n "${FABLO_KUBECONTEXT:-}" ]; then
    echo "$FABLO_KUBECONTEXT"
  else
    kubectlCmd config current-context 2>/dev/null || echo "<unset>"
  fi
}

printTarget() {
  echo "FabricOps target:"
  echo "  context: $(targetContext)"
  if [ -n "${FABLO_KUBECONFIG:-}" ]; then
    echo "  kubeconfig: $FABLO_KUBECONFIG"
  fi
  echo "  namespace: $NAMESPACE"
  echo "  operator namespace: $FABRICOPS_NAMESPACE"
  echo "  FabricNetwork: $FABRICNETWORK_NAME"
  echo "  manifest: $FABRICOPS_MANIFEST"
}

printInstallInstructions() {
  echo "Install FabricOps first, then rerun this command."
  echo "FabricOps installation instructions: $FABRICOPS_INSTALL_URL"
}

requireKubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl is required to apply a FabricOps network"
    exit 1
  fi
}

verifyClusterAccess() {
  if ! kubectlCmd cluster-info >/dev/null 2>&1; then
    echo "Error: could not reach the Kubernetes cluster for context '$(targetContext)'"
    exit 1
  fi
}

verifyFabricOps() {
  requireKubectl

  if [ ! -f "$FABRICOPS_MANIFEST" ]; then
    echo "Error: FabricOps manifest not found: $FABRICOPS_MANIFEST"
    exit 1
  fi

  verifyClusterAccess

  if ! kubectlCmd get crd fabricnetworks.fabricops.io >/dev/null 2>&1; then
    echo "Error: FabricOps CRD 'fabricnetworks.fabricops.io' is not installed in this cluster"
    printInstallInstructions
    exit 1
  fi

  if ! kubectlCmd get namespace "$FABRICOPS_NAMESPACE" >/dev/null 2>&1; then
    echo "Error: FabricOps controller namespace '$FABRICOPS_NAMESPACE' was not found"
    printInstallInstructions
    exit 1
  fi

  if ! kubectlCmd get deployment \
    -n "$FABRICOPS_NAMESPACE" \
    -l app.kubernetes.io/name=fabricops,control-plane=controller-manager \
    -o name | grep -q .; then
    echo "Error: FabricOps controller manager Deployment was not found in namespace '$FABRICOPS_NAMESPACE'"
    printInstallInstructions
    exit 1
  fi

  if ! kubectlCmd wait \
    -n "$FABRICOPS_NAMESPACE" \
    --for=condition=Available \
    --timeout=5s \
    deployment \
    -l app.kubernetes.io/name=fabricops,control-plane=controller-manager; then
    echo "Error: FabricOps controller manager is installed but not Available in namespace '$FABRICOPS_NAMESPACE'"
    echo "Check it with: kubectl -n $FABRICOPS_NAMESPACE get deployment -l app.kubernetes.io/name=fabricops,control-plane=controller-manager"
    exit 1
  fi

  kubectlCmd get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectlCmd create namespace "$NAMESPACE"
}

waitForFabricNetwork() {
  echo "Waiting for FabricNetwork '$FABRICNETWORK_NAME' to become Ready..."

  local timeout_seconds
  timeout_seconds="$(fabricOpsWaitTimeoutSeconds)"

  if [ -z "$timeout_seconds" ]; then
    if kubectlCmd wait \
      -n "$NAMESPACE" \
      --for=condition=Ready \
      --timeout="$FABRICOPS_WAIT_TIMEOUT" \
      "fabricnetworks.fabricops.io/$FABRICNETWORK_NAME"; then
      return
    fi

    printFabricNetworkDiagnostics
    exit 1
  fi

  local deadline=$((SECONDS + timeout_seconds))

  while [ "$SECONDS" -lt "$deadline" ]; do
    local generation
    local observed_generation
    local phase
    local ready_condition
    generation="$(fabricNetworkGeneration)"
    observed_generation="$(fabricNetworkReadyObservedGeneration)"
    phase="$(fabricNetworkPhase)"
    ready_condition="$(fabricNetworkReadyCondition)"

    if [ -z "$generation" ] || [ "$observed_generation" != "$generation" ]; then
      sleep 5
      continue
    fi

    if [ "$phase" = "Ready" ] || [ "$ready_condition" = "True" ]; then
      echo "FabricNetwork '$FABRICNETWORK_NAME' is Ready."
      return
    fi

    if [ "$phase" = "Failed" ]; then
      echo "Error: FabricNetwork '$FABRICNETWORK_NAME' failed to reconcile."
      printFabricNetworkDiagnostics
      exit 1
    fi

    sleep 5
  done

  echo "Error: timed out waiting for FabricNetwork '$FABRICNETWORK_NAME' to become Ready."
  printFabricNetworkDiagnostics
  exit 1
}

networkUp() {
  printTarget
  verifyFabricOps
  kubectlCmd apply -n "$NAMESPACE" -f "$FABRICOPS_MANIFEST"
  waitForFabricNetwork
}

networkDown() {
  printTarget
  requireKubectl
  verifyClusterAccess
  if ! kubectlCmd get crd fabricnetworks.fabricops.io >/dev/null 2>&1; then
    echo "FabricOps CRD 'fabricnetworks.fabricops.io' is not installed. Nothing to delete."
    return 0
  fi
  if ! kubectlCmd get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "Namespace '$NAMESPACE' does not exist. Nothing to delete."
    return 0
  fi
  kubectlCmd delete -n "$NAMESPACE" -f "$FABRICOPS_MANIFEST" --ignore-not-found=true
}

networkStatus() {
  printTarget
  requireKubectl
  verifyClusterAccess
  if command -v fabricopsctl >/dev/null 2>&1; then
    fabricopsctlCmd status -n "$NAMESPACE" "$FABRICNETWORK_NAME"
  else
    kubectlCmd get -n "$NAMESPACE" "fabricnetworks.fabricops.io/$FABRICNETWORK_NAME" -o wide
  fi
}

chaincodeInvoke() {
  if [ "$#" -ne 4 ] && [ "$#" -ne 5 ]; then
    echo "Expected 4 or 5 parameters for chaincode invoke, but got: $*"
    echo "Usage: fablo chaincode invoke <peer_domains_comma_separated> <channel_name> <chaincode_name> <payload> [transient]"
    exit 1
  fi

  requireFabricOpsctl

  local peers="$1"
  local channel="$2"
  local chaincode="$3"
  local payload="$4"
  local transient="${5:-}"
  local submitter_org
  submitter_org="$(chaincodeSubmitterOrg "$peers")"

  local args=(
    invoke
    -n "$NAMESPACE"
    --timeout "$FABRICOPS_OPERATION_TIMEOUT"
    --org "$submitter_org"
    --channel "$channel"
    --chaincode "$chaincode"
    --payload "$payload"
  )

  if [ -n "$transient" ]; then
    args+=(--transient "$transient")
  fi

  local peer_domain
  local peer_ref
  IFS=',' read -r -a peer_domains <<< "$peers"
  for peer_domain in "${peer_domains[@]}"; do
    peer_ref="$(chaincodePeerRef "$peer_domain")"
    args+=(--peer "$peer_ref")
  done

  fabricopsctlCmd "${args[@]}" "$FABRICNETWORK_NAME"
}

chaincodeQuery() {
  if [ "$#" -ne 4 ] && [ "$#" -ne 5 ]; then
    echo "Expected 4 or 5 parameters for chaincode query, but got: $*"
    echo "Usage: fablo chaincode query <peer_domain> <channel_name> <chaincode_name> <payload> [transient]"
    exit 1
  fi

  requireFabricOpsctl

  local peer="$1"
  local channel="$2"
  local chaincode="$3"
  local payload="$4"
  local transient="${5:-}"
  local submitter_org
  local peer_ref
  submitter_org="$(chaincodeSubmitterOrg "$peer")"
  peer_ref="$(chaincodePeerRef "$peer")"

  local args=(
    query
    -n "$NAMESPACE"
    --timeout "$FABRICOPS_OPERATION_TIMEOUT"
    --org "$submitter_org"
    --peer "$peer_ref"
    --channel "$channel"
    --chaincode "$chaincode"
    --payload "$payload"
  )

  if [ -n "$transient" ]; then
    args+=(--transient "$transient")
  fi

  fabricopsctlCmd "${args[@]}" "$FABRICNETWORK_NAME"
}

case "${1:-}" in
  up|start)
    networkUp
    ;;
  down)
    networkDown
    ;;
  reset)
    networkDown
    networkUp
    ;;
  status)
    networkStatus
    ;;
  chaincode)
    case "${2:-}" in
      invoke)
        chaincodeInvoke "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}"
        ;;
      query)
        chaincodeQuery "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}"
        ;;
      *)
        echo "Unsupported Kubernetes chaincode command: ${2:-<unset>}"
        echo "Supported commands are: chaincode invoke, chaincode query"
        exit 1
        ;;
    esac
    ;;
  help|--help|-h)
    printHelp
    ;;
  *)
    echo "No command specified"
    printHelp
    exit 1
    ;;
esac
