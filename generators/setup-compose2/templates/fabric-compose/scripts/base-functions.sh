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

  for file in $(find $OUTPUT_PATH/ -iname *_sk); do dir=$(dirname $file); mv ${dir}/*_sk ${dir}/key.pem; done
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
  local MSP=$5
  local CHANNEL_TX_PATH=$OUTPUT_PATH"/"$CHANNEL_NAME".tx"
  local ANCHOR_PEER_UPDATE_PATH=$OUTPUT_PATH"/"$MSP"anchors.tx"

  if [ -f "$CHANNEL_TX_PATH" ]; then
    printf "\U1F910 \n"
    echo "  Error: Won't channel configuration, it already exists : $OUTPUT_FILE"
    echo "  Looks like network is already prepared. Try using 'start' or 'rerun'."
    printf "\U1F912 \n"
    exit 1
  fi

  docker run -it -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -it $CONTAINER_NAME mkdir /config
  docker exec -it $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile ${CONFIG_PROFILE} -outputCreateChannelTx ./config/channel.tx -channelID ${CHANNEL_NAME}
  docker exec -it $CONTAINER_NAME configtxgen --configPath ./fabric-config -profile ${CONFIG_PROFILE} -outputAnchorPeersUpdate ./config/${MSP}anchors.tx -channelID ${CHANNEL_NAME} -asOrg ${MSP}

  docker cp $CONTAINER_NAME:/config/channel.tx $CHANNEL_TX_PATH
  docker cp $CONTAINER_NAME:/config/${MSP}anchors.tx $ANCHOR_PEER_UPDATE_PATH
  docker rm -f $CONTAINER_NAME
}

