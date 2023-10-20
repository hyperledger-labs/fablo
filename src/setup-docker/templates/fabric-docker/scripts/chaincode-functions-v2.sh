#!/usr/bin/env bash
# phrase "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}" is needed in older bash versions ( <4 ) for array expansion.
# see: https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u

dockerPullIfMissing() {
  local IMAGE="$1"
  if [[ "$(docker images -q "$IMAGE" 2>/dev/null)" == "" ]]; then
    docker pull --platform linux/x86_64 "$IMAGE"
  fi
}

chaincodeBuild() {
  local CHAINCODE_NAME=$1
  local CHAINCODE_LANG=$2
  local CHAINCODE_DIR_PATH=$3
  local RECOMMENDED_NODE_VERSION=$4

  mkdir -p "$CHAINCODE_DIR_PATH"

  # pull required images upfront in case of arm64 (Apple Silicon) architecture
  # see https://stackoverflow.com/questions/69699421/hyperledger-fabric-chaincode-installation-failed-no-matching-manifest-for-linu
  if [ "$(uname -m)" = "arm64" ]; then
    if [ "$CHAINCODE_LANG" = "node" ]; then
      dockerPullIfMissing "hyperledger/fabric-nodeenv:$FABRIC_NODEENV_VERSION"
    fi
    if [ "$CHAINCODE_LANG" = "java" ]; then
      dockerPullIfMissing "hyperledger/fabric-javaenv:$FABRIC_JAVAENV_VERSION"
    fi
    if [ "$CHAINCODE_LANG" = "golang" ]; then
      dockerPullIfMissing "hyperledger/fabric-baseos:$FABRIC_BASEOS_VERSION"
    fi
  fi

  if [ "$CHAINCODE_LANG" = "node" ]; then
    if [ "$(command -v nvm)" != "nvm" ] && [ -f ~/.nvm/nvm.sh ]; then
      # note: `source ~/.nvm/nvm.sh || true` seems to not work on some shells (like /bin/zsh on Apple Silicon)
      set +e
      source ~/.nvm/nvm.sh
      set -e
      if [ "$(command -v nvm)" == "nvm" ]; then
        current_dir="$(pwd)"
        cd "$CHAINCODE_DIR_PATH"
        set +u
        nvm install
        set -u
        cd "$current_dir"
      fi
    fi

    NODE_VERSION="$(node --version)"

    USES_OLD_FABRIC_SHIM="$(jq '.dependencies."fabric-shim" | contains("1.4.")' "$CHAINCODE_DIR_PATH/package.json")"
    if [ "$USES_OLD_FABRIC_SHIM" == "true" ]; then
      RECOMMENDED_NODE_VERSION="8.9"
    fi

    if ! echo "$NODE_VERSION" | grep -q "v$RECOMMENDED_NODE_VERSION"; then
      echo "Warning: Your Node.js version is $NODE_VERSION, but recommended is $RECOMMENDED_NODE_VERSION)"
      echo "See: https://github.com/hyperledger/fabric-chaincode-node/blob/main/COMPATIBILITY.md"
    fi

    echo "Buiding chaincode '$CHAINCODE_NAME'..."
    inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
    inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
    inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
    inputLog "NODE_VERSION: $NODE_VERSION (recommended: $RECOMMENDED_NODE_VERSION)"

    # We have different commands for npm and yarn
    if [ -f "$CHAINCODE_DIR_PATH/yarn.lock" ]; then
      (cd "$CHAINCODE_DIR_PATH" && npm install -g yarn && yarn install && yarn build)
    else
      (cd "$CHAINCODE_DIR_PATH" && npm install && npm run build)
    fi
  fi
}

chaincodePackage() {
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
    "/var/hyperledger/cli/chaincode-packages/$CHAINCODE_LABEL.tar.gz" \
    --path "/var/hyperledger/cli/$CHAINCODE_NAME/" \
    --lang "$CHAINCODE_LANG" \
    --label "$CHAINCODE_LABEL"

  # set package owner as current (host) user to fix permission issues
  docker exec "$CLI_NAME" chown "$(id -u):$(id -g)" "/var/hyperledger/cli/chaincode-packages/$CHAINCODE_LABEL.tar.gz"
}

chaincodeInstall() {
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
    "/var/hyperledger/cli/chaincode-packages/$CHAINCODE_LABEL.tar.gz" \
    "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
}

chaincodeApprove() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME="$3"
  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local CHAINCODE_LABEL="${CHAINCODE_NAME}_$CHAINCODE_VERSION"
  local ORDERER_URL=$6
  local ENDORSEMENT=$7
  local INIT_REQUIRED=$8
  local CA_CERT=$9
  local COLLECTIONS_CONFIG=${10}

  echo "Approving chaincode $CHAINCODE_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "INIT_REQUIRED: $INIT_REQUIRED"
  inputLog "CA_CERT: $CA_CERT"
  inputLog "COLLECTIONS_CONFIG: $COLLECTIONS_CONFIG"

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    CA_CERT_PARAMS=(--tls --cafile "/var/hyperledger/cli/$CA_CERT")
  fi

  local ENDORSEMENT_PARAMS=()
  if [ -n "$ENDORSEMENT" ]; then
    ENDORSEMENT_PARAMS=(--signature-policy "$ENDORSEMENT")
  fi

  local INIT_REQUIRED_PARAMS=()
  if [ "$INIT_REQUIRED" = "true" ]; then
    INIT_REQUIRED_PARAMS=(--init-required)
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
      "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
  )"
  CC_PACKAGE_ID="$(jq ".installed_chaincodes | [.[]? | select(.label==\"$CHAINCODE_LABEL\") ][0].package_id // \"\"" -r <<<"$QUERYINSTALLED_RESPONSE")"
  if [ -z "$CC_PACKAGE_ID" ]; then
    CC_PACKAGE_ID="$CHAINCODE_NAME:$CHAINCODE_VERSION"
  fi
  inputLog "CC_PACKAGE_ID: $CC_PACKAGE_ID"

  local QUERYCOMMITTED_RESPONSE
  local SEQUENCE

  QUERYCOMMITTED_RESPONSE="$(
    docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode querycommitted \
      --channelID "$CHANNEL_NAME" \
      --output json \
      "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
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
    "${ENDORSEMENT_PARAMS[@]+"${ENDORSEMENT_PARAMS[@]}"}" \
    "${INIT_REQUIRED_PARAMS[@]+"${INIT_REQUIRED_PARAMS[@]}"}" \
    "${COLLECTIONS_CONFIG_PARAMS[@]+"${COLLECTIONS_CONFIG_PARAMS[@]}"}" \
    "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
}

chaincodeCommit() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME="$3"
  local CHAINCODE_NAME=$4
  local CHAINCODE_VERSION=$5
  local ORDERER_URL=$6
  local ENDORSEMENT=$7
  local INIT_REQUIRED=$8
  local CA_CERT=$9
  local COMMIT_PEER_ADDRESSES=${10}
  local TLS_ROOT_CERT_FILES=${11}
  local COLLECTIONS_CONFIG=${12}

  echo "Committing chaincode $CHAINCODE_NAME..."
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "ORDERER_URL: $ORDERER_URL"
  inputLog "ENDORSEMENT: $ENDORSEMENT"
  inputLog "INIT_REQUIRED: $INIT_REQUIRED"
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

  local ENDORSEMENT_PARAMS=()
  if [ -n "$ENDORSEMENT" ]; then
    ENDORSEMENT_PARAMS=(--signature-policy "$ENDORSEMENT")
  fi

  local INIT_REQUIRED_PARAMS=()
  if [ "$INIT_REQUIRED" = "true" ]; then
    INIT_REQUIRED_PARAMS=(--init-required)
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
      "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
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
    "${ENDORSEMENT_PARAMS[@]+"${ENDORSEMENT_PARAMS[@]}"}" \
    "${INIT_REQUIRED_PARAMS[@]+"${INIT_REQUIRED_PARAMS[@]}"}" \
    "${COLLECTIONS_CONFIG_PARAMS[@]+"${COLLECTIONS_CONFIG_PARAMS[@]}"}" \
    "${COMMIT_PEER_PARAMS[@]+"${COMMIT_PEER_PARAMS[@]}"}" \
    "${TLS_ROOT_CERT_PARAMS[@]+"${TLS_ROOT_CERT_PARAMS[@]}"}" \
    "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
}

peerChaincodeList() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3

  echo "Chaincodes list:"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"

  # Execute the command to list chaincodes
  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode querycommitted \
    --channelID "$CHANNEL_NAME"
}

peerChaincodeListTls() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHANNEL_NAME=$3
  local CA_CERT=$4

  echo "Chaincodes list:"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CHANNEL_NAME: $CHANNEL_NAME"
  inputLog "CA_CERT: $CA_CERT"

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode querycommitted \
    --channelID "$CHANNEL_NAME" \
    --tls \
    --cafile "/var/hyperledger/cli/$CA_CERT"
}

# Function to perform chaincode invoke
peerChaincodeInvoke() {
  local CLI="$1"
  local PEERS="$2"
  local CHANNEL="$3"
  local CHAINCODE="$4"
  local COMMAND="$5"
  local TRANSIENT="$6"

  echo "Chaincode invoke:"
  inputLog "CLI: $CLI"
  inputLog "PEERS: $PEERS"
  inputLog "CHANNEL: $CHANNEL"
  inputLog "CHAINCODE: $CHAINCODE"
  inputLog "COMMAND: $COMMAND"
  inputLog "TRANSIENT: $TRANSIENT"

  PEER_ADDRESSES="--peerAddresses $(echo "$PEERS" | sed 's/,/ --peerAddresses  /g')"

  # shellcheck disable=SC2086
  docker exec "$CLI" peer chaincode invoke \
    $PEER_ADDRESSES \
    -C "$CHANNEL" \
    -n "$CHAINCODE" \
    -c "$COMMAND" \
    --transient "$TRANSIENT" \
    --waitForEvent \
    --waitForEventTimeout 90s \
    2>&1
}
# Function to perform chaincode invoke for Tls
peerChaincodeInvokeTls() {
  local CLI="$1"
  local PEERS="$2"
  local CHANNEL="$3"
  local CHAINCODE="$4"
  local COMMAND="$5"
  local TRANSIENT="$6"
  local PEER_CERTS="$7"
  local CA_CERT="$8"

  echo "Chaincode invoke:"
  inputLog "CLI: $CLI"
  inputLog "PEERS: $PEERS"
  inputLog "CHANNEL: $CHANNEL"
  inputLog "CHAINCODE: $CHAINCODE"
  inputLog "COMMAND: $COMMAND"
  inputLog "TRANSIENT: $TRANSIENT"
  inputLog "PEER_CERTS: $PEER_CERTS"
  inputLog "CA_CERT: $CA_CERT"

  PEER_ADDRESSES="--peerAddresses $(echo "$PEERS" | sed 's/,/ --peerAddresses  /g')"

  TLS_ROOT_CERT_FILES="--tlsRootCertFiles /var/hyperledger/cli/$(echo "$PEER_CERTS" | sed 's/,/ --tlsRootCertFiles \/var\/hyperledger\/cli\//g')"

  # shellcheck disable=SC2086
  docker exec "$CLI" peer chaincode invoke \
    $PEER_ADDRESSES \
    $TLS_ROOT_CERT_FILES \
    -C "$CHANNEL" \
    -n "$CHAINCODE" \
    -c "$COMMAND" \
    --transient "$TRANSIENT" \
    --waitForEvent \
    --waitForEventTimeout 90s \
    --tls \
    --cafile "/var/hyperledger/cli/$CA_CERT" \
    2>&1
}
