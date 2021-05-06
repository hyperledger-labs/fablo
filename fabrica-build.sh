#!/bin/sh

set -euo

FABRICA_HOME="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=2002
FABRICA_VERSION=$(cat "$FABRICA_HOME"/package.json | jq -r '.version')

COMMIT_HASH=$(git rev-parse --short HEAD)
BUILD_DATE=$(date +'%Y-%m-%d-%H:%M:%S')
VERSION_DETAILS="$BUILD_DATE-$COMMIT_HASH"

echo "Building new image..."
echo "   FABRICA_HOME:    $FABRICA_HOME"
echo "   FABRICA_VERSION: $FABRICA_VERSION"
echo "   VERSION_DETAILS: $VERSION_DETAILS"

IMAGE_BASE_NAME="softwaremill/fabrica:$FABRICA_VERSION"

npm run build:dist

docker build \
  --build-arg VERSION_DETAILS="$VERSION_DETAILS" \
  --tag "$IMAGE_BASE_NAME" "$FABRICA_HOME"

docker tag "$IMAGE_BASE_NAME" "softwaremill/fabrica:$FABRICA_VERSION"

