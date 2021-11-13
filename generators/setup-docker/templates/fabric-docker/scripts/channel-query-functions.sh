#!/usr/bin/env bash

function peerChannelList() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2

  echo "Listing channels using $CLI_NAME using peer $PEER_ADDRESS..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer channel list
}

function peerChannelGetInfo() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local PEER_ADDRESS=$3

  echo "Getting info about $CHANNEL_NAME using peer $PEER_ADDRESS..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer channel getinfo \
    -c "$CHANNEL_NAME"
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

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/assets/
  docker exec \
    -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch config /tmp/hyperledger/assets/config_block_before.pb \
    -c "$CHANNEL_NAME"

  docker exec "$CLI_NAME" chmod 777 /tmp/hyperledger/assets/config_block_before.pb
  docker exec \
    -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" configtxlator proto_decode \
    --input /tmp/hyperledger/assets/config_block_before.pb \
    --type common.Block | \
    jq .data.data[0].payload.data.config > "$CONFIG_FILE_NAME"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/assets/
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

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/blocks/
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch newest /tmp/hyperledger/blocks/newest.block \
    -c "$CHANNEL_NAME"
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/newest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > "$BLOCK_FILE_NAME"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/assets/
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

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/blocks/
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch oldest /tmp/hyperledger/blocks/oldest.block \
    -c "$CHANNEL_NAME"
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/oldest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > "$BLOCK_FILE_NAME"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/assets/
}

function peerChannelFetchBlock() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local BLOCK_FILE_NAME=$3
  local BLOCK_NUMBER=$4
  local PEER_ADDRESS=$5

  echo "Fetching first block from $CHANNEL_NAME using peer $PEER_ADDRESS..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_FILE_NAME: $BLOCK_FILE_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/blocks/
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch oldest /tmp/hyperledger/blocks/oldest.block \
    -c "$CHANNEL_NAME"
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/oldest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > "$BLOCK_FILE_NAME"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/assets/
}

#=== TLS equivalents =========================================================

function peerChannelListTls() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CA_CERT=$3

  echo "Listing channels using $CLI_NAME using peer $PEER_ADDRESS (TLS)..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer channel list --tls --cafile "$CA_CERT"
}

function peerChannelGetInfoTls() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local PEER_ADDRESS=$3
  local CA_CERT=$4


  echo "Getting info about $CHANNEL_NAME using peer $PEER_ADDRESS (TLS)..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer channel getinfo \
    -c "$CHANNEL_NAME" --tls --cafile "$CA_CERT"
}

function peerChannelFetchConfigTls() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local CONFIG_FILE_NAME=$3
  local PEER_ADDRESS=$4
  local CA_CERT=$5

  echo "Fetching config block from $CHANNEL_NAME using peer $PEER_ADDRESS (TLS)..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CONFIG_FILE_NAME: $CONFIG_FILE_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/assets/
  docker exec \
    -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch config /tmp/hyperledger/assets/config_block_before.pb \
    -c "$CHANNEL_NAME" --tls --cafile "$CA_CERT"

  docker exec "$CLI_NAME" chmod 777 /tmp/hyperledger/assets/config_block_before.pb
  docker exec \
    -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" configtxlator proto_decode \
    --input /tmp/hyperledger/assets/config_block_before.pb \
    --type common.Block | \
    jq .data.data[0].payload.data.config > "$CONFIG_FILE_NAME"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/assets/
}

function peerChannelFetchLastBlockTls() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local BLOCK_FILE_NAME=$3
  local PEER_ADDRESS=$4
  local CA_CERT=$5

  echo "Fetching last block from $CHANNEL_NAME using peer $PEER_ADDRESS (TLS)..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_FILE_NAME: $BLOCK_FILE_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/blocks/
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch newest /tmp/hyperledger/blocks/newest.block \
    -c "$CHANNEL_NAME" --tls --cafile "$CA_CERT"
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/newest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > "$BLOCK_FILE_NAME"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/assets/
}

function peerChannelFetchFirstBlockTls() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local BLOCK_FILE_NAME=$3
  local PEER_ADDRESS=$4
  local CA_CERT=$5

  echo "Fetching first block from $CHANNEL_NAME using peer $PEER_ADDRESS (TLS)..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_FILE_NAME: $BLOCK_FILE_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/blocks/
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch oldest /tmp/hyperledger/blocks/oldest.block \
    -c "$CHANNEL_NAME" --tls --cafile "$CA_CERT"
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/oldest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > "$BLOCK_FILE_NAME"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/assets/1
}

function peerChannelFetchBlockTls() {
  local CHANNEL_NAME=$1
  local CLI_NAME=$2
  local BLOCK_FILE_NAME=$3
  local BLOCK_NUMBER=$4
  local PEER_ADDRESS=$5

  echo "Fetching first block from $CHANNEL_NAME using peer $PEER_ADDRESS..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_FILE_NAME: $BLOCK_FILE_NAME"
  inputLog "BLOCK_NUMBER: $BLOCK_NUMBER"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/blocks/
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch oldest /tmp/hyperledger/blocks/oldest.block \
    -c "$CHANNEL_NAME" --tls --cafile "$CA_CERT"
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" configtxlator proto_decode \
    --input /tmp/hyperledger/blocks/oldest.block \
    --type common.Block | \
    jq .data.data[0].payload.data.config > "$BLOCK_FILE_NAME"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/assets/
}
