#!/usr/bin/env bash
# phrase "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}" is needed in older bash versions ( <4 ) for array expansion.
# see: https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u

dockerPullIfMissing() {
  local IMAGE="$1"
  if [[ "$(docker images -q "$IMAGE" 2>/dev/null)" == "" ]]; then
    docker pull --platform linux/x86_64 "$IMAGE"
  fi
}

node_version_check(){
    
    local fabric_shim_version="$1"
    local nodejs_version

    if [[ "$fabric_shim_version" == *"1.4."* ]]; then
        nodejs_version=8.9

    elif [[ "$fabric_shim_version" == *"2.2."* || "$fabric_shim_version" == *"2.3."* ]]; then
        nodejs_version=12.13

    elif [[ "$fabric_shim_version" == *"2.4."* ]]; then
        nodejs_version=16.16

    elif [[ "$fabric_shim_version" == *"2.5."* ]]; then
        nodejs_version=18.12

    else
        nodejs_version=18.12
    fi

    echo $nodejs_version

}

chaincodeBuild() {
  local CHAINCODE_NAME=$1
  local CHAINCODE_LANG=$2
  local CHAINCODE_DIR_PATH=$3
  local RECOMMENDED_NODE_VERSION=$4

  mkdir -p "$CHAINCODE_DIR_PATH"

  # pull required images upfront in case of arm64 (Apple Silicon) architecture
  # see https://stackoverflow.com/questions/69699421/hyperledger-fabric-chaincode-installation-failed-no-matching-manifest-for-linu
  # also, starting from Fabric 2.5, the base images for chaincode are available for arm64, so we don't need to pull them separately
  # and we use `sort -V` to compare versions, because `sort` handles versions like `2.4` and `2.10` correctly
  if [ "$(uname -m)" = "arm64" ] && [ "$(printf '%s\n' "$FABRIC_VERSION" "2.5" | sort -V | head -n1)" = "$FABRIC_VERSION" ]; then
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
    NODE_VERSION=$(node --version)
    fabric_shim_version=$(jq -r '.dependencies."fabric-shim"' "$CHAINCODE_DIR_PATH/package.json")
    RECOMMENDED_NODE_VERSION=$(node_version_check "$fabric_shim_version")

    if ! echo "$NODE_VERSION" | grep -q "v$RECOMMENDED_NODE_VERSION"; then
      echo "Warning: Your Node.js version is $NODE_VERSION, but recommended is $RECOMMENDED_NODE_VERSION)"
      echo "See: https://github.com/hyperledger/fabric-chaincode-node/blob/main/COMPATIBILITY.md"
    fi

    echo "Buiding chaincode '$CHAINCODE_NAME'..."
    inputLog "CHAINCODE_NAME: $CHAINCODE_NAME"
    inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
    inputLog "CHAINCODE_DIR_PATH: $CHAINCODE_DIR_PATH"
    inputLog "NODE_VERSION: $NODE_VERSION (recommended: $RECOMMENDED_NODE_VERSION)"
    
    # Default to using npm for installation and build
    (cd "$CHAINCODE_DIR_PATH" && npm install && npm run build)
    
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

chaincodePackageCCaaS() {
  local CLI_NAME=$1
  local PEER_ADDRESS=$2
  local CHAINCODE_NAME=$3
  local CHAINCODE_VERSION=$4
  local CHAINCODE_LABEL="${CHAINCODE_NAME}_$CHAINCODE_VERSION"
  local CHAINCODE_LANG=$5
  local CHAINCODE_IMAGE=$6
  local CONTAINER_PORT=$7
  local CONTAINER_NAME=$8
  local TLS_ENABLED=$9

  echo "Packaging chaincode $CHAINCODE_NAME..."
  inputLog "CHAINCODE_VERSION: $CHAINCODE_VERSION"
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"
  inputLog "PEER_ADDRESS: $PEER_ADDRESS"
  inputLog "CLI_NAME: $CLI_NAME"
  inputLog "CHAINCODE_IMAGE: $CHAINCODE_IMAGE"
  inputLog "CONTAINER_PORT: $CONTAINER_PORT"
  inputLog "TLS_ENABLED: $TLS_ENABLED"
  
  echo "Packaging chaincode as CCAAS (external builder)..."
  
  local PACKAGE_DIR="./chaincode-packages/ccaas_$CONTAINER_NAME"
  
  mkdir -p "$PACKAGE_DIR"
  echo "{\"type\":\"$CHAINCODE_LANG\",\"label\":\"$CHAINCODE_LABEL\"}" > "$PACKAGE_DIR/metadata.json"

  mkdir -p "$PACKAGE_DIR/code"

  if [ "$TLS_ENABLED" = true ]; then
    local TLS_PATH="$FABLO_NETWORK_ROOT/fabric-config/crypto-config/ccaas/$CONTAINER_NAME/tls"
    local ROOT_CERT=$(cat "$TLS_PATH/peer.crt" | awk '{printf "%s\\n", $0}')
    local SERVER_CERT=$(cat "$TLS_PATH/client.crt" | awk '{printf "%s\\n", $0}')
    local SERVER_KEY=$(cat "$TLS_PATH/client.key" | awk '{printf "%s\\n", $0}')

    cat <<EOF > "$PACKAGE_DIR/code/connection.json"
{
  "address": "${CONTAINER_NAME}:${CONTAINER_PORT}",
  "domain": "${CONTAINER_NAME}",
  "dial_timeout": "10s",
  "tls_required": $TLS_ENABLED,
  "client_auth_required": true,
  "client_cert": "$SERVER_CERT",
  "client_key": "$SERVER_KEY",
  "root_cert": "$ROOT_CERT"
}
EOF
  else
    cat <<EOF > "$PACKAGE_DIR/code/connection.json"
{
  "address": "${CONTAINER_NAME}:${CONTAINER_PORT}",
  "dial_timeout": "10s",
  "tls_required": $TLS_ENABLED,
}
EOF
  fi
  tar -czf "$PACKAGE_DIR/code.tar.gz" -C "$PACKAGE_DIR/code" connection.json
  tar -czf "./chaincode-packages/$CHAINCODE_LABEL.tar.gz" -C "$PACKAGE_DIR" metadata.json code.tar.gz

  docker cp "./chaincode-packages/$CHAINCODE_LABEL.tar.gz" "$CLI_NAME:/var/hyperledger/cli/chaincode-packages/$CHAINCODE_LABEL.tar.gz";

  rm "./chaincode-packages/$CHAINCODE_LABEL.tar.gz"
  rm -rf "$PACKAGE_DIR" 

  echo "CCaaS package created at /var/hyperledger/cli/chaincode-packages/$CHAINCODE_LABEL.tar.gz"
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
  
  set -x

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer lifecycle chaincode install \
    "/var/hyperledger/cli/chaincode-packages/$CHAINCODE_LABEL.tar.gz" \
    "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
}

restartChaincodeContainerWithCorrectId() {
  local PEER_ADDRESS="$1"
  local CHAINCODE_NAME="$2"
  local CHAINCODE_LABEL="$3"
  local CC_PACKAGE_ID="$4"
  local CHAINCODE_IMAGE="$5"

  local PACKAGE_HASH="${CC_PACKAGE_ID#*:}"
  local CONTAINER_NAME="ccaas-${PEER_ADDRESS%%:*}-${CHAINCODE_NAME}"

  echo "🌀 Restarting CCaaS container: $CONTAINER_NAME with ID: ${CHAINCODE_LABEL}:${PACKAGE_HASH}"

  local TLS_PATH="$FABLO_NETWORK_ROOT/fabric-config/crypto-config/ccaas/$CONTAINER_NAME/tls"
  local PORT_MAP="7052:7052"
  
  # Use different ports for different containers to avoid conflicts
  if [[ "$CONTAINER_NAME" == *"peer1"* ]]; then
    PORT_MAP="7053:7052"
  fi
  
  local NETWORK=$(docker inspect "${PEER_ADDRESS%%:*}" | jq -r '.[0].NetworkSettings.Networks | keys[]')

  # Verify all required TLS files exist
  local REQUIRED_TLS_FILES=(
    "$TLS_PATH/client.key"
    "$TLS_PATH/client.crt"
    "$TLS_PATH/client_pem.key"
    "$TLS_PATH/client_pem.crt"
    "$TLS_PATH/peer.crt"
  )

  echo "Verifying TLS files exist..."
  for file in "${REQUIRED_TLS_FILES[@]}"; do
    if [ ! -f "$file" ]; then
      echo "ERROR: Required TLS file missing: $file"
      exit 1
    fi
    echo "✓ Found: $file"
  done

  docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true

  docker run -d \
    --name "$CONTAINER_NAME" \
    -e CORE_CHAINCODE_ADDRESS="0.0.0.0:7052" \
    -e CHAINCODE_SERVER_ADDRESS=0.0.0:7052 \
    -e CORE_CHAINCODE_ID_NAME="${CHAINCODE_LABEL}:${PACKAGE_HASH}" \
    -e CHAINCODE_ID="${CHAINCODE_LABEL}:${PACKAGE_HASH}" \
    -e CORE_CHAINCODE_LOGGING_LEVEL=info \
    -e CORE_CHAINCODE_LOGGING_SHIM=info \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_CHAINCODE_TLS_CERT_FILE=/etc/hyperledger/fabric/client.crt \
    -e CORE_CHAINCODE_TLS_KEY_FILE=/etc/hyperledger/fabric/client.key \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/peer.crt \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -v "$TLS_PATH/client.key:/etc/hyperledger/fabric/client.key" \
    -v "$TLS_PATH/client.crt:/etc/hyperledger/fabric/client.crt" \
    -v "$TLS_PATH/client_pem.key:/etc/hyperledger/fabric/client_pem.key" \
    -v "$TLS_PATH/client_pem.crt:/etc/hyperledger/fabric/client_pem.crt" \
    -v "$TLS_PATH/peer.crt:/etc/hyperledger/fabric/peer.crt" \
    -p "$PORT_MAP" \
    --network "$NETWORK" \
    "$CHAINCODE_IMAGE"
  
  # Redirect container logs to the log file in the background
  echo "Redirecting container logs to $(pwd)/$CONTAINER_NAME.log"
  docker logs -f "$CONTAINER_NAME" > "./$CONTAINER_NAME.log" 2>&1 &
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
  local CHAINCODE_LANG=${11}

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
  inputLog "CHAINCODE_LANG: $CHAINCODE_LANG"

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
  echo "QUERYINSTALLED_RESPONSE: $QUERYINSTALLED_RESPONSE"
  CC_PACKAGE_ID="$(jq ".installed_chaincodes | [.[]? | select(.label==\"$CHAINCODE_LABEL\") ][0].package_id // \"\"" -r <<<"$QUERYINSTALLED_RESPONSE")"
  if [ -z "$CC_PACKAGE_ID" ]; then
    echo "CC_PACKAGE_ID not found, using default: $CHAINCODE_NAME:$CHAINCODE_VERSION"
    CC_PACKAGE_ID="$CHAINCODE_NAME:$CHAINCODE_VERSION"
  fi
  inputLog "CC_PACKAGE_ID: $CC_PACKAGE_ID"
  if [ "$CHAINCODE_LANG" = "ccaas" ]; then
    local CHAINCODE_IMAGE=${12}
    restartChaincodeContainerWithCorrectId "$PEER_ADDRESS" "$CHAINCODE_NAME" "$CHAINCODE_LABEL" "$CC_PACKAGE_ID" "$CHAINCODE_IMAGE"
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
