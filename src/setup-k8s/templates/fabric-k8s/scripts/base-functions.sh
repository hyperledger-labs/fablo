#!/usr/bin/env bash

source "$FABLO_NETWORK_ROOT/fabric-k8s/scripts/util.sh"

deployCA() {
  local CA_HOST="$1"
  local MSPID="$2"
  local CA_NAME="$(echo "$CA_HOST" | sed 's/\./-/g')"

  inputLog "Deploying $CA_ID ($CA_IMAGE:$CA_VERSION)"
  kubectl hlf ca create \
    --image="$CA_IMAGE" \
    --version="$CA_VERSION" \
    --storage-class="$STORAGE_CLASS" \
    --capacity=2Gi \
    --name="$CA_NAME" \
    --hosts="$CA_NAME.localho.st" \
    --enroll-id=enroll \
    --enroll-pw=enrollpw
}

registerPeerUser() {
  local CA_HOST="$1"
  local MSPID="$2"
  local CA_NAME="$(echo "$CA_HOST" | sed 's/\./-/g')"

  inputLog "Registering peer user $PEER_USER on $CA_HOST"
  kubectl hlf ca register \
    --name="$CA_NAME" \
    --user=peer \
    --secret=peerpw \
    --type=peer \
    --enroll-id=enroll \
    --enroll-secret=enrollpw \
    --mspid="$MSPID"
}

deployPeer() {
  local PEER_HOST="$1"
  local CA_HOST="$2"
  local MSPID="$3"
  local PEER_NAME="$(echo "$PEER_HOST" | sed 's/\./-/g')"
  local CA_NAME="$(echo "$CA_HOST" | sed 's/\./-/g')"

  inputLog "Deploying $PEER_HOST ($PEER_IMAGE:$PEER_VERSION)"
  # TODO: make --statedb configurable
  kubectl hlf peer create \
    --statedb=leveldb \
    --image="$PEER_IMAGE" \
    --version="$PEER_VERSION" \
    --storage-class="$STORAGE_CLASS" \
    --capacity=5Gi \
    --enroll-id=peer \
    --enroll-pw=peerpw \
    --name="$PEER_NAME" \
    --hosts="$PEER_NAME.localho.st" \
    --ca-name="$CA_NAME.$NAMESPACE" \
    --mspid="$MSPID"
}

registerOrdererUser() {
  local CA_HOST="$1"
  local MSPID="$2"
  local CA_NAME="$(echo "$CA_HOST" | sed 's/\./-/g')"

  inputLog "Registering orderer user $ORDERER_USER on $CA_HOST"
  kubectl hlf ca register \
    --name="$CA_NAME" \
    --user=orderer \
    --secret=ordererpw \
    --type=orderer \
    --enroll-id=enroll \
    --enroll-secret=enrollpw \
    --mspid="$MSPID"
}

deployOrderer() {
  local ORDERER_HOST="$1"
  local CA_HOST="$2"
  local MSPID="$3"
  local CA_NAME="$(echo "$CA_HOST" | sed 's/\./-/g')"
  local ORDERER_NAME="$(echo "$ORDERER_HOST" | sed 's/\./-/g')"

  inputLog "Deploying $ORDERER_HOST ($ORDERER_IMAGE:$ORDERER_VERSION)"
  kubectl hlf ordnode create \
    --image="$ORDERER_IMAGE" \
    --version="$ORDERER_VERSION" \
    --storage-class="$STORAGE_CLASS" \
    --capacity=2Gi \
    --enroll-id=orderer \
    --enroll-pw=ordererpw \
    --name="$ORDERER_NAME" \
    --hosts="$ORDERER_NAME.localho.st" \
    --ca-name="$CA_NAME.$NAMESPACE" \
    --mspid="$MSPID"
}

startNetwork() {
  printHeadline "Starting network" "U1F680"

  <% orgs.forEach((org) => { -%>
    deployCA "<%= org.ca.address %>" "<%= org.mspName %>"
  <% }) -%>
  kubectl wait --timeout=60s --for=condition=Running fabriccas.hlf.kungfusoftware.es --all

  <% orgs.forEach((org) => { -%>
    <% if(org.ordererGroups.length > 0 ) { -%>
      registerOrdererUser "<%= org.ca.address %>" "<%= org.mspName %>"
      <% org.ordererGroups.forEach((group) => { -%>
        <% group.orderers.forEach((orderer) => { -%>
          deployOrderer "<%= orderer.address %>" "<%= org.ca.address %>" "<%= org.mspName %>"
        <% }) -%>
      <% }) -%>
    <% } -%>
  <% }) -%>
  kubectl wait --timeout=180s --for=condition=Running fabricorderernodes.hlf.kungfusoftware.es --all

  <% orgs.forEach((org) => { -%>
    <% if(org.peers.length > 0 ) { -%>
      registerPeerUser "<%= org.ca.address %>" "<%= org.mspName %>"
      <% org.peers.forEach((peer) => { -%>
        deployPeer "<%= peer.address %>" "<%= org.ca.address %>" "<%= org.mspName %>"
      <% }) -%>
    <% } -%>
  <% }) -%>
  kubectl wait --timeout=180s --for=condition=Running fabricpeers.hlf.kungfusoftware.es --all
}

installChannels() {

  <% channels.forEach((channel) => { -%>
    <% channel.orgs.forEach((org) => { -%>
       printItalics "Creating '<%= channel.name %>' on /peer0" "U1F63B"
        sleep 10
        kubectl hlf channel generate --output="$CONFIG_DIR/<%= channel.name %>.block" --name=<%= channel.name %> --organizations <%= org.mspName %> --ordererOrganizations <%= channel.ordererHead.orgMspName %> &&

        kubectl hlf ca enroll --name=<%= channel.ordererHead.orgName.toLowerCase() %>-<%= org.ca.prefix %> --namespace="$NAMESPACE" --user="$<%= org.ca.caAdminNameVar %>" --secret="$<%= org.ca.caAdminPassVar %>" --mspid <%= channel.ordererHead.orgMspName %> --ca-name=tlsca --output "$CONFIG_DIR/admin-tls-ordservice.yaml" &&

        sleep 10

        kubectl hlf ordnode join --block="$CONFIG_DIR/<%= channel.name %>.block" --name=<%= channel.ordererHead.orgName.toLowerCase() %>-node --namespace="$NAMESPACE" --identity="$CONFIG_DIR/admin-tls-ordservice.yaml"

        kubectl hlf ca register --name=<%= org.name.toLowerCase() %>-<%= org.ca.prefix %> --user="$<%= org.ca.caAdminNameVar %>" --secret="$<%= org.ca.caAdminPassVar %>" --type=admin --enroll-id <%= org.name.toLowerCase() %> --enroll-secret="$<%= org.ca.caAdminPassVar %>" --mspid <%= org.mspName %> &&
        kubectl hlf ca enroll --name=<%= org.name.toLowerCase() %>-<%= org.ca.prefix %> --user="$<%= org.ca.caAdminNameVar %>" --secret="$<%= org.ca.caAdminPassVar %>" --mspid <%= org.mspName %> --ca-name ca --output "$CONFIG_DIR/peer-<%= org.name %>.yaml" &&
        kubectl hlf inspect --output "$CONFIG_DIR/<%= org.name %>.yaml" -o "<%= org.mspName %>" -o "<%= channel.ordererHead.orgMspName %>" &&
        kubectl hlf utils adduser --userPath="$CONFIG_DIR/peer-<%= org.name %>.yaml" --config="$CONFIG_DIR/<%= org.name %>.yaml" --username="$<%= org.ca.caAdminNameVar %>" --mspid=<%= org.mspName %> &&

        sleep 10

      <% org.peers.forEach((peer) => { %>
        printItalics "Joining '<%= channel.name %>' on  <%= org.name.toLowerCase() %>/<%= peer.name %>" "U1F638"
        kubectl hlf channel join --name=<%= channel.name %> --config="$CONFIG_DIR/<%= org.name %>.yaml" --user="$<%= org.ca.caAdminNameVar %>" -p="<%= peer.name %>.$NAMESPACE"
      <% }) %>

      # add anchor peers
      <% org.anchorPeers.forEach((anchorpeer) => { %>
        printItalics "Electing on <%= org.name.toLowerCase() %>/<%= anchorpeer.name %> as Anchor peer" "U1F638"
        kubectl hlf channel addanchorpeer --channel=<%= channel.name %> --config="$CONFIG_DIR/<%= org.name %>.yaml" --user="$<%= org.ca.caAdminNameVar %>" --peer="<%= anchorpeer.name %>.$NAMESPACE"
      <% }) %>

      <% }) -%>
    <% }) -%>
}


installChaincodes() {
  <% chaincodes.forEach((chaincode) => { -%>

    printItalics "Installing chaincodes...." "U1F618"

    <% orgs.forEach((org) => { org.peers.forEach((peer) => { %>
      printItalics "Building chaincode <%= chaincode.name %>" "U1F618"
      buildAndInstallChaincode "<%= chaincode.name %>" "<%= peer.name %>.$NAMESPACE" "<%= chaincode.lang %>" "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" "<%= chaincode.version %>" "$<%= org.ca.caAdminNameVar %>" "$CONFIG_DIR/<%= org.name %>.yaml"

      printItalics "Approving chaincode...." "U1F618"
      approveChaincode "<%= chaincode.name %>" "<%= peer.name %>.$NAMESPACE" "<%= chaincode.version %>" "<%= chaincode.channel.name %>" "$<%= org.ca.caAdminNameVar %>" "$CONFIG_DIR/<%= org.name %>.yaml" "<%= org.mspName %>"

      printItalics "Committing chaincode '<%= chaincode.name %>' on channel '<%= chaincode.channel.name %>' " "U1F618"

      commitChaincode "<%= chaincode.name %>" "<%= peer.name %>.$NAMESPACE" "<%= chaincode.version %>" "<%= chaincode.channel.name %>" "$<%= org.ca.caAdminNameVar %>" "$CONFIG_DIR/<%= org.name %>.yaml" "<%= org.mspName %>"
    <% })}) %>
  <% }) %>
}

destroyNetwork() {
  kubectl delete fabricpeers.hlf.kungfusoftware.es --all-namespaces --all
  kubectl delete fabriccas.hlf.kungfusoftware.es --all-namespaces --all
  kubectl delete fabricorderernodes.hlf.kungfusoftware.es --all-namespaces --all
  kubectl delete fabricchaincode.hlf.kungfusoftware.es --all-namespaces --all
}

printHeadline() {
  bold=$'\e[1m'
  end=$'\e[0m'

  TEXT=$1
  EMOJI=$2
  printf "${bold}============ %b %s %b ==============${end}\n" "\\$EMOJI" "$TEXT" "\\$EMOJI"
}

printItalics() {
  italics=$'\e[3m'
  end=$'\e[0m'

  TEXT=$1
  EMOJI=$2
  printf "${italics}==== %b %s %b ====${end}\n" "\\$EMOJI" "$TEXT" "\\$EMOJI"
}

inputLog() {
  end=$'\e[0m'
  darkGray=$'\e[90m'

  echo "${darkGray}   $1 ${end}"
}

inputLogShort() {
  end=$'\e[0m'
  darkGray=$'\e[90m'

  echo "${darkGray}   $1 ${end}"
}

verifyKubernetesConnectivity() {
  echo "Verifying kubectl-hlf installation..."
  if ! [[ $(command -v kubectl-hlf) ]]; then
    echo "Error: Fablo could not detect kubectl hlf plugin. Ensure you have installed:
  - kubectl - https://kubernetes.io/docs/tasks/tools/
  - helm - https://helm.sh/docs/intro/install/
  - krew - https://krew.sigs.k8s.io/docs/user-guide/setup/install/
  - hlf-operator along with krew hlf plugin - https://github.com/hyperledger-labs/hlf-operator#install-kubernetes-operator"
    exit 1
  else
    echo "  $(command -v kubectl-hlf)"
  fi

  if [ "$(kubectl get pods -l=app.kubernetes.io/name=hlf-operator -o jsonpath='{.items}')" = "[]" ]; then
    echo "Error: hlf-operator is not running. You can install it with:
  helm install hlf-operator --version=1.6.0 kfs/hlf-operator"
    exit 1
  fi

  echo "Verifying default kubernetes cluster"
  if ! kubectl get ns default >/dev/null 2>&1; then
    printf "No K8 cluster detected\n" >&2
    exit 1
  fi

  while [ "$(kubectl get pods -l=app.kubernetes.io/name=hlf-operator -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" ]; do
    sleep 5
    echo "$BLUE" "Waiting for Operator to be ready." "$RESETBG"
  done
}
