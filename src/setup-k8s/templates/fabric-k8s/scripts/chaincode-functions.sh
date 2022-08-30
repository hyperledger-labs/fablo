#!/usr/bin/env bash


buildAndInstallChaincode() {
  local CHAINCODE_NAME="$1"
  local PEER=$2
  local CHAINCODE_LANG=$3
  local CHAINCODE_DIR_PATH=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LABEL="${CHAINCODE_NAME}_$CHAINCODE_VERSION"

  if [ -z "$CHAINCODE_NAME" ]; then
    echo "Error: chaincode name is not provided"
    exit 1
  fi

  if [ -z "$PEER" ]; then
    echo "Error: peer number is not provided e.g 0, 1"
    exit 1
  fi

  if [ -z "$CHAINCODE_LANG" ]; then
    echo "Error: chaincode language is not provided"
    exit 1
  fi

  if [ -z "$CHAINCODE_VERSION" ]; then
    echo "Error: chaincode version is not provided e.g 1.0, 2.0"
    exit 1
  fi

  kubectl hlf chaincode install --path=$CHAINCODE_DIR_PATH \
    --config=$CONFIG_DIR/org1.yaml --language=$CHAINCODE_LANG --label=$CHAINCODE_LABEL --user=$ADMIN_USER --peer=$ORG-peer$PEER.$NAMESPACE
}

approveChaincode() {
  local CHAINCODE_NAME="$1"
  local PEER=$2
  local CHAINCODE_VERSION="$3"
  local CHANNEL_NAME="$4"

  if [ -z "$CHAINCODE_NAME" ]; then
    echo "Error: chaincode name is not provided"
    exit 1
  fi

  if [ -z "$PEER" ]; then
    echo "Error: peer number is not provided e.g 0, 1"
    exit 1
  fi

  if [ -z "$CHAINCODE_VERSION" ]; then
    echo "Error: chaincode version is not provided e.g 1.0, 2.0"
    exit 1
  fi

  if [ -z "$CHANNEL_NAME" ]; then
    echo "Error: channel name is not provided"
    exit 1
  fi

    PACKAGE_ID=$(kubectl hlf chaincode queryinstalled --config=$CONFIG_DIR/org1.yaml --user=$ADMIN_USER --peer=$ORG-peer$PEER.$NAMESPACE | awk '{print $1}' | grep chaincode)

    printItalics "Approving chaincode $CHAINCODE_NAME on peer$PEER" "U1F618"

    kubectl hlf chaincode approveformyorg --config=$CONFIG_DIR/org1.yaml --user=$ADMIN_USER --peer=$ORG-peer$PEER.$NAMESPACE \
    --package-id=$PACKAGE_ID --version "$CHAINCODE_VERSION" --sequence "$SEQUENCE" --name=$CHAINCODE_NAME \
    --policy="OR('$MSP_ORG.member')" --channel=$CHANNEL_NAME
}

commitChaincode() {

  local CHAINCODE_NAME="$1"
  local PEER=$2
  local CHAINCODE_VERSION="$3"
  local CHANNEL_NAME="$4"

  if [ -z "$CHAINCODE_NAME" ]; then
    echo "Error: chaincode name is not provided"
    exit 1
  fi

  if [ -z "$PEER" ]; then
    echo "Error: peer number is not provided e.g 0, 1"
    exit 1
  fi

  if [ -z "$CHAINCODE_VERSION" ]; then
    echo "Error: chaincode version is not provided e.g 1.0, 2.0"
    exit 1
  fi

  if [ -z "$CHANNEL_NAME" ]; then
    echo "Error: channel name is not provided"
    exit 1
  fi

    PACKAGE_ID=$(kubectl hlf chaincode queryinstalled --config=$CONFIG_DIR/org1.yaml --user=$ADMIN_USER --peer=$ORG-peer$PEER.$NAMESPACE | awk '{print $1}' | grep chaincode)

    kubectl hlf chaincode commit --config=$CONFIG_DIR/org1.yaml --user=$ADMIN_USER --mspid=$MSP_ORG \
    --version "$VERSION" --sequence "$SEQUENCE" --name=$CHAINCODE_NAME \
    --policy="OR('$MSP_ORG.member')" --channel=$CHANNEL_NAME
}


