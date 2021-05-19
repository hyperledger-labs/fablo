#!/usr/bin/env bash

function chaincodeBuild() {
  local CHAINCODE_NAME=$1
  local CHAINCODE_LANG=$2
  local CHAINCODE_DIR_PATH=$3

  mkdir -p "$CHAINCODE_DIR_PATH"

  if [ "$CHAINCODE_LANG" = "node" ]; then
    local NODE_VERSION="12"
    local COMMAND="npm install && npm run build"

    local USES_OLD_FABRIC_SHIM="$(jq '.dependencies."fabric-shim" | contains("1.4.")' "$CHAINCODE_DIR_PATH/package.json")"
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
}

function chaincodePackage() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHAINCODE_NAME=$3
  local CHAINCODE_VERSION=$4
  local CHAINCODE_LABEL="${CHAINCODE_NAME}_$CHAINCODE_VERSION"
  local CHAINCODE_LANG=$5
  local ORDERER_URL=$6
  local CA_CERT=$7

  echo "Packaging chaincode $CHAINCODE_NAME..."
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
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

  docker exec "$CLI_NAME" peer lifecycle chaincode package \
    "/var/hyperledger/cli/$CHAINCODE_NAME/$CHAINCODE_LABEL.tar.gz" \
    --path "/var/hyperledger/cli/$CHAINCODE_NAME/" \
    --lang "$CHAINCODE_LANG" \
    --label "$CHAINCODE_LABEL" \
    "${PEER_PARAMS[@]}" \
    "${CA_CERT_PARAMS[@]}"
}

function chaincodeInstall() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHAINCODE_NAME=$3
  local CHAINCODE_VERSION=$4
  local CHAINCODE_LABEL="${CHAINCODE_NAME}_$CHAINCODE_VERSION"
  local ORDERER_URL=$5
  local CA_CERT=$6

  echo "Installing chaincode $CHAINCODE_NAME..."
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
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
  local CHAINCODE_LABEL="${CHAINCODE_NAME}_$CHAINCODE_VERSION"
  local ORDERER_URL=$6
  local ENDORSEMENT=$7
  local CA_CERT=$8
  local COLLECTIONS_CONFIG=$9

  echo "Approving chaincode $CHAINCODE_NAME..."
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

  local QUERYINSTALLED_RESPONSE
  local CC_PACKAGE_ID

  QUERYINSTALLED_RESPONSE="$(
    docker exec "$CLI_NAME" peer lifecycle chaincode queryinstalled \
      --output json \
      "${PEER_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
  )"
  echo "$QUERYINSTALLED_RESPONSE"
  CC_PACKAGE_ID="$(jq ".installed_chaincodes | [.[]? | select(.label==\"$CHAINCODE_LABEL\") ][0].package_id" -r <<<"$QUERYINSTALLED_RESPONSE")"
  inputLog "CC_PACKAGE_ID: $CC_PACKAGE_ID"

  local QUERYCOMMITTED_RESPONSE
  local SEQUENCE

  QUERYCOMMITTED_RESPONSE="$(
    docker exec "$CLI_NAME" peer lifecycle chaincode querycommitted \
      --channelID "$CHANNEL_NAME" \
      --output json \
      "${PEER_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
  )"
  echo "$QUERYCOMMITTED_RESPONSE"
  SEQUENCE="$(jq ".chaincode_definitions | [.[]? | select(.name==\"$CHAINCODE_NAME\").sequence ] | max | select(.!= null)" -r <<<"$QUERYCOMMITTED_RESPONSE")"
  SEQUENCE=$((SEQUENCE + 1))
  inputLog "SEQUENCE: $SEQUENCE"

  docker exec -e CC_PACKAGE_ID="$CC_PACKAGE_ID" "$CLI_NAME" peer lifecycle chaincode approveformyorg \
    -o "$ORDERER_URL" \
    -C "$CHANNEL_NAME" \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    --package-id "$CC_PACKAGE_ID" \
    --sequence "$SEQUENCE" \
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

  local QUERYCOMMITTED_RESPONSE
  local SEQUENCE

  QUERYCOMMITTED_RESPONSE="$(
    docker exec "$CLI_NAME" peer lifecycle chaincode querycommitted \
      --channelID "$CHANNEL_NAME" \
      --output json \
      "${PEER_PARAMS[@]}" \
      "${CA_CERT_PARAMS[@]}"
  )"
  echo "$QUERYCOMMITTED_RESPONSE"
  SEQUENCE="$(jq ".chaincode_definitions | [.[]? | select(.name==\"$CHAINCODE_NAME\").sequence ] | max | select(.!= null)" -r <<<"$QUERYCOMMITTED_RESPONSE")"
  SEQUENCE=$((SEQUENCE + 1))
  inputLog "SEQUENCE: $SEQUENCE"

  docker exec "$CLI_NAME" peer lifecycle chaincode commit \
    -o "$ORDERER_URL" \
    -C "$CHANNEL_NAME" \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    --sequence "$SEQUENCE" \
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
  local ORDERER_URL=$7
  local CA_CERT=$8

  echo "Installing chaincode on $CHANNEL_NAME..."
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
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

  docker exec -e CHANNEL_NAME="$CHANNEL_NAME" "$CLI_NAME" peer chaincode install \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    -l "$CHAINCODE_LANG" \
    -p "/var/hyperledger/cli/$CHAINCODE_NAME/" \
    -o "$ORDERER_URL" \
    "${PEER_PARAMS[@]}" \
    "${CA_CERT_PARAMS[@]}"
}

function chaincodeInstantiateV1() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3
  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local ORDERER_URL=$7
  local INIT_PARAMS=$8
  local ENDORSEMENT=$9
  local CA_CERT=${10}
  local COLLECTIONS_CONFIG=${11}

  echo "Instantiating chaincode on $CHANNEL_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
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
}

function chaincodeUpgradeV1() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3
  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LANG=$6
  local ORDERER_URL=$7
  local INIT_PARAMS=$8
  local ENDORSEMENT=$9
  local CA_CERT=${10}
  local COLLECTIONS_CONFIG=${11}

  echo "Upgrading chaincode on $CHANNEL_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
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
}
