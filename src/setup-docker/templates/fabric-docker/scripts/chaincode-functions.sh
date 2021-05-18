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
      NODE_VERSION="12"
      COMMAND="npm install && npm run build"

      USES_OLD_FABRIC_SHIM="$(jq '.dependencies."fabric-shim" | contains("1.4.")' "$CHAINCODE_DIR_PATH/package.json")"
      if [ "$USES_OLD_FABRIC_SHIM" == "true" ]; then
        NODE_VERSION="8"
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

function chaincodePackage() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHAINCODE_NAME=$3
  local CHAINCODE_LABEL=$4
  local CHAINCODE_LANG=$5
  local CHAINCODE_DIR_PATH=$6
  local ORDERER_URL=$7
  local CA_CERT=$8

  echo "Packaging chaincode $CHAINCODE_NAME..."
  inputLog "CHAINCODE_LABEL: $CHAINCODE_LABEL"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CA_CERT: $CA_CERT"

  local PEER_PARAMS=()
  read -r -a PEER_PARAMS <<<"--peerAddresses $(echo "$PEER_ADDRESS" | sed 's/,/ --peerAddresses /g')"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    read -r -a CA_CERT_PARAMS <<<"--tls --cafile /var/hyperledger/cli/$(echo "$CA_CERT_FILES" | sed 's/,/ --cafile \/var\/hyperledger\/cli\//g')"
  fi

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    docker exec "$CLI_NAME" peer lifecycle chaincode package \
      "/var/hyperledger/cli/$CHAINCODE_NAME/$CHAINCODE_LABEL.tar.gz" \
      --path "/var/hyperledger/cli/$CHAINCODE_NAME/" \
      --lang "$CHAINCODE_LANG" \
      --label "$CHAINCODE_LABEL" \
      "${PEER_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' packaging. Chaincode's directory is empty."
  fi
}

function chaincodeInstall() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHAINCODE_NAME=$3
  local CHAINCODE_LABEL=$4
  local ORDERER_URL=$5
  local CA_CERT=$6

  echo "Installing chaincode $CHAINCODE_NAME..."
  inputLog "CHAINCODE_LABEL: $CHAINCODE_LABEL"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CA_CERT: $CA_CERT"

  local PEER_PARAMS=()
  read -r -a PEER_PARAMS <<<"--peerAddresses $(echo "$PEER_ADDRESS" | sed 's/,/ --peerAddresses /g')"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    read -r -a CA_CERT_PARAMS <<<"--tls --cafile /var/hyperledger/cli/$(echo "$CA_CERT_FILES" | sed 's/,/ --cafile \/var\/hyperledger\/cli\//g')"
  fi

  docker exec "$CLI_NAME" peer lifecycle chaincode install \
    "/var/hyperledger/cli/$CHAINCODE_NAME/$CHAINCODE_LABEL.tar.gz" \
    "${PEER_PARAMS[@]}" \
    "${CA_CERT_PARAMS[@]}"
}

function chaincodeApprove() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME="$3"
  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LABEL=$6
  local ORDERER_URL=$7
  local ENDORSEMENT=$8
  local CA_CERT=$9
  local COLLECTIONS_CONFIG=${10}

  echo "Approving chaincode $CHAINCODE_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LABEL: $CHAINCODE_LABEL"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "CA_CERT: $CA_CERT"
  inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"

  local PEER_PARAMS=()
  read -r -a PEER_PARAMS <<<"--peerAddresses $(echo "$PEER_ADDRESS" | sed 's/,/ --peerAddresses /g')"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    read -r -a CA_CERT_PARAMS <<<"--tls --cafile /var/hyperledger/cli/$(echo "$CA_CERT_FILES" | sed 's/,/ --cafile \/var\/hyperledger\/cli\//g')"
  fi

  local COLLECTIONS_CONFIG_PARAMS=()
  if [ -n "$COLLECTIONS_CONFIG" ]; then
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  fi

  local QUERYINSTALLED_RESPONSE
  local CC_PACKAGE_ID

  QUERYINSTALLED_RESPONSE="$(
    docker exec "$CLI_NAME" peer lifecycle chaincode queryinstalled \
      "${PEER_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
  )"
  CC_PACKAGE_ID="$(echo "$QUERYINSTALLED_RESPONSE" | grep -E -o "$CHAINCODE_LABEL:[^,]+")"
  inputLog "CC_PACKAGE_ID: $CC_PACKAGE_ID"

  docker exec -e CC_PACKAGE_ID="$CC_PACKAGE_ID" "$CLI_NAME" peer lifecycle chaincode approveformyorg \
    -o "$ORDERER_URL" \
    -C "$CHANNEL_NAME" \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    --package-id "$CC_PACKAGE_ID" \
    --sequence 1 \
    --signature-policy "$ENDORSEMENT" \
    "${COLLECTIONS_CONFIG_PARAMS[@]}" \
    "${PEER_PARAMS[@]}" \
    "${CA_CERT_PARAMS[@]}"
  # ??? FIXME sequence
  # ??? --ordererTLSHostnameOverride orderer.example.com ???
  # TODO which methods require the organization admin role
  # TODO paths with tls certs are wrong?
}

function chaincodeCommit() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME="$3"
  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local ORDERER_URL=$6
  local ENDORSEMENT=$7
  local CA_CERT=$8
  local COLLECTIONS_CONFIG=$9

  echo "Committing chaincode $CHAINCODE_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "CA_CERT: $CA_CERT"
  inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"

  local PEER_PARAMS=()
  read -r -a PEER_PARAMS <<<"--peerAddresses $(echo "$PEER_ADDRESS" | sed 's/,/ --peerAddresses /g')"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    read -r -a CA_CERT_PARAMS <<<"--tls --cafile /var/hyperledger/cli/$(echo "$CA_CERT_FILES" | sed 's/,/ --cafile \/var\/hyperledger\/cli\//g')"
  fi

  local COLLECTIONS_CONFIG_PARAMS=()
  if [ -n "$COLLECTIONS_CONFIG" ]; then
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  fi

  docker exec "$CLI_NAME" peer lifecycle chaincode commit \
    -o "$ORDERER_URL" \
    -C "$CHANNEL_NAME" \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    --sequence 1 \
    --signature-policy "$ENDORSEMENT" \
    "${COLLECTIONS_CONFIG_PARAMS[@]}" \
    "${PEER_PARAMS[@]}" \
    "${CA_CERT_PARAMS[@]}"
}

function chaincodeInstallV1() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3
  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local CHAINCODE_DIR_PATH=$7
  local ORDERER_URL=$8
  local CA_CERT=$9

  echo "Installing chaincode on $CHANNEL_NAME..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CA_CERT: $CA_CERT"

  local PEER_PARAMS=()
  read -r -a PEER_PARAMS <<<"--peerAddresses $(echo "$PEER_ADDRESS" | sed 's/,/ --peerAddresses /g')"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    read -r -a CA_CERT_PARAMS <<<"--tls --cafile /var/hyperledger/cli/$(echo "$CA_CERT_FILES" | sed 's/,/ --cafile \/var\/hyperledger\/cli\//g')"
  fi

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    docker exec -e CHANNEL_NAME="$CHANNEL_NAME" "$CLI_NAME" peer chaincode install \
      -n "$CHAINCODE_NAME" \
      -v "$CHAINCODE_VERSION" \
      -l "$CHAINCODE_LANG" \
      -p "/var/hyperledger/cli/$CHAINCODE_NAME/" \
      -o "$ORDERER_URL" \
      "${PEER_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' installation (TLS). Chaincode's directory is empty."
  fi
}

function chaincodeInstantiateV1() {
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
  local CA_CERT=${11}
  local COLLECTIONS_CONFIG=${12}

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

  local PEER_PARAMS=()
  read -r -a PEER_PARAMS <<<"--peerAddresses $(echo "$PEER_ADDRESS" | sed 's/,/ --peerAddresses /g')"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    read -r -a CA_CERT_PARAMS <<<"--tls --cafile /var/hyperledger/cli/$(echo "$CA_CERT_FILES" | sed 's/,/ --cafile \/var\/hyperledger\/cli\//g')"
  fi

  local COLLECTIONS_CONFIG_PARAMS=()
  if [ -n "$COLLECTIONS_CONFIG" ]; then
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  fi

  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    docker exec "$CLI_NAME" peer chaincode instantiate \
      -C "$CHANNEL_NAME" \
      -n "$CHAINCODE_NAME" \
      -v "$CHAINCODE_VERSION" \
      -l "$CHAINCODE_LANG" \
      -o "$ORDERER_URL" \
      -c "$INIT_PARAMS" \
      -P "$ENDORSEMENT" \
      "${PEER_PARAMS[@]}" \
      "${COLLECTIONS_CONFIG_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' instantiate. Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}

function chaincodeUpgradeV1() {
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
  local CA_CERT=${11}
  local COLLECTIONS_CONFIG=${12}

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

  local PEER_PARAMS=()
  read -r -a PEER_PARAMS <<<"--peerAddresses $(echo "$PEER_ADDRESS" | sed 's/,/ --peerAddresses /g')"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    read -r -a CA_CERT_PARAMS <<<"--tls --cafile /var/hyperledger/cli/$(echo "$CA_CERT_FILES" | sed 's/,/ --cafile \/var\/hyperledger\/cli\//g')"
  fi

  local COLLECTIONS_CONFIG_PARAMS=()
  if [ -n "$COLLECTIONS_CONFIG" ]; then
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  fi

  # TODO move this check to commands generated everywhere
  if [ -n "$(ls "$CHAINCODE_DIR_PATH")" ]; then
    docker exec "$CLI_NAME" peer chaincode upgrade \
      -C "$CHANNEL_NAME" \
      -n "$CHAINCODE_NAME" \
      -v "$CHAINCODE_VERSION" \
      -l "$CHAINCODE_LANG" \
      -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
      -o "$ORDERER_URL" \
      -c "$INIT_PARAMS" \
      -P "$ENDORSEMENT" \
      "${COLLECTIONS_CONFIG_PARAMS[@]}" \
      "${PEER_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
  else
    echo "Warning! Skipping chaincode '$CHAINCODE_NAME' instantiate. Chaincode's directory is empty."
    echo "Looked in dir: '$CHAINCODE_DIR_PATH'"
  fi
}
