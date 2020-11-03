function certsGenerate() {
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
    echo "Try using 'recreate' or 'down' to remove whole network or 'start' to reuse it"
    exit 1
  fi

  docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash || removeContainer $CONTAINER_NAME
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config || removeContainer $CONTAINER_NAME

  docker exec -i $CONTAINER_NAME cryptogen generate --config=./fabric-config/$CRYPTO_CONFIG_FILE_NAME || removeContainer $CONTAINER_NAME

  docker cp $CONTAINER_NAME:/crypto-config/. $OUTPUT_PATH || removeContainer $CONTAINER_NAME

  removeContainer $CONTAINER_NAME
  for file in $(find $OUTPUT_PATH/ -iname *_sk); do
    dir=$(dirname $file)
    mv ${dir}/*_sk ${dir}/priv-key.pem
  done
}

function genesisBlockCreate() {
  local CONTAINER_NAME=genesisBlockCreate

  local CONFIG_PATH=$1
  local OUTPUT_PATH=$2

  echo "Creating genesis block..."
  inputLog "CONFIG_PATH: $CONFIG_PATH"
  inputLog "OUTPUT_PATH: $OUTPUT_PATH"

  if [ -d "$OUTPUT_PATH" ]; then
    echo "Cant't generate genesis block, directory already exists : $OUTPUT_PATH"
    echo "Try using 'recreate' or 'down' to remove whole network or 'start' to reuse it"
    exit 1
  fi

  docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash || removeContainer $CONTAINER_NAME
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config || removeContainer $CONTAINER_NAME

  docker exec -i $CONTAINER_NAME mkdir /config || removeContainer $CONTAINER_NAME
  docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile OrdererGenesis -outputBlock ./config/genesis.block || removeContainer $CONTAINER_NAME

  docker cp $CONTAINER_NAME:/config $OUTPUT_PATH || removeContainer $CONTAINER_NAME

  removeContainer $CONTAINER_NAME
}

function createChannelTx() {
  local CONTAINER_NAME=createChannelTx

  local CHANNEL_NAME=$1
  local CONFIG_PATH=$2
  local CONFIG_PROFILE=$3
  local OUTPUT_PATH=$4
  local CHANNEL_TX_PATH=$OUTPUT_PATH"/"$CHANNEL_NAME".tx"

  echo "Creating channelTx for $CHANNEL_NAME..."
  inputLog "CONFIG_PATH: $CONFIG_PATH"
  inputLog "CONFIG_PROFILE: $CONFIG_PROFILE"
  inputLog "OUTPUT_PATH: $OUTPUT_PATH"
  inputLog "CHANNEL_TX_PATH: $CHANNEL_TX_PATH"

  if [ -f "$CHANNEL_TX_PATH" ]; then
    echo "Can't create channel configuration, it already exists : $CHANNEL_TX_PATH"
    echo "Try using 'recreate' or 'down' to remove whole network or 'start' to reuse it"
    exit 1
  fi

  docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash || removeContainer $CONTAINER_NAME
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config || removeContainer $CONTAINER_NAME

  docker exec -i $CONTAINER_NAME mkdir /config || removeContainer $CONTAINER_NAME
  docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile ${CONFIG_PROFILE} -outputCreateChannelTx ./config/channel.tx -channelID ${CHANNEL_NAME} || removeContainer $CONTAINER_NAME

  docker cp $CONTAINER_NAME:/config/channel.tx $CHANNEL_TX_PATH || removeContainer $CONTAINER_NAME

  removeContainer $CONTAINER_NAME
}

function createNewChannelUpdateTx() {
  local CONTAINER_NAME=createAnchorPeerUpdateTx

  local CHANNEL_NAME=$1
  local MSP_NAME=$2
  local CONFIG_PROFILE=$3
  local CONFIG_PATH=$4
  local OUTPUT_PATH=$5
  local ANCHOR_PEER_UPDATE_PATH=$OUTPUT_PATH"/"$MSP_NAME"anchors-$CHANNEL_NAME.tx"

  echo "Creating new channel config block. Channel: $CHANNEL_NAME for organization $MSP_NAME..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "MSP_NAME: $MSP_NAME"
  inputLog "CONFIG_PROFILE: $CONFIG_PROFILE"
  inputLog "CONFIG_PATH: $CONFIG_PATH"
  inputLog "OUTPUT_PATH: $OUTPUT_PATH"
  inputLog "ANCHOR_PEER_UPDATE_PATH: $ANCHOR_PEER_UPDATE_PATH"

  if [ -f "$ANCHOR_PEER_UPDATE_PATH" ]; then
    echo "Cant't create anchor peer update, it already exists : $ANCHOR_PEER_UPDATE_PATH"
    echo "Try using 'recreate' or 'down' to remove whole network or 'start' to reuse it"
    exit 1
  fi

  docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash || removeContainer $CONTAINER_NAME
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config || removeContainer $CONTAINER_NAME

  docker exec -i $CONTAINER_NAME mkdir /config || removeContainer $CONTAINER_NAME
  docker exec -i $CONTAINER_NAME configtxgen \
    --configPath ./fabric-config \
    -profile ${CONFIG_PROFILE} \
    -outputAnchorPeersUpdate ./config/${MSP_NAME}anchors.tx \
    -channelID ${CHANNEL_NAME} \
    -asOrg ${MSP_NAME} || removeContainer $CONTAINER_NAME

  docker cp $CONTAINER_NAME:/config/${MSP_NAME}anchors.tx $ANCHOR_PEER_UPDATE_PATH || removeContainer $CONTAINER_NAME

  removeContainer $CONTAINER_NAME
}

function notifyOrgAboutNewChannel() {
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

  if [ ! -z "$ANCHOR_PEER_UPDATE_PATH" ]; then
    docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
      $CLI_NAME peer channel update \
      -c $CHANNEL_NAME \
      -o $ORDERER_URL \
      -f $ANCHOR_PEER_UPDATE_PATH
  else
    echo "channel update tx not found! Looked for: $ANCHOR_PEER_UPDATE_PATH"
  fi
}

function notifyOrgAboutNewChannelTls() {
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

  if [ ! -z "$ANCHOR_PEER_UPDATE_PATH" ]; then
    docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
      $CLI_NAME peer channel update \
      -c $CHANNEL_NAME \
      -o $ORDERER_URL \
      -f $ANCHOR_PEER_UPDATE_PATH \
      --tls --cafile $CA_CERT
  else
    echo "channel update tx not found! Looked for: $ANCHOR_PEER_UPDATE_PATH"
  fi
}

function deleteNewChannelUpdateTx() {
  local CHANNEL_NAME=$1
  local MSP_NAME=$2
  local CLI_NAME=$3
  local ANCHOR_PEER_UPDATE_PATH="/var/hyperledger/cli/config/${MSP_NAME}anchors-$CHANNEL_NAME.tx"

  echo "Deleting new channel config block. Channel: $CHANNEL_NAME, Organization: $MSP_NAME"
  inputLogShort "CHANNEL_NAME: $CHANNEL_NAME, MSP_NAME: $MSP_NAME, CLI_NAME: $CLI_NAME, ANCHOR_PEER_UPDATE_PATH: $ANCHOR_PEER_UPDATE_PATH"

  if [ ! -z "$ANCHOR_PEER_UPDATE_PATH" ]; then
    docker exec $CLI_NAME rm $ANCHOR_PEER_UPDATE_PATH
  else
    echo "channel update tx not found! Looked for: $ANCHOR_PEER_UPDATE_PATH"
  fi
}

function chaincodeInstall() {
  local CHAINCODE_DIR_PATH=$1
  local CHAINCODE_NAME=$2
  local CHAINCODE_VERSION=$3
  local CHAINCODE_LANG=$4

  local CHANNEL_NAME=$5

  local PEER_ADDRESS=$6
  local ORDERER_URL=$7
  local CLI_NAME=$8

  local CHAINCODE_DIR_CONTENT=$(ls $CHAINCODE_DIR_PATH)

  echo "Installing chaincode on $CHANNEL_NAME..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"

  if [ ! -z "$CHAINCODE_DIR_CONTENT" ]; then
    docker exec -e CHANNEL_NAME=$CHANNEL_NAME -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
      $CLI_NAME peer chaincode install \
      -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -l $CHAINCODE_LANG -p /var/hyperledger/cli/$CHAINCODE_NAME/ \
      -o $ORDERER_URL
  else
    echo "Skipping chaincode '$CHAINCODE_NAME' installation. Chaincode's directory is empty."
  fi
}

function chaincodeInstantiate() {
  local CHAINCODE_DIR_PATH=$1
  local CHAINCODE_NAME=$2
  local CHAINCODE_VERSION=$3
  local CHAINCODE_LANG=$4
  local CHANNEL_NAME=$5
  local PEER_ADDRESS=$6
  local ORDERER_URL=$7
  local CLI_NAME=$8
  local INIT_PARAMS=$9
  local ENDORSEMENT=${10}

  local CHAINCODE_DIR_CONTENT=$(ls $CHAINCODE_DIR_PATH)

  echo "Instantiating chaincode on $CHANNEL_NAME..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"

  if [ ! -z "$CHAINCODE_DIR_CONTENT" ]; then
    docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS $CLI_NAME peer chaincode instantiate \
      -C $CHANNEL_NAME \
      -n $CHAINCODE_NAME \
      -v $CHAINCODE_VERSION \
      -l $CHAINCODE_LANG \
      -o $ORDERER_URL \
      -c "$INIT_PARAMS" \
      -P "$ENDORSEMENT"
  else
    echo "Skipping chaincode '$CHAINCODE_NAME' instantiate. Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function chaincodeUpgrade() {
  local CHAINCODE_DIR_PATH=$1
  local CHAINCODE_NAME=$2
  local CHAINCODE_VERSION=$3
  local CHAINCODE_LANG=$4
  local CHANNEL_NAME=$5
  local PEER_ADDRESS=$6
  local ORDERER_URL=$7
  local CLI_NAME=$8
  local INIT_PARAMS=$9
  local ENDORSEMENT=${10}

  local CHAINCODE_DIR_CONTENT=$(ls "$CHAINCODE_DIR_PATH")

  echo "Upgrading chaincode on $CHANNEL_NAME..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"

  if [ -n "$CHAINCODE_DIR_CONTENT" ]; then
    docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS $CLI_NAME peer chaincode upgrade \
      -C "$CHANNEL_NAME" \
      -n "$CHAINCODE_NAME" \
      -v "$CHAINCODE_VERSION" \
      -l "$CHAINCODE_LANG" \
      -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
      -o "$ORDERER_URL" \
      -c "$INIT_PARAMS" \
      -P "$ENDORSEMENT"
  else
    echo "Skipping chaincode '$CHAINCODE_NAME' instantiate. Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function chaincodeInstallTls() {
  local CHAINCODE_DIR_PATH=$1
  local CHAINCODE_NAME=$2
  local CHAINCODE_VERSION=$3
  local CHAINCODE_LANG=$4
  local CHANNEL_NAME=$5
  local PEER_ADDRESS=$6
  local ORDERER_URL=$7
  local CLI_NAME=$8
  local CA_CERT="/var/hyperledger/cli/"$9

  local CHAINCODE_DIR_CONTENT=$(ls $CHAINCODE_DIR_PATH)

  echo "Installing chaincode on $CHANNEL_NAME (TLS)..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CA_CERT: $CA_CERT"

  if [ ! -z "$CHAINCODE_DIR_CONTENT" ]; then
    docker exec -e CHANNEL_NAME=$CHANNEL_NAME -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
      $CLI_NAME peer chaincode install \
      -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -l $CHAINCODE_LANG -p /var/hyperledger/cli/$CHAINCODE_NAME/ \
      -o $ORDERER_URL --tls --cafile $CA_CERT
  else
    echo "Skipping chaincode '$CHAINCODE_NAME' installation (TLS). Chaincode's directory is empty."
  fi
}

function chaincodeInstantiateTls() {
  local CHAINCODE_DIR_PATH=$1
  local CHAINCODE_NAME=$2
  local CHAINCODE_VERSION=$3
  local CHAINCODE_LANG=$4
  local CHANNEL_NAME=$5
  local PEER_ADDRESS=$6
  local ORDERER_URL=$7
  local CLI_NAME=$8
  local INIT_PARAMS=$9
  local ENDORSEMENT=${10}
  local CA_CERT="/var/hyperledger/cli/"${11}

  local CHAINCODE_DIR_CONTENT=$(ls $CHAINCODE_DIR_PATH)

  echo "Instantiating chaincode on $CHANNEL_NAME (TLS)..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CA_CERT: $CA_CERT"

  if [ ! -z "$CHAINCODE_DIR_CONTENT" ]; then
    docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS $CLI_NAME peer chaincode instantiate \
      -C $CHANNEL_NAME \
      -n $CHAINCODE_NAME \
      -v $CHAINCODE_VERSION \
      -l $CHAINCODE_LANG \
      -o $ORDERER_URL \
      -c "$INIT_PARAMS" \
      -P "$ENDORSEMENT" \
      --tls \
      --cafile $CA_CERT
  else
    echo "Skipping chaincode '$CHAINCODE_NAME' instantiate (TLS). Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function chaincodeUpgradeTls() {
  local CHAINCODE_DIR_PATH=$1
  local CHAINCODE_NAME=$2
  local CHAINCODE_VERSION=$3
  local CHAINCODE_LANG=$4
  local CHANNEL_NAME=$5
  local PEER_ADDRESS=$6
  local ORDERER_URL=$7
  local CLI_NAME=$8
  local INIT_PARAMS=$9
  local ENDORSEMENT=${10}
  local CA_CERT="/var/hyperledger/cli/"${11}

  local CHAINCODE_DIR_CONTENT=$(ls $CHAINCODE_DIR_PATH)

  echo "Upgrading chaincode on $CHANNEL_NAME (TLS)..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CA_CERT: $CA_CERT"

  if [ ! -z "$CHAINCODE_DIR_CONTENT" ]; then
    docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS $CLI_NAME peer chaincode upgrade \
      -C $CHANNEL_NAME \
      -n $CHAINCODE_NAME \
      -v $CHAINCODE_VERSION \
      -l $CHAINCODE_LANG \
      -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
      -o $ORDERER_URL \
      -c "$INIT_PARAMS" \
      -P "$ENDORSEMENT" \
      --tls \
      --cafile $CA_CERT
  else
    echo "Skipping chaincode '$CHAINCODE_NAME' instantiate (TLS). Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function printHeadline() {
  bold=$'\e[1m'
  end=$'\e[0m'

  TEXT=$1
  EMOJI=$2
  printf "${bold}============ %b %s %b ==============${end}\n" "\\$EMOJI" "$TEXT" "\\$EMOJI"
}

function printItalics() {
  italics=$'\e[3m'
  end=$'\e[0m'

  TEXT=$1
  EMOJI=$2
  printf "${italics}==== %b %s %b ====${end}\n" "\\$EMOJI" "$TEXT" "\\$EMOJI"
}

function inputLog() {
  end=$'\e[0m'
  darkGray=$'\e[90m'

  echo "${darkGray}   $1 ${end}"
}

function inputLogShort() {
  end=$'\e[0m'
  darkGray=$'\e[90m'

  echo "${darkGray}   $1 ${end}"
}

function certsRemove() {
  local CERTS_DIR_PATH=$1
  rm -rf "$CERTS_DIR_PATH"/*
}

function removeContainer() {
  CONTAINER_NAME=$1
  docker rm -f "$CONTAINER_NAME"
}
