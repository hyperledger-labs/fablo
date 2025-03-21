#!/usr/bin/env bash

set -euo

FABLO_HOME="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=2002
FABLO_VERSION=$(cat "$FABLO_HOME"/package.json | jq -r '.version')

COMMIT_HASH=$(git rev-parse --short HEAD)
BUILD_DATE=$(date +'%Y-%m-%d-%H:%M:%S')
VERSION_DETAILS="$BUILD_DATE-$COMMIT_HASH"

echo "Building new image..."
echo "   FABLO_HOME:    $FABLO_HOME"
echo "   FABLO_VERSION: $FABLO_VERSION"
echo "   VERSION_DETAILS: $VERSION_DETAILS"

IMAGE_BASE_NAME="ghcr.io/fablo-io/fablo:$FABLO_VERSION"

if [ "$(command -v nvm)" != "nvm" ] && [ -f ~/.nvm/nvm.sh ]; then
  set +e
  # shellcheck disable=SC2039
  source ~/.nvm/nvm.sh
  set -e
fi
if [ "$(command -v nvm)" = "nvm" ]; then
  set +u
  nvm install
  set -u
fi

npm install
npm run build:dist

# if --push is passed, then build for all platforms and push the image to the registry
if [ "${1:-''}" = "--push" ]; then
  docker buildx build \
    --build-arg VERSION_DETAILS="$VERSION_DETAILS" \
    --platform linux/amd64,linux/arm64 \
    --tag "ghcr.io/fablo-io/fablo:$FABLO_VERSION" \
    --push \
    "$FABLO_HOME"
else
  docker build \
    --build-arg VERSION_DETAILS="$VERSION_DETAILS" \
    --tag "$IMAGE_BASE_NAME" "$FABLO_HOME"

  docker tag "$IMAGE_BASE_NAME" "ghcr.io/fablo-io/fablo:$FABLO_VERSION"
fi