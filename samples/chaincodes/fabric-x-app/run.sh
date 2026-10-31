#!/usr/bin/env bash


set -euo pipefail

FABRIC_X_ROOT="${1:?usage: run.sh <path to fablo-target/fabric-x>}"
FABRIC_X_ROOT="$(cd "$FABRIC_X_ROOT" && pwd)"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CHANNEL="${CHANNEL:?CHANNEL is required}"
NAMESPACE="${NAMESPACE:?NAMESPACE is required}"
MSP_ID="${MSP_ID:?MSP_ID is required}"
ORG_DOMAIN="${ORG_DOMAIN:?ORG_DOMAIN is required}"
ORG_SLUG="${ORG_SLUG:?ORG_SLUG is required}"

NETWORK="${NETWORK:-fabric-x}"
GO_IMAGE="${GO_IMAGE:-golang:1.26}"
ORDERER_ADDR="${ORDERER_ADDR:-orderer-router:7050}"
SIDECAR_ADDR="${SIDECAR_ADDR:-committer-$ORG_SLUG-sidecar:4001}"

CRYPTO="$FABRIC_X_ROOT/crypto"
CACHE_DIR="$APP_DIR/.cache"
mkdir -p "$CACHE_DIR"

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
  -v "$CRYPTO/ordererOrganizations/orderer.example.com/msp/tlscacerts/tlsca.orderer.example.com-cert.pem:/orderer-tls-ca.pem:ro,Z" \
  -w /src \
  "$GO_IMAGE" \
  sh -c 'test -f go.sum || go mod tidy; go run . "$@"' sh \
  --channel "$CHANNEL" \
  --msp-id "$MSP_ID" \
  --namespace "$NAMESPACE" \
  --orderer "$ORDERER_ADDR" \
  --sidecar "$SIDECAR_ADDR"
