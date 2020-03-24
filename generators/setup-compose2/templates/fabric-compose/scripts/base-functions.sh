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

  for file in $(find $OUTPUT_PATH/ -iname *_sk); do dir=$(dirname $file); mv ${dir}/*_sk ${dir}/private-key.pem; done
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
