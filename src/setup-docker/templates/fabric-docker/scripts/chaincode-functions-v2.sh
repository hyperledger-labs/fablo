#!/usr/bin/env bash

function chaincodeBuild() {
  local CHAINCODE_NAME=$1
  local CHAINCODE_LANG=$2
  local CHAINCODE_DIR_PATH=$3

  mkdir -p "$CHAINCODE_DIR_PATH"

  if [ "$CHAINCODE_LANG" = "node" ]; then
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
}

function chaincodePackage() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHAINCODE_NAME=$3
  local CHAINCODE_VERSION=$4
  local CHAINCODE_LABEL="${CHAINCODE_NAME}_$CHAINCODE_VERSION"
  local CHAINCODE_LANG=$5

  echo "Packaging chaincode $CHAINCODE_NAME..."
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CLI_NAME: $CLI_NAME"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode package \
    "/var/hyperledger/cli/$CHAINCODE_NAME/$CHAINCODE_LABEL.tar.gz" \
    --path "/var/hyperledger/cli/$CHAINCODE_NAME/" \
    --lang "$CHAINCODE_LANG" \
    --label "$CHAINCODE_LABEL"
}

function chaincodeInstall() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHAINCODE_NAME=$3
  local CHAINCODE_VERSION=$4
  local CHAINCODE_LABEL="${CHAINCODE_NAME}_$CHAINCODE_VERSION"
  local CA_CERT=$5

  echo "Installing chaincode $CHAINCODE_NAME..."
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CA_CERT: $CA_CERT"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    CA_CERT_PARAMS=(--tlsRootCertFiles "/var/hyperledger/cli/$CA_CERT")
  fi

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode install \
    "/var/hyperledger/cli/$CHAINCODE_NAME/$CHAINCODE_LABEL.tar.gz" \
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

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    CA_CERT_PARAMS=(--tls --cafile "/var/hyperledger/cli/$CA_CERT")
  fi

  local COLLECTIONS_CONFIG_PARAMS=()
  if [ -n "$COLLECTIONS_CONFIG" ]; then
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  fi

  local QUERYINSTALLED_RESPONSE
  local CC_PACKAGE_ID

  QUERYINSTALLED_RESPONSE="$(
    docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode queryinstalled \
      --output json \
      "${CA_CERT_PARAMS[@]}"
  )"
  CC_PACKAGE_ID="$(jq ".installed_chaincodes | [.[]? | select(.label==\"$CHAINCODE_LABEL\") ][0].package_id" -r <<<"$QUERYINSTALLED_RESPONSE")"
  inputLog "CC_PACKAGE_ID: $CC_PACKAGE_ID"

  local QUERYCOMMITTED_RESPONSE
  local SEQUENCE

  QUERYCOMMITTED_RESPONSE="$(
    docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode querycommitted \
      --channelID "$CHANNEL_NAME" \
      --output json \
      "${CA_CERT_PARAMS[@]}"
  )"
  SEQUENCE="$(jq ".chaincode_definitions | [.[]? | select(.name==\"$CHAINCODE_NAME\").sequence ] | max | select(.!= null)" -r <<<"$QUERYCOMMITTED_RESPONSE")"
  SEQUENCE=$((SEQUENCE + 1))
  inputLog "SEQUENCE: $SEQUENCE"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" -e CC_PACKAGE_ID="$CC_PACKAGE_ID" "$CLI_NAME" peer lifecycle chaincode approveformyorg \
    -o "$ORDERER_URL" \
    -C "$CHANNEL_NAME" \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    --package-id "$CC_PACKAGE_ID" \
    --sequence "$SEQUENCE" \
    --signature-policy "$ENDORSEMENT" \
    "${COLLECTIONS_CONFIG_PARAMS[@]}" \
    "${CA_CERT_PARAMS[@]}"
}

function chaincodeCommit() {
  # TODO commands generated ma przyjmować te parametry (brakuje tls)
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME="$3"
  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local ORDERER_URL=$6
  local ENDORSEMENT=$7
  local CA_CERT=$8
  local COMMIT_PEER_ADDRESSES=$9
  local TLS_ROOT_CERT_FILES=${10}
  local COLLECTIONS_CONFIG=${11}

  echo "Committing chaincode $CHAINCODE_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "CA_CERT: $CA_CERT"
  inputLog "COMMIT_PEER_ADDRESSES: $COMMIT_PEER_ADDRESSES"
  inputLog "TLS_ROOT_CERT_FILES: $TLS_ROOT_CERT_FILES"
  inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    CA_CERT_PARAMS=(--tls --cafile "/var/hyperledger/cli/$CA_CERT")
  fi

  local COMMIT_PEER_PARAMS=()
  if [ -n "$COMMIT_PEER_ADDRESSES" ]; then
    # shellcheck disable=SC2207
    COMMIT_PEER_PARAMS=($(echo ",$COMMIT_PEER_ADDRESSES" | sed 's/,/ --peerAddresses /g'))
  fi

  local TLS_ROOT_CERT_PARAMS=()
  if [ -n "$TLS_ROOT_CERT_FILES" ]; then
    # shellcheck disable=SC2207
    TLS_ROOT_CERT_PARAMS=(--tls $(echo ",$TLS_ROOT_CERT_FILES" | sed 's/,/ --tlsRootCertFiles \/var\/hyperledger\/cli\//g'))
  fi

  local COLLECTIONS_CONFIG_PARAMS=()
  if [ -n "$COLLECTIONS_CONFIG" ]; then
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  fi

  local QUERYCOMMITTED_RESPONSE
  local SEQUENCE

  QUERYCOMMITTED_RESPONSE="$(
    docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode querycommitted \
      --channelID "$CHANNEL_NAME" \
      --output json \
      "${CA_CERT_PARAMS[@]}"
  )"
  SEQUENCE="$(jq ".chaincode_definitions | [.[]? | select(.name==\"$CHAINCODE_NAME\").sequence ] | max | select(.!= null)" -r <<<"$QUERYCOMMITTED_RESPONSE")"
  SEQUENCE=$((SEQUENCE + 1))
  inputLog "SEQUENCE: $SEQUENCE"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode commit \
    -o "$ORDERER_URL" \
    -C "$CHANNEL_NAME" \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    --sequence "$SEQUENCE" \
    --signature-policy "$ENDORSEMENT" \
    "${COLLECTIONS_CONFIG_PARAMS[@]}" \
    "${COMMIT_PEER_PARAMS[@]}" \
    "${TLS_ROOT_CERT_PARAMS[@]}" \
    "${CA_CERT_PARAMS[@]}"
}
