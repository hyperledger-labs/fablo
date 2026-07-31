#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_IMAGE="ghcr.io/hyperledger/fabric-x-tools:1.0.0"
COMPOSE_FILE="$SCRIPT_DIR/compose.test-committer.yaml"

initCrypto() {
  echo "Generating Fabric-X crypto material..."
  rm -rf "$SCRIPT_DIR/crypto"
  docker run --rm -v "$SCRIPT_DIR:/config" "$TOOLS_IMAGE" \
    sh -c 'cryptogen generate --config=/config/crypto-config.yaml --output=/config/crypto'
  docker run --rm -v "$SCRIPT_DIR:/config" -v "$SCRIPT_DIR/crypto:/crypto" \
    --entrypoint /usr/local/bin/armageddon "$TOOLS_IMAGE" \
    createSharedConfigProto --sharedConfigYaml=/config/shared_config.yaml --output=/config/crypto/
  docker run --rm -v "$SCRIPT_DIR:/config" "$TOOLS_IMAGE" \
    configtxgen --channelID mychannel --profile OrgsChannel \
    --outputBlock /config/crypto/config-block.pb.bin --configPath /config
}

start() {
  if [ ! -d "$SCRIPT_DIR/crypto" ]; then
    initCrypto
  fi
  docker compose -f "$COMPOSE_FILE" up -d
  echo "Waiting for test committer to be ready..."
  while ! nc -z localhost 7001 2>/dev/null; do sleep 1; done
  echo "Fabric-X network is up."
}

stop() {
  docker compose -f "$COMPOSE_FILE" down
}

down() {
  docker compose -f "$COMPOSE_FILE" down -v
  rm -rf "$SCRIPT_DIR/crypto" "$SCRIPT_DIR/data"
}

reset() {
  down
  start
}

namespaceList() {
  docker run --rm --network fabric-x -v "$SCRIPT_DIR/fxconfig.yaml:/config/fxconfig.yaml:ro" "$TOOLS_IMAGE" \
    fxconfig namespace list --config=/config/fxconfig.yaml
}

namespaceInit() {
  local ns="${1:-mynamespace}"
  local policy="${2:-AND('Org1MSP.member')}"
  docker run --rm --network fabric-x \
    --env "FX_NS=$ns" --env "FX_POLICY=$policy" \
    -v "$SCRIPT_DIR/fxconfig.yaml:/config/fxconfig.yaml:ro" "$TOOLS_IMAGE" \
    sh -c 'fxconfig namespace create "$FX_NS" --policy="$FX_POLICY" --endorse --submit --wait --config=/config/fxconfig.yaml'
}

case "$1" in
  up) start ;;
  start) start ;;
  stop) stop ;;
  down) down ;;
  reset) reset ;;
  namespace)
    case "$2" in
      list) namespaceList ;;
      init) namespaceInit "$3" "$4" ;;
      *) echo "Unknown namespace subcommand: $2"; exit 1 ;;
    esac
    ;;
  *) echo "Unknown command: $1"; exit 1 ;;
esac