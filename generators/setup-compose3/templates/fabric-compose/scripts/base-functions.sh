function certsRemove() {
  local CERTS_DIR_PATH=$1
  rm -rf "$CERTS_DIR_PATH"/*
}

function certsGenerate() {
  local CONTAINER_NAME=certsGenerate

  local CONFIG_PATH=$1
  local OUTPUT_PATH=$2

  if [ -d "$OUTPUT_PATH" ]; then
    printf "\U1F910 \n"
    echo "  Error: Won't genere certs, directory already exists : $OUTPUT_PATH"
    echo "  Looks like network is already prepared. Try using 'start' or 'rerun'."
    printf "\U1F912 \n"
    exit 1
  fi

  echo "=== Generating crypto material (base-functions) ==="

  docker run -it -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -it $CONTAINER_NAME cryptogen generate --config=./fabric-config/crypto-config.yaml

  docker cp $CONTAINER_NAME:/crypto-config $OUTPUT_PATH
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

  echo "=== Generating genesis block (base-functions) ==="

  docker run -it -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -it $CONTAINER_NAME mkdir /config
  docker exec -it $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile SoloOrdererGenesis -outputBlock ./config/genesis.block

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

  docker run -it -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -it $CONTAINER_NAME mkdir /config
  docker exec -it $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile ${CONFIG_PROFILE} -outputCreateChannelTx ./config/channel.tx -channelID ${CHANNEL_NAME}

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

  docker run -it -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -it $CONTAINER_NAME mkdir /config
  docker exec -it $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile ${CONFIG_PROFILE} -outputAnchorPeersUpdate ./config/${MSP}anchors.tx -channelID ${CHANNEL_NAME} -asOrg ${MSP}

  docker cp $CONTAINER_NAME:/config/${MSP}anchors.tx $ANCHOR_PEER_UPDATE_PATH
  docker rm -f $CONTAINER_NAME
}

function chaincodeInstall() {
  local CHAINCODE_NAME=$1
  local CHAINCODE_VERSION=$2
  local CHAINCODE_LANG=$3

  local CHANNEL_NAME=$4

  local PEER_ADDRESS=$5
  local ORDERER_URL=$6
  local CLI_NAME=$7

  local CHAINCODE_DIR_PATH=$(realpath $CHAINCODE_NAME)

  if [ -d "$CHAINCODE_DIR_PATH" ]; then
    echo "Installing chaincode '$CHAINCODE_NAME' from directory '$CHAINCODE_DIR_PATH' on '$CHANNEL_NAME'"
    docker exec -e CHANNEL_NAME=$CHANNEL_NAME -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
      $CLI_NAME peer chaincode install \
      -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -l $CHAINCODE_LANG -p /var/hyperledger/cli/$CHAINCODE_NAME/ \
      -o $ORDERER_URL
  else
    echo "Skipping chaincode '$CHAINCODE_NAME' installation. Chaincode's directory is empty."
    echo "Looked for dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function chaincodeInstantiate() {
  local CHAINCODE_NAME=$1
  local CHAINCODE_VERSION=$2
  local CHAINCODE_LANG=$3

  local CHANNEL_NAME=$4

  local PEER_ADDRESS=$5
  local ORDERER_URL=$6
  local CLI_NAME=$7

  local INIT_PARAMS=$8
  local ENDORSMENT=$9

  local CHAINCODE_DIR_PATH=$(realpath $CHAINCODE_NAME)

  if [ -d "$CHAINCODE_DIR_PATH" ]; then
    docker exec \
        -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
        $CLI_NAME peer chaincode instantiate \
        -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -l $CHAINCODE_LANG -c $INIT_PARAMS -C $CHANNEL_NAME -P $ENDORSMENT \
        -o $ORDERER_URL
        #--collections-config $COLLECTION_CONIFG_PATH \
        #--tls --cafile $TLS_CA_CERT_PATH
  else
    echo "No chaincode to instantiate"
  fi
}

function chaincodeInstallTls() {
  local CHAINCODE_NAME=$1
  local CHAINCODE_VERSION=$2
  local CHAINCODE_LANG=$3

  local CHANNEL_NAME=$4

  local PEER_ADDRESS=$5
  local ORDERER_URL=$6
  local CLI_NAME=$7
  local CA_CERT=$8

  docker exec -e CHANNEL_NAME=$CHANNEL_NAME -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
    $CLI_NAME peer chaincode install \
    -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -l $CHAINCODE_LANG -p /var/hyperledger/cli/$CHAINCODE_NAME/ \
    -o $ORDERER_URL --tls --cafile $CA_CERT

#  /tmp/hyperledger/$ORG1/admin/msp/tlscacerts/tls-ca-cert.pem

}
