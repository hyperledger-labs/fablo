import util/log
import util/tryCatch

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

  try {
    docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
    docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

    docker exec -i $CONTAINER_NAME cryptogen generate --config=./fabric-config/$CRYPTO_CONFIG_FILE_NAME

    docker cp $CONTAINER_NAME:/crypto-config/. $OUTPUT_PATH
  } catch {
    removeContainer $CONTAINER_NAME
  }

  removeContainer $CONTAINER_NAME
  for file in $(find $OUTPUT_PATH/ -iname *_sk); do dir=$(dirname $file); mv ${dir}/*_sk ${dir}/priv-key.pem; done
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

  try {
    docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
    docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

    docker exec -i $CONTAINER_NAME mkdir /config
    docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile OrdererGenesis -outputBlock ./config/genesis.block

    docker cp $CONTAINER_NAME:/config $OUTPUT_PATH
  } catch {
    removeContainer $CONTAINER_NAME
  }
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

  try {
    docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
    docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

    docker exec -i $CONTAINER_NAME mkdir /config
    docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile ${CONFIG_PROFILE} -outputCreateChannelTx ./config/channel.tx -channelID ${CHANNEL_NAME}

    docker cp $CONTAINER_NAME:/config/channel.tx $CHANNEL_TX_PATH
  } catch {
    removeContainer $CONTAINER_NAME
  }
  removeContainer $CONTAINER_NAME
}

function createAnchorPeerUpdateTx() {
  local CONTAINER_NAME=createAnchorPeerUpdateTx

  local CHANNEL_NAME=$1
  local CONFIG_PATH=$2
  local CONFIG_PROFILE=$3
  local OUTPUT_PATH=$4
  local MSP=$5
  local ANCHOR_PEER_UPDATE_PATH=$OUTPUT_PATH"/"$MSP"anchors.tx"

  if [ -f "$ANCHOR_PEER_UPDATE_PATH" ]; then
    echo "Cant't create anchor peer update, it already exists : $ANCHOR_PEER_UPDATE_PATH"
    echo "Try using 'recreate' or 'down' to remove whole network or 'start' to reuse it"
    exit 1
  fi

  try {
    docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
    docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

    docker exec -i $CONTAINER_NAME mkdir /config
    docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile ${CONFIG_PROFILE} -outputAnchorPeersUpdate ./config/${MSP}anchors.tx -channelID ${CHANNEL_NAME} -asOrg ${MSP}

    docker cp $CONTAINER_NAME:/config/${MSP}anchors.tx $ANCHOR_PEER_UPDATE_PATH
  } catch {
    removeContainer $CONTAINER_NAME
  }
  removeContainer $CONTAINER_NAME
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
    docker exec \
        -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
        $CLI_NAME peer chaincode instantiate \
        -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -l $CHAINCODE_LANG -c "$INIT_PARAMS" -C $CHANNEL_NAME -P "$ENDORSEMENT" \
        -o $ORDERER_URL
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
    docker exec \
        -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
        $CLI_NAME peer chaincode instantiate \
        -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -l $CHAINCODE_LANG -c "$INIT_PARAMS" -C $CHANNEL_NAME -P "$ENDORSEMENT" \
        -o $ORDERER_URL --tls --cafile $CA_CERT
  else
    echo "Skipping chaincode '$CHAINCODE_NAME' instantiate (TLS). Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function printHeadline() {
  TEXT=$1
  EMOJI=$2
  printf "$(UI.Color.Bold)============ %b %s %b ==============$(UI.Color.Default)\n" "\\$EMOJI" "$TEXT" "\\$EMOJI"
}

function printItalics() {
  TEXT=$1
  EMOJI=$2
  printf "$(UI.Color.Italics)==== %b %s %b ====$(UI.Color.Default)\n" "\\$EMOJI" "$TEXT" "\\$EMOJI"
}

function inputLog() {
  echo "$(UI.Color.DarkGray)   $1 $(UI.Color.Default)"
}

function certsRemove() {
  local CERTS_DIR_PATH=$1
  rm -rf "$CERTS_DIR_PATH"/*
}

function removeContainer() {
  CONTAINER_NAME=$1
  docker rm -f "$CONTAINER_NAME"
}
