function peerChannelList() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2

  echo "Listing channels using $CLI_NAME using peer $PEER_ADDRESS..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS $CLI_NAME peer channel list
}

function peerChannelListDefault() {
  local CLI_NAME=$1

  echo "Listing channels using $CLI_NAME using default cli's peer"
  inputLog "CLI_NAME: $CLI_NAME"

  docker exec $CLI_NAME peer channel list
}

function peerChannelGetInfo() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local PEER_ADDRESS=$3

  echo "Getting info about $CHANNEL_NAME using peer $PEER_ADDRESS..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS $CLI_NAME peer channel getinfo \
    -c $CHANNEL_NAME
}

function peerChannelGetInfoDefault() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2

  echo "Getting info about $CHANNEL_NAME using default cli's peer..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"

  docker exec $CLI_NAME peer channel getinfo \
    -c $CHANNEL_NAME
}

function peerChannelFetchConfig() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local CONFIG_FILE_NAME=$3
  local PEER_ADDRESS=$4

  echo "Fetching config block from $CHANNEL_NAME using peer $PEER_ADDRESS..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CONFIG_FILE_NAME: $CONFIG_FILE_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec $CLI_NAME mkdir -p /tmp/hyperledger/assets/
  docker exec \
    -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
    $CLI_NAME peer channel fetch config /tmp/hyperledger/assets/config_block_before.pb \
    -c $CHANNEL_NAME

  docker exec $CLI_NAME chmod 777 /tmp/hyperledger/assets/config_block_before.pb
  docker exec \
    -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
    $CLI_NAME configtxlator proto_decode \
    --input /tmp/hyperledger/assets/config_block_before.pb \
    --type common.Block | \
    jq .data.data[0].payload.data.config > $CONFIG_FILE_NAME

  docker exec $CLI_NAME rm -rf /tmp/hyperledger/assets/
}

function peerChannelFetchConfigDefault() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local CONFIG_FILE_NAME=$3

  echo "Fetching config block from $CHANNEL_NAME using default cli's peer..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CONFIG_FILE_NAME: $CONFIG_FILE_NAME"

  docker exec $CLI_NAME mkdir -p /tmp/hyperledger/assets/
  docker exec \
    $CLI_NAME peer channel fetch config /tmp/hyperledger/assets/config_block_before.pb \
    -c $CHANNEL_NAME

  docker exec $CLI_NAME chmod 777 /tmp/hyperledger/assets/config_block_before.pb
  docker exec $CLI_NAME configtxlator proto_decode \
    --input /tmp/hyperledger/assets/config_block_before.pb \
    --type common.Block | \
    jq .data.data[0].payload.data.config > $CONFIG_FILE_NAME

  docker exec $CLI_NAME rm -rf /tmp/hyperledger/assets/
}

function peerChannelFetchLastBlock() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local BLOCK_FILE_NAME=$3
  local PEER_ADDRESS=$4

  echo "Fetching last block from $CHANNEL_NAME using peer $PEER_ADDRESS..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_FILE_NAME: $BLOCK_FILE_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec $CLI_NAME mkdir -p /tmp/hyperledger/blocks/
  docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
    $CLI_NAME peer channel fetch newest /tmp/hyperledger/blocks/newest.block \
    -c $CHANNEL_NAME
  docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
    $CLI_NAME configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/newest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > $BLOCK_FILE_NAME

  docker exec $CLI_NAME rm -rf /tmp/hyperledger/assets/
}

function peerChannelFetchLastBlockDefault() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local BLOCK_FILE_NAME=$3

  echo "Fetching last block from $CHANNEL_NAME using default cli's peer..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_FILE_NAME: $BLOCK_FILE_NAME"

  docker exec $CLI_NAME mkdir -p /tmp/hyperledger/blocks/
  docker exec \
    $CLI_NAME peer channel fetch newest /tmp/hyperledger/blocks/newest.block \
    -c $CHANNEL_NAME
  docker exec $CLI_NAME configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/newest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > $BLOCK_FILE_NAME

  docker exec $CLI_NAME rm -rf /tmp/hyperledger/assets/
}

function peerChannelFetchFirstBlock() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local BLOCK_FILE_NAME=$3
  local PEER_ADDRESS=$4

  echo "Fetching first block from $CHANNEL_NAME using peer $PEER_ADDRESS..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_FILE_NAME: $BLOCK_FILE_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec $CLI_NAME mkdir -p /tmp/hyperledger/blocks/
  docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
    $CLI_NAME peer channel fetch oldest /tmp/hyperledger/blocks/oldest.block \
    -c $CHANNEL_NAME
  docker exec -e CORE_PEER_ADDRESS=$PEER_ADDRESS \
    $CLI_NAME configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/oldest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > $BLOCK_FILE_NAME

  docker exec $CLI_NAME rm -rf /tmp/hyperledger/assets/
}

function peerChannelFetchFirstBlockDefault() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local BLOCK_FILE_NAME=$3

  echo "Fetching first block from $CHANNEL_NAME using default cli's peer..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_FILE_NAME: $BLOCK_FILE_NAME"

  docker exec $CLI_NAME mkdir -p /tmp/hyperledger/blocks/
  docker exec \
    $CLI_NAME peer channel fetch oldest /tmp/hyperledger/blocks/oldest.block \
    -c $CHANNEL_NAME
  docker exec $CLI_NAME configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/oldest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > $BLOCK_FILE_NAME

  docker exec $CLI_NAME rm -rf /tmp/hyperledger/assets/
}
