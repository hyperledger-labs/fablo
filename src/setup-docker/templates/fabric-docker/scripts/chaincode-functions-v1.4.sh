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
        nvm install
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

chaincodeInstall() {
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

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    CA_CERT_PARAMS=(--tls --cafile "/var/hyperledger/cli/$CA_CERT")
  fi

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" -e CHANNEL_NAME="$CHANNEL_NAME" "$CLI_NAME" peer chaincode install \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    -l "$CHAINCODE_LANG" \
    -p "/var/hyperledger/cli/$CHAINCODE_NAME/" \
    -o "$ORDERER_URL" \
    "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
}

chaincodeInstantiate() {
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

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    CA_CERT_PARAMS=(--tls --cafile "/var/hyperledger/cli/$CA_CERT")
  fi

  local COLLECTIONS_CONFIG_PARAMS=()
  if [ -n "$COLLECTIONS_CONFIG" ]; then
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  fi

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode instantiate \
    -C "$CHANNEL_NAME" \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    -l "$CHAINCODE_LANG" \
    -o "$ORDERER_URL" \
    -c "$INIT_PARAMS" \
    -P "$ENDORSEMENT" \
    "${COLLECTIONS_CONFIG_PARAMS[@]+"${COLLECTIONS_CONFIG_PARAMS[@]}"}" \
    "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
}

chaincodeUpgrade() {
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

  local CA_CERT_PARAMS=()
  if [ -n "$CA_CERT" ]; then
    CA_CERT_PARAMS=(--tls --cafile "/var/hyperledger/cli/$CA_CERT")
  fi

  local COLLECTIONS_CONFIG_PARAMS=()
  if [ -n "$COLLECTIONS_CONFIG" ]; then
    COLLECTIONS_CONFIG_PARAMS=(--collections-config "$COLLECTIONS_CONFIG")
  fi

  docker exec -e CORE_PEER_ADDRESS="$PEER_ADDRESS" "$CLI_NAME" peer chaincode upgrade \
    -C "$CHANNEL_NAME" \
    -n "$CHAINCODE_NAME" \
    -v "$CHAINCODE_VERSION" \
    -l "$CHAINCODE_LANG" \
    -p /var/hyperledger/cli/"$CHAINCODE_NAME"/ \
    -o "$ORDERER_URL" \
    -c "$INIT_PARAMS" \
    -P "$ENDORSEMENT" \
    "${COLLECTIONS_CONFIG_PARAMS[@]+"${COLLECTIONS_CONFIG_PARAMS[@]}"}" \
    "${CA_CERT_PARAMS[@]+"${CA_CERT_PARAMS[@]}"}"
}
