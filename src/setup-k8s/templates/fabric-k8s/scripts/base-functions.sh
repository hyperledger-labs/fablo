#!/usr/bin/env bash

source "$FABLO_NETWORK_ROOT/fabric-k8s/scripts/util.sh"

certsGenerate() {

  printItalics "Deploying Certificate Authority" "U1F984"

  kubectl hlf ca create --storage-class=$STORAGE_CLASS --capacity=2Gi --name=$ORG-ca --enroll-id=$ORG1_CA_ADMIN_NAME --enroll-pw=$ORG1_CA_ADMIN_PASSWORD && sleep 3

  while [[ $(kubectl get pods -l release=$ORG-ca -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    sleep 5
    inputLog "waiting for CA"
  done

  kubectl hlf ca register --name=$ORG-ca --user=peer --secret=$PEER_SECRET --type=peer --enroll-id $ORG1_CA_ADMIN_NAME --enroll-secret=$ORG1_CA_ADMIN_PASSWORD --mspid $MSP_ORG &&
    inputLog "registered $ORG-ca"
}

deployPeer() {

  printItalics "Deploying Peers" "U1F984"
  sleep 10

  kubectl hlf peer create --image=$PEER_IMAGE --version=$PEER_VERSION --storage-class=$STORAGE_CLASS --enroll-id=peer --mspid=$MSP_ORG \
    --enroll-pw=$PEER_SECRET --capacity=5Gi --name=$ORG-peer0 --ca-name=$ORG-ca.$NAMESPACE --k8s-builder=true --external-service-builder=false
  kubectl hlf peer create --image=$PEER_IMAGE --version=$PEER_VERSION --storage-class=$STORAGE_CLASS --enroll-id=peer --mspid=$MSP_ORG \
    --enroll-pw=$PEER_SECRET --capacity=5Gi --name=$ORG-peer1 --ca-name=$ORG-ca.$NAMESPACE --k8s-builder=true --external-service-builder=false

  while [[ $(kubectl get pods -l app=hlf-peer --output=jsonpath='{.items[*].status.containerStatuses[0].ready}') != "true true" ]]; do
    sleep 5
    inputLog "waiting for peer nodes to be ready"
  done
}

deployOrderer() {

  printItalics "Deploying Orderers" "U1F984"
  kubectl hlf ca create --storage-class=$STORAGE_CLASS --capacity=2Gi --name=$ORD-ca --enroll-id=$ORG1_CA_ADMIN_NAME --enroll-pw=$ORG1_CA_ADMIN_PASSWORD

  while [[ $(kubectl get pods -l release=$ORD-ca -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    sleep 5
    inputLog "waiting for $ORD CA to be ready" $RESETBG
  done

  kubectl hlf ca register --name=$ORD-ca --user=orderer --secret=$ORDERER_SECRET --type=orderer --enroll-id=$ORG1_CA_ADMIN_NAME --enroll-secret=$ORG1_CA_ADMIN_PASSWORD --mspid $MSP_ORD &&
    inputLog "registered $ORD-ca"

  kubectl hlf ordnode create --image=$ORDERER_IMAGE --version=$ORDERER_VERSION \
    --storage-class=$STORAGE_CLASS --enroll-id=$ORD --mspid=$MSP_ORD \
    --enroll-pw=$ORDERER_SECRET --capacity=2Gi --name=$ORD-node1 --ca-name=$ORD-ca.$NAMESPACE

  while [[ $(kubectl get pods -l app=hlf-ordnode -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    sleep 5
    inputLog "waiting for $ORD Node to be ready"
  done
}

# Might no be needed, after last meeting

adminConfig() {
  kubectl hlf inspect --output $CONFIG_DIR/ordservice.yaml -o $MSP_ORD &&
    kubectl hlf ca register --name=$ORD-ca --user=$ADMIN_USER --secret=$ADMIN_PASS --type=admin --enroll-id=$ORG1_CA_ADMIN_NAME --enroll-secret=$ORG1_CA_ADMIN_PASSWORD --mspid=$MSP_ORD

  kubectl hlf ca enroll --name=$ORD-ca --user=$ADMIN_USER --secret=$ADMIN_PASS --mspid $MSP_ORD --ca-name ca --output $CONFIG_DIR/admin-ordservice.yaml &&
    kubectl hlf utils adduser --userPath=$CONFIG_DIR/admin-ordservice.yaml --config=$CONFIG_DIR/ordservice.yaml --username=$ADMIN_USER --mspid=$MSP_ORD
}

installChannels() {
  printItalics "Creating 'my-channel1' on Org1/peer0" "U1F63B"
  sleep 10
  kubectl hlf channel generate --output=$CONFIG_DIR/$CHANNEL_NAME.block --name=$CHANNEL_NAME --organizations $MSP_ORG --ordererOrganizations $MSP_ORD &&
    kubectl hlf ca enroll --name=$ORD-ca --namespace=$NAMESPACE --user=$ADMIN_USER --secret=$ADMIN_PASS --mspid $MSP_ORD --ca-name $USER_CA_TYPE --output $CONFIG_DIR/admin-tls-ordservice.yaml &&
    sleep 10

  kubectl hlf ordnode join --block=$CONFIG_DIR/$CHANNEL_NAME.block --name=$ORD-node1 --namespace=$NAMESPACE --identity=$CONFIG_DIR/admin-tls-ordservice.yaml
}

joinChannels() {

  printItalics "Joining 'my-channel1' on  Org1/peer0" "U1F638"

  kubectl hlf ca register --name=$ORG-ca --user=$ADMIN_USER --secret=$ADMIN_PASS --type=admin --enroll-id $ORG1_CA_ADMIN_NAME --enroll-secret=$ORG1_CA_ADMIN_PASSWORD --mspid $MSP_ORG &&
    kubectl hlf ca enroll --name=$ORG-ca --user=$ADMIN_USER --secret=$ADMIN_PASS --mspid $MSP_ORG --ca-name ca --output $CONFIG_DIR/peer-org1.yaml &&
    kubectl hlf inspect --output $CONFIG_DIR/org1.yaml -o $MSP_ORG -o $MSP_ORD &&
    kubectl hlf utils adduser --userPath=$CONFIG_DIR/peer-org1.yaml --config=$CONFIG_DIR/org1.yaml --username=$ADMIN_USER --mspid=$MSP_ORG &&
    printItalics "Joining 'my-channel1' on  Org1/peer0" "U1F638"

  retry 3 kubectl hlf channel join --name=$CHANNEL_NAME --config=$CONFIG_DIR/org1.yaml --user=$ADMIN_USER -p=$ORG-peer0.$NAMESPACE

  printItalics "Joining 'my-channel1' on  Org1/peer1" "U1F638"

  retry 3 kubectl hlf channel join --name=$CHANNEL_NAME --config=$CONFIG_DIR/org1.yaml --user=$ADMIN_USER -p=$ORG-peer1.$NAMESPACE

  # add anchor peer

  printItalics "Electing on Org1/peer0 as Anchor peer" "U1F638"

  kubectl hlf channel addanchorpeer --channel=$CHANNEL_NAME --config=$CONFIG_DIR/org1.yaml --user=$ADMIN_USER --peer=$ORG-peer0.$NAMESPACE
}

installChaincodes() {
  printItalics "Building chaincode $CHAINCODE_NAME" "U1F618"

  buildAndInstallChaincode "$CHAINCODE_NAME" "0" "$CHAINCODE_LANG" "$CHAINCODES_BASE_DIR/./chaincodes/chaincode-kv-node" "$CHAINCODE_VERSION"
  buildAndInstallChaincode "$CHAINCODE_NAME" "1" "$CHAINCODE_LANG" "$CHAINCODES_BASE_DIR/./chaincodes/chaincode-kv-node" "$CHAINCODE_VERSION"

  approveChaincode "$CHAINCODE_NAME" "1" "$CHAINCODE_VERSION" "$CHANNEL_NAME"

  printItalics "Committing chaincode '$CHAINCODE_NAME' on channel '$CHANNEL_NAME' as '$ORG'" "U1F618"
  commitChaincode "$CHAINCODE_NAME" "1" "$CHAINCODE_VERSION" "$CHANNEL_NAME"
}

destroyNetwork() {
  kubectl delete fabricpeers.hlf.kungfusoftware.es --all-namespaces --all
  kubectl delete fabriccas.hlf.kungfusoftware.es --all-namespaces --all
  kubectl delete fabricorderernodes.hlf.kungfusoftware.es --all-namespaces --all
  kubectl delete fabricchaincode.hlf.kungfusoftware.es --all-namespaces --all
}

hlfOperator() {
  helm repo add kfs $REPOSITORY --force-update

  helm install hlf-operator --version=1.6.0 kfs/hlf-operator

  while [ "$(kubectl get pods -l=app.kubernetes.io/name=hlf-operator -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" ]; do
    sleep 5
    echo $BLUE "Waiting for Operator to be ready." $RESETBG
  done
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

checkDependencies() {
  if [[ $(command -v kubectl) ]]; then
    printf "\nKubectl installed...\n"
  else
    printf "\nCouldn't detect Kubectl \n" && exit 1
  fi

  if [[ $(command -v kubectl-hlf) ]]; then
    printf "\nHLF installed...\n"
  else
    printf "\nCouldn't detect the HLF Plugin \n" && exit 1
  fi

  if [[ $(command -v helm) ]]; then
    printf "\nHelm installed\n"
  else
    printf "\nCouldn't detect Helm \n" && exit 1
  fi
}

validateK8Connectivity() {
  if ! kubectl get ns default >/dev/null 2>&1; then
    printf "\nNo K8 cluster detected\n" >&2
    exit 1
  fi
}
