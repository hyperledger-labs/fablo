#!/usr/bin/env bash

peerChannelList() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2

  echo "Listing channels using $CLI_NAME using peer $PEER_ADDRESS..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer channel list
}

peerChannelGetInfo() {
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

peerChannelFetchConfig() {
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

peerChannelFetchBlock() {
  local CHANNEL_NAME="$1"
  local CLI_NAME="$2"
  local BLOCK_NAME="$3"
  local PEER_ADDRESS="$4"
  local TARGET_FILE="$5"
  local TEMP_FILE="/tmp/hyperledger/blocks/$BLOCK_NAME.block"

  echo "Fetching block $BLOCK_NAME from $CHANNEL_NAME using peer $PEER_ADDRESS..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_NAME: $BLOCK_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "TARGET_FILE: $TARGET_FILE"

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/blocks/

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch "$BLOCK_NAME" "$TEMP_FILE" \
    -c "$CHANNEL_NAME"

  docker exec "$CLI_NAME" cat "$TEMP_FILE" > "$TARGET_FILE"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/blocks/
}

#=== TLS equivalents =========================================================

peerChannelListTls() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CA_CERT=$3

  echo "Listing channels using $CLI_NAME using peer $PEER_ADDRESS (TLS)..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer channel list --tls --cafile "$CA_CERT"
}

peerChannelGetInfoTls() {
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

peerChannelFetchConfigTls() {
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

peerChannelFetchBlockTls() {
  local CHANNEL_NAME="$1"
  local CLI_NAME="$2"
  local BLOCK_NAME="$3"
  local PEER_ADDRESS="$4"
  local CA_CERT="$5"
  local TARGET_FILE="$6"
  local TEMP_FILE="/tmp/hyperledger/blocks/$BLOCK_NAME.block"

  echo "Fetching block $BLOCK_NAME from $CHANNEL_NAME using peer $PEER_ADDRESS..."
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "BLOCK_NAME: $BLOCK_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "TARGET_FILE: $TARGET_FILE"

  docker exec "$CLI_NAME" mkdir -p /tmp/hyperledger/blocks/

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
    "$CLI_NAME" peer channel fetch "$BLOCK_NAME" "$TEMP_FILE" \
    -c "$CHANNEL_NAME" --tls --cafile "$CA_CERT"

  docker exec "$CLI_NAME" cat "$TEMP_FILE" > "$TARGET_FILE"

  docker exec "$CLI_NAME" rm -rf /tmp/hyperledger/blocks/
}
