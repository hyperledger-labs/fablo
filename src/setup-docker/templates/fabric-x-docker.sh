#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FABRICX_DIR="$SCRIPT_DIR/fabric-x"


export COMPOSE_FILE="$FABRICX_DIR/docker-compose.yaml"

TOOLS_IMAGE="${TOOLS_IMAGE:-ghcr.io/hyperledger/fabric-x-tools:1.0.0}"
ORDERER_IMAGE="${ORDERER_IMAGE:-ghcr.io/hyperledger/fabric-x-orderer:1.0.0}"
RUN_AS=(--user "$(id -u):$(id -g)")

NETWORK="${NETWORK:-fabric-x}"
DEFAULT_POLICY="AND('Org1MSP.member')"

COMMAND="$1"
SUBCOMMAND="$2"

generateArtifacts() {
  echo "Generating Fabric-X crypto material..."
  rm -rf "$FABRICX_DIR/crypto"
  docker run --rm "${RUN_AS[@]}" \
    -v "$FABRICX_DIR:/config" \
    "$TOOLS_IMAGE" \
    sh -c 'cryptogen generate --config=/config/crypto-config.yaml --output=/config/crypto \
      && cp /config/crypto/peerOrganizations/org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem \
            /config/crypto/client-tls-ca.pem'

  echo "Generating Fabric-X shared config proto..."
  docker run --rm "${RUN_AS[@]}" \
    -v "$FABRICX_DIR:/config" \
    -v "$FABRICX_DIR/crypto:/crypto" \
    --entrypoint /usr/local/bin/armageddon \
    "$ORDERER_IMAGE" \
    createSharedConfigProto \
    --sharedConfigYaml=/config/shared_config.yaml \
    --output=/config/crypto/

  echo "Generating Fabric-X genesis / config block..."
  docker run --rm "${RUN_AS[@]}" \
    -v "$FABRICX_DIR:/config" \
    "$TOOLS_IMAGE" \
    configtxgen --channelID mychannel --profile OrgsChannel \
    --outputBlock /config/crypto/config-block.pb.bin \
    --configPath /config
}


runFxconfig() {
  local ns="$1"
  local policy="$2"
  docker run --rm --network "$NETWORK" "${RUN_AS[@]}" \
    --env "FX_NS=$ns" \
    --env "FX_POLICY=$policy" \
    -v "$FABRICX_DIR/fxconfig.yaml:/config/fxconfig.yaml:ro,Z" \
    -v "$FABRICX_DIR/crypto/peerOrganizations/org1.example.com/peers/fxconfig.org1.example.com/tls:/tls:ro,Z" \
    -v "$FABRICX_DIR/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp:/msp:ro,Z" \
    -v "$FABRICX_DIR/crypto/peerOrganizations/org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem:/org-tls-ca.pem:ro,Z" \
    -v "$FABRICX_DIR/crypto/ordererOrganizations/orderer-org-1/msp/tlscacerts/tlsca.orderer-org-1-cert.pem:/orderer-tls-ca.pem:ro,Z" \
    "$TOOLS_IMAGE" \
    sh -c 'fxconfig namespace list --config=/config/fxconfig.yaml 2>/dev/null | grep -q ") $FX_NS:" || \
      fxconfig namespace create "$FX_NS" --policy="$FX_POLICY" --endorse --submit --wait --config=/config/fxconfig.yaml'
}

namespaceInit() {
  runFxconfig "mynamespace" "$DEFAULT_POLICY"
}

namespaceList() {
  docker run --rm --network "$NETWORK" "${RUN_AS[@]}" \
    -v "$FABRICX_DIR/fxconfig.yaml:/config/fxconfig.yaml:ro,Z" \
    -v "$FABRICX_DIR/crypto/peerOrganizations/org1.example.com/peers/fxconfig.org1.example.com/tls:/tls:ro,Z" \
    -v "$FABRICX_DIR/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp:/msp:ro,Z" \
    -v "$FABRICX_DIR/crypto/peerOrganizations/org1.example.com/msp/tlscacerts/tlsca.org1.example.com-cert.pem:/org-tls-ca.pem:ro,Z" \
    -v "$FABRICX_DIR/crypto/ordererOrganizations/orderer-org-1/msp/tlscacerts/tlsca.orderer-org-1-cert.pem:/orderer-tls-ca.pem:ro,Z" \
    "$TOOLS_IMAGE" \
    fxconfig namespace list --config=/config/fxconfig.yaml
}


fabricxUp() {
  if [ ! -d "$FABRICX_DIR/crypto" ]; then
    generateArtifacts
  fi
  docker compose up -d --wait
  namespaceInit
}

fabricxStart() {
  docker compose up -d --wait
}

fabricxStop() {
  docker compose down
}

fabricxDown() {
  docker compose down -v
  rm -rf "$FABRICX_DIR/crypto"
}

fabricxReset() {
  fabricxDown
  fabricxUp
}

fabricxNamespace() {
  case "$SUBCOMMAND" in
  list)
    namespaceList
    ;;
  init)
    namespaceInit
    ;;
  *)
    echo "Error: unknown namespace subcommand '$SUBCOMMAND'. Expected 'list' or 'init'."
    exit 1
    ;;
  esac
}

case "$COMMAND" in
up)
  fabricxUp
  ;;
start)
  fabricxStart
  ;;
stop)
  fabricxStop
  ;;
down)
  fabricxDown
  ;;
reset)
  fabricxReset
  ;;
namespace)
  fabricxNamespace
  ;;
*)
  echo "Error: unsupported Fabric-X command '$COMMAND'."
  exit 1
  ;;
esac