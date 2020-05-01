function certsRemove() {
  local CERTS_DIR_PATH=$1
  rm -rf "$CERTS_DIR_PATH"/*
}

function certsGenerate() {
  local CONTAINER_NAME=certsGenerate

  local CONFIG_PATH=$1
  local CRYPTO_CONFIG_FILE_NAME=$2
  local ORG_PATH=$3
  local OUTPUT_PATH=$4
  local FULL_CERT_PATH=$OUTPUT_PATH$ORG_PATH

  if [ -d "$FULL_CERT_PATH" ]; then
    printf "\U1F910 \n"
    echo "  Error: Won't genere certs, directory already exists : $FULL_CERT_PATH"
    echo "  Looks like network is already prepared. Try using 'start' or 'rerun'."
    printf "\U1F912 \n"
    exit 1
  fi

  docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -i $CONTAINER_NAME cryptogen generate --config=./fabric-config/$CRYPTO_CONFIG_FILE_NAME

  docker cp $CONTAINER_NAME:/crypto-config/. $OUTPUT_PATH
  docker rm -f $CONTAINER_NAME

  for file in $(find $OUTPUT_PATH/ -iname *_sk); do dir=$(dirname $file); mv ${dir}/*_sk ${dir}/priv-key.pem; done
}

function genesisBlockCreate() {
  local CONTAINER_NAME=genesisBlockCreate

  local CONFIG_PATH=$1
  local OUTPUT_PATH=$2

    if [ -d "$OUTPUT_PATH" ]; then
    printf "\U1F910 \n"
    echo "  Error: Won't generate genesis block, directory already exists : $OUTPUT_PATH"
    echo "  Looks like network is already prepared. Try using 'start' or 'rerun'."
    printf "\U1F912 \n"
    exit 1
  fi

  docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -i $CONTAINER_NAME mkdir /config
  docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile SoloOrdererGenesis -outputBlock ./config/genesis.block

  docker cp $CONTAINER_NAME:/config $OUTPUT_PATH
  docker rm -f $CONTAINER_NAME
}

function createChannelTx() {
  local CONTAINER_NAME=createChannelTx

  local CHANNEL_NAME=$1
  local CONFIG_PATH=$2
  local CONFIG_PROFILE=$3
  local OUTPUT_PATH=$4
  local CHANNEL_TX_PATH=$OUTPUT_PATH"/"$CHANNEL_NAME".tx"

  if [ -f "$CHANNEL_TX_PATH" ]; then
    printf "\U1F910 \n"
    echo "  Error: Won't create channel configuration, it already exists : $CHANNEL_TX_PATH"
    echo "  Looks like network is already prepared. Try using 'start' or 'rerun'."
    printf "\U1F912 \n"
    exit 1
  fi

  docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -i $CONTAINER_NAME mkdir /config
  docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile ${CONFIG_PROFILE} -outputCreateChannelTx ./config/channel.tx -channelID ${CHANNEL_NAME}

  docker cp $CONTAINER_NAME:/config/channel.tx $CHANNEL_TX_PATH
  docker rm -f $CONTAINER_NAME
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
    printf "\U1F910 \n"
    echo "  Error: Won't create anchor peer update, it already exists : $ANCHOR_PEER_UPDATE_PATH"
    echo "  Looks like network is already prepared. Try using 'start' or 'rerun'."
    printf "\U1F912 \n"
    exit 1
  fi

  docker run -i -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -i $CONTAINER_NAME mkdir /config
  docker exec -i $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile ${CONFIG_PROFILE} -outputAnchorPeersUpdate ./config/${MSP}anchors.tx -channelID ${CHANNEL_NAME} -asOrg ${MSP}

  docker cp $CONTAINER_NAME:/config/${MSP}anchors.tx $ANCHOR_PEER_UPDATE_PATH
  docker rm -f $CONTAINER_NAME
}

function chaincodeInstall() {
  local CHAINCODE_DIR_PATH=$(pwd)"/"$1
  local CHAINCODE_NAME=$2
  local CHAINCODE_VERSION=$3
  local CHAINCODE_LANG=$4

  local CHANNEL_NAME=$5

  local PEER_ADDRESS=$6
  local ORDERER_URL=$7
  local CLI_NAME=$8

  local CHAINCODE_DIR_CONTENT=$(ls $CHAINCODE_DIR_PATH)

  echo "Installing chaincode on $CHANNEL_NAME..."
  echo "   CHAINCODE_NAME: $CHAINCODE_NAME"
  echo "   CHAINCODE_VERSION: $CHAINCODE_VERSION"
  echo "   CHAINCODE_LANG: $CHAINCODE_LANG"
  echo "   CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  echo ""
  echo "   PEER_ADDRESS: $PEER_ADDRESS"
  echo "   ORDERER_URL: $ORDERER_URL"
  echo "   CLI_NAME: $CLI_NAME"

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
  local CHAINCODE_DIR_PATH=$(pwd)"/"$1
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

  echo "Installing chaincode on $CHANNEL_NAME..."
  echo "   CHAINCODE_NAME: $CHAINCODE_NAME"
  echo "   CHAINCODE_VERSION: $CHAINCODE_VERSION"
  echo "   CHAINCODE_LANG: $CHAINCODE_LANG"
  echo "   CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  echo ""
  echo "   INIT_PARAMS: $INIT_PARAMS"
  echo "   ENDORSEMENT: $ENDORSEMENT"
  echo ""
  echo "   PEER_ADDRESS: $PEER_ADDRESS"
  echo "   ORDERER_URL: $ORDERER_URL"
  echo "   CLI_NAME: $CLI_NAME"

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
  local CHAINCODE_DIR_PATH=$(pwd)"/"$1
  local CHAINCODE_NAME=$2
  local CHAINCODE_VERSION=$3
  local CHAINCODE_LANG=$4

  local CHANNEL_NAME=$5

  local PEER_ADDRESS=$6
  local ORDERER_URL=$7
  local CLI_NAME=$8
  local CA_CERT=$9

  docker exec -e CHANNEL_NAME=$CHANNEL_NAME -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
    $CLI_NAME peer chaincode install \
    -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -l $CHAINCODE_LANG -p /var/hyperledger/cli/$CHAINCODE_NAME/ \
    -o $ORDERER_URL --tls --cafile $CA_CERT
}
