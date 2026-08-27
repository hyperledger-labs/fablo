#!/usr/bin/env bash

printHeadline() {
  bold=$'\e[1m'
  end=$'\e[0m'
  TEXT=$1
  EMOJI=$2
  printf "${bold}============ %b %s %b ==============${end}\n" "\\$EMOJI" "$TEXT" "\\$EMOJI"
}

printStartSuccessInfo() {
  printHeadline "Done!! Fabric-X network is up" "U1F984"
  echo "App-level submit/query calls need a namespace."
  echo "Run './fabric-x-docker.sh namespace init' to create the default namespace if needed."
}

TOOLS_IMAGE="${TOOLS_IMAGE:-ghcr.io/hyperledger/fabric-x-tools:1.0.0}"
ORDERER_IMAGE="${ORDERER_IMAGE:-ghcr.io/hyperledger/fabric-x-orderer:1.0.0}"
NETWORK="${NETWORK:-fabric-x}"
DEFAULT_POLICY="AND('Org1MSP.member')"


generateArtifacts() {
  if [ -f "$FABRIC_X_ROOT/crypto/config-block.pb.bin" ] &&
    [ -f "$FABRIC_X_ROOT/crypto/shared_config.binpb" ] &&
    [ -f "$FABRIC_X_ROOT/crypto/client-tls-ca.pem" ]; then
    echo "Fabric-X crypto and config artifacts already exist, skipping generation."
    return
  fi

  if [ -d "$FABRIC_X_ROOT/crypto" ]; then
    echo "Removing incomplete Fabric-X crypto material..."
    rm -rf "$FABRIC_X_ROOT/crypto"
  fi

  mkdir -p "$FABRIC_X_ROOT/crypto"

  echo "Generating Fabric-X crypto material..."
  docker run --rm --user "$(id -u):$(id -g)" \
    -v "$FABRIC_X_ROOT:/config" \
    "$TOOLS_IMAGE" \
    sh -c 'cryptogen generate --config=/config/crypto-config.yaml --output=/config/crypto \
      && cp /config/crypto/peerOrganizations/org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem \
            /config/crypto/client-tls-ca.pem'

  echo "Generating Fabric-X shared config proto..."

  docker run --rm --user "$(id -u):$(id -g)" \
    -v "$FABRIC_X_ROOT:/config" \
    -v "$FABRIC_X_ROOT/crypto:/crypto" \
    --entrypoint /usr/local/bin/armageddon \
    "$ORDERER_IMAGE" \
    createSharedConfigProto \
    --sharedConfigYaml=/config/shared-config.yaml \
    --output=/config/crypto/

  echo "Generating Fabric-X genesis / config block..."
  docker run --rm --user "$(id -u):$(id -g)" \
    -v "$FABRIC_X_ROOT:/config" \
    "$TOOLS_IMAGE" \
    configtxgen --channelID mychannel --profile OrgsChannel \
    --outputBlock /config/crypto/config-block.pb.bin \
    --configPath /config

  echo "Fixing permissions for crypto material to ensure containers can read TLS keys..."
  chmod -R a+rX "$FABRIC_X_ROOT/crypto" || true
}
networkUp() {
  mkdir -p "$FABRIC_X_ROOT/data/orderers/party1-router" \
           "$FABRIC_X_ROOT/data/orderers/party1-consenter" \
           "$FABRIC_X_ROOT/data/orderers/party1-assembler" \
           "$FABRIC_X_ROOT/data/orderers/party1-batcher" \
           "$FABRIC_X_ROOT/data/committer-org1/sidecar-ledger"

  generateArtifacts
  # cryptogen writes private keys with mode 600. Run the services as the same
  # host user that owns those files instead of relying on Compose's 1000:1000
  # fallback, which is a different UID on many CI runners.
  FABRIC_X_UID="$(id -u)" FABRIC_X_GID="$(id -g)" \
    docker compose --project-directory "$FABRIC_X_ROOT" up -d --wait
  printStartSuccessInfo
}

networkDown() {
  (cd "$FABRIC_X_ROOT" && docker compose down -v)
  # Some containers (like Postgres) may change data dir ownership to their internal user (e.g. 999), 
  # making rm -rf fail for the CI runner user. Use docker to clean up if needed.
  rm -rf "$FABRIC_X_ROOT/crypto" "$FABRIC_X_ROOT/data" 2>/dev/null || \
    docker run --rm -v "$FABRIC_X_ROOT:/tmp/fx" alpine rm -rf /tmp/fx/crypto /tmp/fx/data
}


startNetwork() {
  (cd "$FABRIC_X_ROOT" && docker compose start)
}

stopNetwork() {
  (cd "$FABRIC_X_ROOT" && docker compose stop)
}


namespaceInit() {
  docker run --rm --network "$NETWORK" --user "$(id -u):$(id -g)" \
    --env "FX_NS=mynamespace" \
    --env "FX_POLICY=$DEFAULT_POLICY" \
    -v "$FABRIC_X_ROOT/fxconfig.yaml:/config/fxconfig.yaml:ro,Z" \
    -v "$FABRIC_X_ROOT/crypto/peerOrganizations/org1.example.com/peers/fxconfig.org1.example.com/tls:/tls:ro,Z" \
    -v "$FABRIC_X_ROOT/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp:/msp:ro,Z" \
    -v "$FABRIC_X_ROOT/crypto/peerOrganizations/org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem:/org-tls-ca.pem:ro,Z" \
    -v "$FABRIC_X_ROOT/crypto/ordererOrganizations/orderer.example.com/msp/tlscacerts/tlsca.orderer.example.com-cert.pem:/orderer-tls-ca.pem:ro,Z" \
    "$TOOLS_IMAGE" \
    sh -c 'fxconfig namespace list --config=/config/fxconfig.yaml 2>/dev/null | grep -q ") $FX_NS:" || \
      fxconfig namespace create "$FX_NS" --policy="$FX_POLICY" --endorse --submit --wait --config=/config/fxconfig.yaml'
}

namespaceList() {
  docker run --rm --network "$NETWORK" --user "$(id -u):$(id -g)" \
    -v "$FABRIC_X_ROOT/fxconfig.yaml:/config/fxconfig.yaml:ro,Z" \
    -v "$FABRIC_X_ROOT/crypto/peerOrganizations/org1.example.com/peers/fxconfig.org1.example.com/tls:/tls:ro,Z" \
    -v "$FABRIC_X_ROOT/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp:/msp:ro,Z" \
    -v "$FABRIC_X_ROOT/crypto/peerOrganizations/org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem:/org-tls-ca.pem:ro,Z" \
    -v "$FABRIC_X_ROOT/crypto/ordererOrganizations/orderer.example.com/msp/tlscacerts/tlsca.orderer.example.com-cert.pem:/orderer-tls-ca.pem:ro,Z" \
    "$TOOLS_IMAGE" \
    fxconfig namespace list --config=/config/fxconfig.yaml
}
