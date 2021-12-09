#!/usr/bin/env bash

certsGenerate() {
  local CONTAINER_NAME=certsGenerate

  local CONFIG_PATH=$1
  local CRYPTO_CONFIG_FILE_NAME=$2
  local ORG_PATH=$3
  local OUTPUT_PATH=$4
  local FULL_CERT_PATH=$OUTPUT_PATH$ORG_PATH

  echo "Generating certs..."
  inputLog "CONFIG_PATH: $CONFIG_PATH"
  inputLog "CRYPTO_CONFIG_FILE_NAME: $CRYPTO_CONFIG_FILE_NAME"
  inputLog "ORG_PATH: $ORG_PATH"
  inputLog "OUTPUT_PATH: $OUTPUT_PATH"
  inputLog "FULL_CERT_PATH: $FULL_CERT_PATH"

  if [ -d "$FULL_CERT_PATH" ]; then
    echo "Can't generate certs, directory already exists : $FULL_CERT_PATH"
    echo "Try using 'reset' or 'down' to remove whole network or 'start' to reuse it"
    exit 1
  fi

  docker run -i -d -w="/" --name $CONTAINER_NAME hyperledger/fabric-tools:"${FABRIC_VERSION}" bash || removeContainer $CONTAINER_NAME
  docker cp "$CONFIG_PATH" $CONTAINER_NAME:/fabric-config || removeContainer $CONTAINER_NAME

  docker exec -i $CONTAINER_NAME cryptogen generate --config=./fabric-config/"$CRYPTO_CONFIG_FILE_NAME" || removeContainer $CONTAINER_NAME

  docker cp $CONTAINER_NAME:/crypto-config/. "$OUTPUT_PATH" || removeContainer $CONTAINER_NAME

  removeContainer $CONTAINER_NAME

  # shellcheck disable=2044
  for file in $(find "$OUTPUT_PATH"/ -iname '*_sk'); do
    dir=$(dirname "$file")
    mv "${dir}"/*_sk "${dir}"/priv-key.pem
  done
}

genesisBlockCreate() {
  local CONTAINER_NAME=genesisBlockCreate

  local CONFIG_PATH=$1
  local OUTPUT_PATH=$2
  local GENESIS_PROFILE_NAME=$3
  local GENESIS_FILE_NAME=$GENESIS_PROFILE_NAME.block

  echo "Creating genesis block..."
  inputLog "CONFIG_PATH: $CONFIG_PATH"
  inputLog "OUTPUT_PATH: $OUTPUT_PATH"
  inputLog "GENESIS_PROFILE_NAME: $GENESIS_PROFILE_NAME"
  inputLog "GENESIS_FILE_NAME: $GENESIS_FILE_NAME"

  if [ -f "$OUTPUT_PATH/$GENESIS_FILE_NAME" ]; then
    echo "Cant't generate genesis block, file already exists: $OUTPUT_PATH/$GENESIS_FILE_NAME"
    echo "Try using 'reset' or 'down' to remove whole network or 'start' to reuse it"
    exit 1
  fi

  docker run -i -d -w="/" --name $CONTAINER_NAME hyperledger/fabric-tools:"${FABRIC_VERSION}" bash || removeContainer $CONTAINER_NAME
  docker cp "$CONFIG_PATH" $CONTAINER_NAME:/fabric-config || removeContainer $CONTAINER_NAME

  docker exec -i $CONTAINER_NAME mkdir /config || removeContainer $CONTAINER_NAME
  docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile "$GENESIS_PROFILE_NAME" -outputBlock "./config/$GENESIS_FILE_NAME" -channelID system-channel || removeContainer $CONTAINER_NAME

  mkdir -p "$OUTPUT_PATH"
  docker cp "$CONTAINER_NAME:/config/$GENESIS_FILE_NAME" "$OUTPUT_PATH/$GENESIS_FILE_NAME" || removeContainer $CONTAINER_NAME

  removeContainer $CONTAINER_NAME
}

createChannelTx() {
  local CONTAINER_NAME=createChannelTx

  local CHANNEL_NAME=$1
  local CONFIG_PATH=$2
  local CONFIG_PROFILE=$3
  local OUTPUT_PATH=$4
  local CHANNEL_TX_PATH="$OUTPUT_PATH/$CHANNEL_NAME".tx

  echo "Creating channelTx for $CHANNEL_NAME..."
  inputLog "CONFIG_PATH: $CONFIG_PATH"
  inputLog "CONFIG_PROFILE: $CONFIG_PROFILE"
  inputLog "OUTPUT_PATH: $OUTPUT_PATH"
  inputLog "CHANNEL_TX_PATH: $CHANNEL_TX_PATH"

  if [ -f "$CHANNEL_TX_PATH" ]; then
    echo "Can't create channel configuration, it already exists : $CHANNEL_TX_PATH"
    echo "Try using 'reset' or 'down' to remove whole network or 'start' to reuse it"
    exit 1
  fi

  docker run -i -d -w="/" --name $CONTAINER_NAME hyperledger/fabric-tools:"${FABRIC_VERSION}" bash || removeContainer $CONTAINER_NAME
  docker cp "$CONFIG_PATH" $CONTAINER_NAME:/fabric-config || removeContainer $CONTAINER_NAME

  docker exec -i $CONTAINER_NAME mkdir /config || removeContainer $CONTAINER_NAME
  docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile "${CONFIG_PROFILE}" -outputCreateChannelTx ./config/channel.tx -channelID "${CHANNEL_NAME}" || removeContainer $CONTAINER_NAME

  docker cp $CONTAINER_NAME:/config/channel.tx "$CHANNEL_TX_PATH" || removeContainer $CONTAINER_NAME

  removeContainer $CONTAINER_NAME
}

createNewChannelUpdateTx() {
  local CONTAINER_NAME=createAnchorPeerUpdateTx

  local CHANNEL_NAME=$1
  local MSP_NAME=$2
  local CONFIG_PROFILE=$3
  local CONFIG_PATH=$4
  local OUTPUT_PATH=$5
  local ANCHOR_PEER_UPDATE_PATH="$OUTPUT_PATH/${MSP_NAME}anchors-$CHANNEL_NAME.tx"

  echo "Creating new channel config block. Channel: $CHANNEL_NAME for organization $MSP_NAME..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "MSP_NAME: $MSP_NAME"
  inputLog "CONFIG_PROFILE: $CONFIG_PROFILE"
  inputLog "CONFIG_PATH: $CONFIG_PATH"
  inputLog "OUTPUT_PATH: $OUTPUT_PATH"
  inputLog "ANCHOR_PEER_UPDATE_PATH: $ANCHOR_PEER_UPDATE_PATH"

  if [ -f "$ANCHOR_PEER_UPDATE_PATH" ]; then
    echo "Cant't create anchor peer update, it already exists : $ANCHOR_PEER_UPDATE_PATH"
    echo "Try using 'reset' or 'down' to remove whole network or 'start' to reuse it"
    exit 1
  fi

  docker run -i -d -w="/" --name $CONTAINER_NAME hyperledger/fabric-tools:"${FABRIC_VERSION}" bash || removeContainer $CONTAINER_NAME
  docker cp "$CONFIG_PATH" $CONTAINER_NAME:/fabric-config || removeContainer $CONTAINER_NAME

  docker exec -i $CONTAINER_NAME mkdir /config || removeContainer $CONTAINER_NAME
  docker exec -i $CONTAINER_NAME configtxgen \
    --configPath ./fabric-config \
    -profile "${CONFIG_PROFILE}" \
    -outputAnchorPeersUpdate ./config/"${MSP_NAME}"anchors.tx \
    -channelID "${CHANNEL_NAME}" \
    -asOrg "${MSP_NAME}" || removeContainer $CONTAINER_NAME

  docker cp $CONTAINER_NAME:/config/"${MSP_NAME}"anchors.tx "$ANCHOR_PEER_UPDATE_PATH" || removeContainer $CONTAINER_NAME

  removeContainer $CONTAINER_NAME
}

notifyOrgAboutNewChannel() {
  local CHANNEL_NAME=$1
  local MSP_NAME=$2
  local CLI_NAME=$3
  local PEER_ADDRESS=$4
  local ORDERER_URL=$5
  local ANCHOR_PEER_UPDATE_PATH="/var/hyperledger/cli/config/${MSP_NAME}anchors-$CHANNEL_NAME.tx"

  echo "Updating channel $CHANNEL_NAME for organization $MSP_NAME..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "MSP_NAME: $MSP_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "ANCHOR_PEER_UPDATE_PATH: $ANCHOR_PEER_UPDATE_PATH"

  if [ -n "$ANCHOR_PEER_UPDATE_PATH" ]; then
    docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
      "$CLI_NAME" peer channel update \
      -c "$CHANNEL_NAME" \
      -o "$ORDERER_URL" \
      -f "$ANCHOR_PEER_UPDATE_PATH"
  else
    echo "channel update tx not found! Looked for: $ANCHOR_PEER_UPDATE_PATH"
  fi
}

notifyOrgAboutNewChannelTls() {
  local CHANNEL_NAME=$1
  local MSP_NAME=$2
  local CLI_NAME=$3
  local PEER_ADDRESS=$4
  local ORDERER_URL=$5
  local ANCHOR_PEER_UPDATE_PATH="/var/hyperledger/cli/config/${MSP_NAME}anchors-$CHANNEL_NAME.tx"
  local CA_CERT="/var/hyperledger/cli/"${6}

  echo "Updating channel $CHANNEL_NAME for organization $MSP_NAME (TLS)..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "MSP_NAME: $MSP_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "ANCHOR_PEER_UPDATE_PATH: $ANCHOR_PEER_UPDATE_PATH"

  if [ -n "$ANCHOR_PEER_UPDATE_PATH" ]; then
    docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
      "$CLI_NAME" peer channel update \
      -c "$CHANNEL_NAME" \
      -o "$ORDERER_URL" \
      -f "$ANCHOR_PEER_UPDATE_PATH" \
      --tls --cafile "$CA_CERT"
  else
    echo "channel update tx not found! Looked for: $ANCHOR_PEER_UPDATE_PATH"
  fi
}

deleteNewChannelUpdateTx() {
  local CHANNEL_NAME=$1
  local MSP_NAME=$2
  local CLI_NAME=$3
  local ANCHOR_PEER_UPDATE_PATH="/var/hyperledger/cli/config/${MSP_NAME}anchors-$CHANNEL_NAME.tx"

  echo "Deleting new channel config block. Channel: $CHANNEL_NAME, Organization: $MSP_NAME"
  inputLogShort "CHANNEL_NAME: $CHANNEL_NAME, MSP_NAME: $MSP_NAME, CLI_NAME: $CLI_NAME, ANCHOR_PEER_UPDATE_PATH: $ANCHOR_PEER_UPDATE_PATH"

  if [ -n "$ANCHOR_PEER_UPDATE_PATH" ]; then
    docker exec "$CLI_NAME" rm "$ANCHOR_PEER_UPDATE_PATH"
  else
    echo "channel update tx not found! Looked for: $ANCHOR_PEER_UPDATE_PATH"
  fi
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

certsRemove() {
  local CERTS_DIR_PATH=$1
  rm -rf "$CERTS_DIR_PATH"
}

removeContainer() {
  CONTAINER_NAME=$1
  docker rm -f "$CONTAINER_NAME"
}
