#!/usr/bin/env bash

function chaincodeInstall() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3

  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local CHAINCODE_DIR_PATH=$7

  local ORDERER_URL=$8

  echo "Installing chaincode on $CHANNEL_NAME..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    docker exec -e CHANNEL_NAME="$CHANNEL_NAME" -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
      "$CLI_NAME" peer chaincode install \
      -n "$CHAINCODE_NAME" \
      -v "$CHAINCODE_VERSION" \
      -l "$CHAINCODE_LANG" \
      -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
      -o "$ORDERER_URL"
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' installation. Chaincode's directory is empty."
  fi
}

function chaincodeInstantiate() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3

  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local CHAINCODE_DIR_PATH=$7

  local ORDERER_URL=$8

  local INIT_PARAMS=$9
  local ENDORSEMENT=${10}
  local ADD_COLLECTIONS_CONFIG=${11}
  local COLLECTIONS_CONFIG="/var/hyperledger/cli/collections/$CHAINCODE_NAME.json"

  echo "Instantiating chaincode on $CHANNEL_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "ADD_COLLECTIONS_CONFIG: $ADD_COLLECTIONS_CONFIG"

  if [ "$ADD_COLLECTIONS_CONFIG" == true ]; then
    inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"
  fi

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    if [ "$ADD_COLLECTIONS_CONFIG" == true ]; then
      docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode instantiate \
        -C "$CHANNEL_NAME" \
        -n "$CHAINCODE_NAME" \
        -v "$CHAINCODE_VERSION" \
        -l "$CHAINCODE_LANG" \
        -o "$ORDERER_URL" \
        -c "$INIT_PARAMS" \
        -P "$ENDORSEMENT" \
        --collections-config "$COLLECTIONS_CONFIG"
    else
      docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode instantiate \
        -C "$CHANNEL_NAME" \
        -n "$CHAINCODE_NAME" \
        -v "$CHAINCODE_VERSION" \
        -l "$CHAINCODE_LANG" \
        -o "$ORDERER_URL" \
        -c "$INIT_PARAMS" \
        -P "$ENDORSEMENT"
    fi
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' instantiate. Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function chaincodeUpgrade() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3

  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local CHAINCODE_DIR_PATH=$7

  local ORDERER_URL=$8

  local INIT_PARAMS=$9
  local ENDORSEMENT=${10}

  local ADD_COLLECTIONS_CONFIG=${11}
  local COLLECTIONS_CONFIG="/var/hyperledger/cli/collections/$CHAINCODE_NAME.json"

  echo "Upgrading chaincode on $CHANNEL_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "ADD_COLLECTIONS_CONFIG: $ADD_COLLECTIONS_CONFIG"

  if [ "$ADD_COLLECTIONS_CONFIG" == true ]; then
    inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"
  fi

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    if [ "$ADD_COLLECTIONS_CONFIG" == true ]; then
      docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode upgrade \
        -C "$CHANNEL_NAME" \
        -n "$CHAINCODE_NAME" \
        -v "$CHAINCODE_VERSION" \
        -l "$CHAINCODE_LANG" \
        -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
        -o "$ORDERER_URL" \
        -c "$INIT_PARAMS" \
        -P "$ENDORSEMENT" \
        --collections-config "$COLLECTIONS_CONFIG"
    else
      docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode upgrade \
        -C "$CHANNEL_NAME" \
        -n "$CHAINCODE_NAME" \
        -v "$CHAINCODE_VERSION" \
        -l "$CHAINCODE_LANG" \
        -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
        -o "$ORDERER_URL" \
        -c "$INIT_PARAMS" \
        -P "$ENDORSEMENT"
    fi
  else
    echo "Skipping chaincode '$CHAINCODE_NAME' instantiate. Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function chaincodeInstallTls() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3

  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local CHAINCODE_DIR_PATH=$7

  local ORDERER_URL=$8
  local CA_CERT="/var/hyperledger/cli/$9"

  echo "Installing chaincode on $CHANNEL_NAME (TLS)..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CA_CERT: $CA_CERT"

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    docker exec -e CHANNEL_NAME="$CHANNEL_NAME" -e CORE_PEER_ADDRESS="$PEER_ADDRESS" \
      "$CLI_NAME" peer chaincode install \
      -n "$CHAINCODE_NAME" \
      -v "$CHAINCODE_VERSION" \
      -l "$CHAINCODE_LANG" \
      -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
      -o "$ORDERER_URL" \
      --tls \
      --cafile "$CA_CERT"
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' installation (TLS). Chaincode's directory is empty."
  fi
}

function chaincodeInstantiateTls() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3

  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local CHAINCODE_DIR_PATH=$7

  local ORDERER_URL=$8

  local INIT_PARAMS=$9
  local ENDORSEMENT=${10}

  local ADD_COLLECTIONS_CONFIG=${11}
  local COLLECTIONS_CONFIG="/var/hyperledger/cli/collections/$CHAINCODE_NAME.json"

  local CA_CERT="/var/hyperledger/cli/${12}"

  echo "Instantiating chaincode on $CHANNEL_NAME (TLS)..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "ADD_COLLECTIONS_CONFIG: $ADD_COLLECTIONS_CONFIG"
  inputLog "CA_CERT: $CA_CERT"

  if [ "$ADD_COLLECTIONS_CONFIG" == true ]; then
    inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"
  fi

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    if [ "$ADD_COLLECTIONS_CONFIG" == true ]; then
      docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode instantiate \
        -C "$CHANNEL_NAME" \
        -n "$CHAINCODE_NAME" \
        -v "$CHAINCODE_VERSION" \
        -l "$CHAINCODE_LANG" \
        -o "$ORDERER_URL" \
        -c "$INIT_PARAMS" \
        -P "$ENDORSEMENT" \
        --collections-config "$COLLECTIONS_CONFIG" \
        --tls \
        --cafile "$CA_CERT"
    else
      docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode instantiate \
        -C "$CHANNEL_NAME" \
        -n "$CHAINCODE_NAME" \
        -v "$CHAINCODE_VERSION" \
        -l "$CHAINCODE_LANG" \
        -o "$ORDERER_URL" \
        -c "$INIT_PARAMS" \
        -P "$ENDORSEMENT" \
        --tls \
        --cafile "$CA_CERT"
    fi
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' instantiate (TLS). Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function chaincodeUpgradeTls() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3

  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local CHAINCODE_DIR_PATH=$7

  local ORDERER_URL=$8
  local INIT_PARAMS=$9

  local ENDORSEMENT=${10}

  local ADD_COLLECTIONS_CONFIG=${11}
  local COLLECTIONS_CONFIG="/var/hyperledger/cli/collections/$CHAINCODE_NAME.json"

  local CA_CERT="/var/hyperledger/cli/"${12}

  echo "Upgrading chaincode on $CHANNEL_NAME (TLS)..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "ADD_COLLECTIONS_CONFIG: $ADD_COLLECTIONS_CONFIG"
  inputLog "CA_CERT: $CA_CERT"

  if [ "$ADD_COLLECTIONS_CONFIG" == true ]; then
    inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"
  fi

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    if [ "$ADD_COLLECTIONS_CONFIG" == true ]; then
      docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode upgrade \
        -C "$CHANNEL_NAME" \
        -n "$CHAINCODE_NAME" \
        -v "$CHAINCODE_VERSION" \
        -l "$CHAINCODE_LANG" \
        -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
        -o "$ORDERER_URL" \
        -c "$INIT_PARAMS" \
        -P "$ENDORSEMENT" \
        --collections-config "$COLLECTIONS_CONFIG" \
        --tls \
        --cafile "$CA_CERT"
    else
      docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode upgrade \
        -C "$CHANNEL_NAME" \
        -n "$CHAINCODE_NAME" \
        -v "$CHAINCODE_VERSION" \
        -l "$CHAINCODE_LANG" \
        -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
        -o "$ORDERER_URL" \
        -c "$INIT_PARAMS" \
        -P "$ENDORSEMENT" \
        --tls \
        --cafile "$CA_CERT"
    fi
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' instantiate (TLS). Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}
