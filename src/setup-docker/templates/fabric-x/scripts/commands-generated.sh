#!/usr/bin/env bash

printHeadline() {
  bold=$'\e[1m'
  end=$'\e[0m'
  TEXT=$1
  EMOJI=$2
  printf "${bold}============ %b %s %b ==============${end}\n" "\\$EMOJI" "$TEXT" "\\$EMOJI"
}

printStartSuccessInfo() {
  printHeadline "Done! Fabric-X network is up" "U1F984"
  echo "No namespace has been created yet - app-level submit/query calls need one first."
  echo "Run './fabric-x-docker.sh namespace init' to create the default namespace."
}

TOOLS_IMAGE="${TOOLS_IMAGE:-ghcr.io/hyperledger/fabric-x-tools:1.0.0}"
ORDERER_IMAGE="${ORDERER_IMAGE:-ghcr.io/hyperledger/fabric-x-orderer:1.0.0}"
NETWORK="${NETWORK:-fabric-x}"
DEFAULT_POLICY="AND('Org1MSP.member')"


generateArtifacts() {
  if [ -d "$FABRIC_X_ROOT/crypto" ]; then
    echo "Crypto material already exists, skipping generation."
    return
  fi

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
    --sharedConfigYaml=/config/shared-config.yml \
    --output=/config/crypto/

  echo "Generating Fabric-X genesis / config block..."
  docker run --rm --user "$(id -u):$(id -g)" \
    -v "$FABRIC_X_ROOT:/config" \
    "$TOOLS_IMAGE" \
    configtxgen --channelID mychannel --profile OrgsChannel \
    --outputBlock /config/crypto/config-block.pb.bin \
    --configPath /config
}


networkUp() {
  generateArtifacts
  (cd "$FABRIC_X_ROOT" && docker compose up -d --wait)
  printStartSuccessInfo
}


networkDown() {
  (cd "$FABRIC_X_ROOT" && docker compose down -v)
  rm -rf "$FABRIC_X_ROOT/crypto" "$FABRIC_X_ROOT/data"
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