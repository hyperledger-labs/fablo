#!/usr/bin/env bash

set -eu

createChannelAndJoin() {
  local CHANNEL_NAME=$1

  local CORE_PEER_LOCALMSPID=$2
  local CORE_PEER_ADDRESS=$3
  local CORE_PEER_MSPCONFIGPATH=$(realpath "$4")

  local ORDERER_URL=$5

  local DIR_NAME=step-createChannelAndJoin-$CHANNEL_NAME-$CORE_PEER_ADDRESS

  echo "Creating channel with name: ${CHANNEL_NAME}"
  echo "   Orderer: $ORDERER_URL"
  echo "   CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
  echo "   CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"
  echo "   CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"

  mkdir "$DIR_NAME" && cd "$DIR_NAME"

  cp /var/hyperledger/cli/config/"$CHANNEL_NAME".pb .

  osnadmin channel join --channelID "${CHANNEL_NAME}" --config-block ./"$CHANNEL_NAME".pb -o "${ORDERER_URL}"
  cd .. && rm -rf "$DIR_NAME"
}

createChannelAndJoinTls() {
  local CHANNEL_NAME=$1
  local ORDERER_MSP_NAME=$2
  local ORDERER_ADMIN_ADDRESS=$3
  local ADMIN_TLS_SIGN_CERT=$(realpath "$4")
  local ADMIN_TLS_PRIVATE_KEY=$(realpath "$5")
  local TLS_CA_CERT_PATH=$(realpath "$6")

  local DIR_NAME=step-createChannelAndJoinTls-$CHANNEL_NAME-$ORDERER_MSP_NAME

  echo "Creating channel with name (TLS): ${CHANNEL_NAME}"
  echo "   ORDERER_MSP_NAME:      $ORDERER_MSP_NAME"
  echo "   ORDERER_ADMIN_ADDRESS: $ORDERER_ADMIN_ADDRESS"
  echo "   ADMIN_TLS_SIGN_CERT:   $ADMIN_TLS_SIGN_CERT"
  echo "   ADMIN_TLS_PRIVATE_KEY: $ADMIN_TLS_PRIVATE_KEY"
  echo "   TLS_CA_CERT_PATH:      $TLS_CA_CERT_PATH"

  if [ ! -d "$DIR_NAME" ]; then
    mkdir -p "$DIR_NAME"
    cp /var/hyperledger/cli/config/"$CHANNEL_NAME".pb "$DIR_NAME"
  fi

  osnadmin channel join \
    --channelID "${CHANNEL_NAME}" \
    --config-block "$DIR_NAME/$CHANNEL_NAME.pb" \
    -o "${ORDERER_ADMIN_ADDRESS}" \
    --client-cert "${ADMIN_TLS_SIGN_CERT}" \
    --client-key "${ADMIN_TLS_PRIVATE_KEY}" \
    --ca-file "${TLS_CA_CERT_PATH}"

  cd ..
  rm -rf "$DIR_NAME"
}

fetchChannelAndJoin() {
  local CHANNEL_NAME=$1
  local CORE_PEER_LOCALMSPID=$2
  local CORE_PEER_ADDRESS=$3
  local CORE_PEER_MSPCONFIGPATH=$(realpath "$4")
  local ORDERER_URL=$5

  local DIR_NAME=step-fetchChannelAndJoin-$CHANNEL_NAME-$CORE_PEER_ADDRESS

  echo "Fetching channel with name: ${CHANNEL_NAME}"
  echo "   Orderer: $ORDERER_URL"
  echo "   CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
  echo "   CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"
  echo "   CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"

  mkdir "$DIR_NAME" && cd "$DIR_NAME"

  peer channel fetch newest -c "${CHANNEL_NAME}" --orderer "${ORDERER_URL}"
  peer channel join -b "${CHANNEL_NAME}"_newest.block

  cd .. && rm -rf "$DIR_NAME"
}

fetchChannelAndJoinTls() {
  local CHANNEL_NAME=$1
  local CORE_PEER_LOCALMSPID=$2
  local CORE_PEER_ADDRESS=$3
  local CORE_PEER_MSPCONFIGPATH=$(realpath "$4")
  local CORE_PEER_TLS_MSPCONFIGPATH=$(realpath "$5")
  local TLS_CA_CERT_PATH=$(realpath "$6")
  local ORDERER_URL=$7

  local CORE_PEER_TLS_CERT_FILE=$CORE_PEER_TLS_MSPCONFIGPATH/client.crt
  local CORE_PEER_TLS_KEY_FILE=$CORE_PEER_TLS_MSPCONFIGPATH/client.key
  local CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_MSPCONFIGPATH/ca.crt

  local DIR_NAME=step-fetchChannelAndJoinTls-$CHANNEL_NAME-$CORE_PEER_ADDRESS

  echo "Fetching channel with name (TLS): ${CHANNEL_NAME}"
  echo "   Orderer: $ORDERER_URL"
  echo "   CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
  echo "   CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"
  echo "   CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"
  echo "   TLS_CA_CERT_PATH is: $TLS_CA_CERT_PATH"
  echo "   CORE_PEER_TLS_CERT_FILE: $CORE_PEER_TLS_CERT_FILE"
  echo "   CORE_PEER_TLS_KEY_FILE: $CORE_PEER_TLS_KEY_FILE"
  echo "   CORE_PEER_TLS_ROOTCERT_FILE: $CORE_PEER_TLS_ROOTCERT_FILE"

  mkdir "$DIR_NAME" && cd "$DIR_NAME"

  peer channel fetch newest -c "${CHANNEL_NAME}" --orderer "${ORDERER_URL}" --tls --cafile "$TLS_CA_CERT_PATH"
  peer channel join -b "${CHANNEL_NAME}"_newest.block --tls --cafile "$TLS_CA_CERT_PATH"

  cd .. && rm -rf "$DIR_NAME"
}
