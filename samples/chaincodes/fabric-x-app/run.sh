#!/usr/bin/env bash
set -euo pipefail
FABLO_CONFIG="${1:?usage: run.sh <fablo-config.json> <path to fablo-target/fabric-x>}"
FABRIC_X_ROOT="${2:?usage: run.sh <fablo-config.json> <path to fablo-target/fabric-x>}"
FABRIC_X_ROOT="$(cd "$FABRIC_X_ROOT" && pwd)"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FXCONFIG="$FABRIC_X_ROOT/fxconfig.yaml"
CRYPTO="$FABRIC_X_ROOT/crypto"
NETWORK="${NETWORK:-fabric-x}"
GO_IMAGE="${GO_IMAGE:-golang:1.26}"

fxconfig_value() {
  awk -v section="$1:" -v key="$2:" '
    /^[a-zA-Z]/ { in_section = ($1 == section) }
    in_section && $1 == key { print $2; exit }
  ' "$FXCONFIG"
}

require() {
  if [ -z "$2" ] || [ "$2" = "null" ]; then
    echo "run.sh: could not read $1" >&2
    exit 1
  fi
}

ORG_DOMAIN="$(jq -r '.orgs[0].organization.domain' "$FABLO_CONFIG")"
NAMESPACE="${NAMESPACE:-$(jq -r '.namespaces[0].name' "$FABLO_CONFIG")}"
MSP_ID="$(fxconfig_value msp localMspID)"
CHANNEL="$(fxconfig_value orderer channel)"
ORDERER="$(fxconfig_value orderer address)"
SIDECAR="$(fxconfig_value notifications address)"

require "the org domain from $FABLO_CONFIG" "$ORG_DOMAIN"
require "the namespace from $FABLO_CONFIG" "$NAMESPACE"
require "msp.localMspID from $FXCONFIG" "$MSP_ID"
require "orderer.channel from $FXCONFIG" "$CHANNEL"
require "orderer.address from $FXCONFIG" "$ORDERER"
require "notifications.address from $FXCONFIG" "$SIDECAR"

CACHE_DIR="$APP_DIR/.cache"
mkdir -p "$CACHE_DIR"

if [ ! -f "$APP_DIR/go.sum" ]; then
  echo "run.sh: go.sum is missing, it will be created now. Commit it so that the run is reproducible." >&2
fi

docker run --rm --network "$NETWORK" --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e GOCACHE=/cache/build \
  -e GOMODCACHE=/cache/mod \
  -e GOFLAGS=-buildvcs=false \
  -v "$APP_DIR:/src:Z" \
  -v "$CACHE_DIR:/cache:Z" \
  -v "$CRYPTO/peerOrganizations/$ORG_DOMAIN/peers/fxconfig.$ORG_DOMAIN/tls:/tls:ro,Z" \
  -v "$CRYPTO/peerOrganizations/$ORG_DOMAIN/users/User1@$ORG_DOMAIN/msp:/msp:ro,Z" \
  -v "$CRYPTO/peerOrganizations/$ORG_DOMAIN/msp/tlscacerts/tlsca.$ORG_DOMAIN-cert.pem:/org-tls-ca.pem:ro,Z" \
  -v "$CRYPTO/ordererOrganizations:/orderer-cas:ro,Z" \
  -w /src \
  "$GO_IMAGE" \
  sh -c 'test -f go.sum || go mod tidy; go run . "$@"' sh \
  -channel "$CHANNEL" \
  -namespace "$NAMESPACE" \
  -msp-id "$MSP_ID" \
  -orderer "$ORDERER" \
  -sidecar "$SIDECAR"