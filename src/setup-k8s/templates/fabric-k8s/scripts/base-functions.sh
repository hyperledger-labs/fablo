#!/usr/bin/env bash

source "$FABLO_NETWORK_ROOT/fabric-k8s/scripts/util.sh"


deployPeer() {

  <% orgs.forEach((org) => { -%>
    <% if(org.peers.length > 0 ) { -%>

      printItalics "Deploying <%= org.name %> CA" "U1F984"
      kubectl hlf ca create --image="$CA_IMAGE" --version="$CA_VERSION" --storage-class="$STORAGE_CLASS" --capacity=2Gi --name=<%= org.name.toLowerCase() %>-<%= org.ca.prefix %> --enroll-id=<%= org.name.toLowerCase() %> --enroll-pw="$<%= org.ca.caAdminPassVar %>"
      sleep 3

      while [[ $(kubectl get pods -l release=<%= org.name.toLowerCase() %>-<%= org.ca.prefix %> -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
        sleep 5
        inputLog "waiting for CA"
      done

      kubectl hlf ca register --name=<%= org.name.toLowerCase() %>-<%= org.ca.prefix %> --user=peer --secret="$<%= org.ca.caAdminPassVar %>" --type=peer --enroll-id <%= org.name.toLowerCase() %>  --enroll-secret="$<%= org.ca.caAdminPassVar %>" --mspid <%= org.mspName %>
      inputLog "registered <%= org.name %> -ca"

      printItalics "Deploying Peers" "U1F984"
      sleep 10

      <% orgs.forEach((org) => { org.peers.forEach((peer) => { %>
        kubectl hlf peer create --statedb=<%= peer.db.type.toLowerCase() %> --version="$PEER_VERSION" --storage-class="$STORAGE_CLASS" --enroll-id=peer --mspid=<%= org.mspName %> \
          --enroll-pw="$<%= org.ca.caAdminPassVar %>" --capacity=5Gi --name=<%= peer.name %> --ca-name="<%= org.name.toLowerCase() %>-<%= org.ca.prefix %>.$NAMESPACE" --k8s-builder=true --external-service-builder=false
      <% })}) %>

    <% } -%>
  <% }) %>

  while [[ $(kubectl get pods -l app=hlf-peer --output=jsonpath='{.items[*].status.containerStatuses[0].ready}') != "true true" ]]; do
    sleep 5
    inputLog "waiting for peer nodes to be ready"
  done
}

deployOrderer() {

  printItalics "Deploying Orderers" "U1F984"

  <% orgs.forEach((org) => { -%>
    <% if(org.name == "Orderer") { -%>
      kubectl hlf ca create --storage-class="$STORAGE_CLASS" --capacity=2Gi --name=<%= org.name.toLowerCase() %>-<%= org.ca.prefix %>  --enroll-id=<%= org.name.toLowerCase() %> --enroll-pw="$<%= org.ca.caAdminPassVar %>"
  while [[ $(kubectl get pods -l release=<%= org.name.toLowerCase() %>-<%= org.ca.prefix %> -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    sleep 5
    inputLog "waiting for <%= org.name.toLowerCase() %>-<%= org.ca.prefix %> CA to be ready" "$RESETBG"
  done
  kubectl hlf ca register --name=<%= org.name.toLowerCase() %>-<%= org.ca.prefix %> --user="$<%= org.ca.caAdminNameVar %>" --secret="$<%= org.ca.caAdminPassVar %>" --type=orderer --enroll-id=<%= org.name.toLowerCase() %> --enroll-secret="$<%= org.ca.caAdminPassVar %>" --mspid <%= org.mspName %> &&
    inputLog "registered <%= org.name.toLowerCase() %>-<%= org.ca.prefix %>"

    kubectl hlf ordnode create --version="$ORDERER_VERSION" \
      --storage-class="$STORAGE_CLASS" --enroll-id="$<%= org.ca.caAdminNameVar %>"  --mspid=<%= org.mspName %> \
      --enroll-pw="$<%= org.ca.caAdminPassVar %>" --capacity=2Gi --name=<%= org.name.toLowerCase() %>-node --ca-name="<%= org.name.toLowerCase() %>-<%= org.ca.prefix %>.$NAMESPACE"
  while [[ $(kubectl get pods -l app=hlf-ordnode -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    sleep 5
    inputLog "waiting for <%= org.name.toLowerCase() %> Node to be ready"
  done

    kubectl hlf inspect --output "$CONFIG_DIR/ordservice.yaml" -o <%= org.mspName %>
    kubectl hlf ca enroll --name=<%= org.name.toLowerCase() %>-<%= org.ca.prefix %> --user="$<%= org.ca.caAdminNameVar %>" --secret="$<%= org.ca.caAdminPassVar %>" --mspid <%= org.mspName %> --ca-name ca --output "$CONFIG_DIR/admin-ordservice.yaml" &&
    kubectl hlf utils adduser --userPath="$CONFIG_DIR/admin-ordservice.yaml" --config="$CONFIG_DIR/ordservice.yaml" --username="$<%= org.ca.caAdminNameVar %>" --mspid=<%= org.mspName %>
    <% } -%>
  <% }) %>
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
