#!/usr/bin/env bash

function chaincodeBuild() {
  local CHAINCODE_NAME=$1
  local CHAINCODE_LANG=$2
  local CHAINCODE_DIR_PATH=$3

  mkdir -p "$CHAINCODE_DIR_PATH"

  if [ "$CHAINCODE_LANG" = "node" ]; then
    if [ -z "$(ls "$CHAINCODE_DIR_PATH")" ]; then
      echo "Skipping chaincode '$CHAINCODE_NAME' build. Directory '$CHAINCODE_DIR_PATH' is empty."
    else
      # We need to adjust Node.js version to Fabric Shim version, see:
      # https://github.com/hyperledger/fabric-chaincode-node/blob/main/COMPATIBILITY.md
      NODE_VERSION="12"
      COMMAND="npm install && npm run build"

      USES_OLD_FABRIC_SHIM="$(jq '.dependencies."fabric-shim" | contains("1.4.")' "$CHAINCODE_DIR_PATH/package.json")"
      if [ "$USES_OLD_FABRIC_SHIM" == "true" ]; then
        NODE_VERSION="8.9"
      fi

      if [ -f "$CHAINCODE_DIR_PATH/yarn.lock" ]; then
        COMMAND="npm install -g yarn && yarn install && yarn build"
      fi

      echo "Buiding chaincode '$CHAINCODE_NAME'..."
      inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
      inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
      inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
      inputLog "NODE_VERSION: $NODE_VERSION"

      docker run --rm -v "$CHAINCODE_DIR_PATH:/chaincode" -w /chaincode "node:$NODE_VERSION" sh -c "$COMMAND"
    fi
  fi
}

function chaincodeInstall() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3

  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local CHAINCODE_DIR_PATH=$7

  local ORDERER_URL=$8

  local CA_CERT
  local CA_CERT_PARAMS

  if [ -n "$9" ]; then
    CA_CERT="/var/hyperledger/cli/$9"
    CA_CERT_PARAMS=(--tls --cafile "$CA_CERT")
  else
    CA_CERT="<none>"
    CA_CERT_PARAMS=()
  fi

  echo "Installing chaincode on $CHANNEL_NAME..."
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
      "${CA_CERT_PARAMS[@]}"
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' installation (TLS). Chaincode's directory is empty."
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

  local CA_CERT
  local CA_CERT_PARAMS

  if [ -n "${11}" ]; then
    CA_CERT="/var/hyperledger/cli/${11}"
    CA_CERT_PARAMS=(--tls --cafile "$CA_CERT")
  else
    CA_CERT="<none>"
    CA_CERT_PARAMS=()
  fi

  local COLLECTIONS_CONFIG
  local COLLECTIONS_CONFIG_PARAMS

  if [ -n "${12}" ]; then
    COLLECTIONS_CONFIG="/var/hyperledger/cli/${12}"
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  else
    COLLECTIONS_CONFIG="<none>"
    COLLECTIONS_CONFIG_PARAMS=()
  fi

  echo "Instantiating chaincode on $CHANNEL_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CA_CERT: $CA_CERT"

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode instantiate \
      -C "$CHANNEL_NAME" \
      -n "$CHAINCODE_NAME" \
      -v "$CHAINCODE_VERSION" \
      -l "$CHAINCODE_LANG" \
      -o "$ORDERER_URL" \
      -c "$INIT_PARAMS" \
      -P "$ENDORSEMENT" \
      "${COLLECTIONS_CONFIG_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
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

  local CA_CERT
  local CA_CERT_PARAMS

  if [ -n "${11}" ]; then
    CA_CERT="/var/hyperledger/cli/${11}"
    CA_CERT_PARAMS=(--tls --cafile "$CA_CERT")
  else
    CA_CERT="<none>"
    CA_CERT_PARAMS=()
  fi

  local COLLECTIONS_CONFIG
  local COLLECTIONS_CONFIG_PARAMS

  if [ -n "${12}" ]; then
    COLLECTIONS_CONFIG="/var/hyperledger/cli/${12}"
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  else
    COLLECTIONS_CONFIG="<none>"
    COLLECTIONS_CONFIG_PARAMS=()
  fi

  echo "Upgrading chaincode on $CHANNEL_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"
  inputLog "INIT_PARAMS: $INIT_PARAMS"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CA_CERT: $CA_CERT"

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode upgrade \
      -C "$CHANNEL_NAME" \
      -n "$CHAINCODE_NAME" \
      -v "$CHAINCODE_VERSION" \
      -l "$CHAINCODE_LANG" \
      -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
      -o "$ORDERER_URL" \
      -c "$INIT_PARAMS" \
      -P "$ENDORSEMENT" \
      "${COLLECTIONS_CONFIG_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' instantiate. Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}
