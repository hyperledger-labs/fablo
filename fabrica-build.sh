#!/bin/sh

set -eu

FABRICA_HOME="$(cd "$(dirname "$0")" && pwd)"

NODE_IMAGE_TAG="12.18.0-alpine3.12"

COMMIT_HASH=$(git rev-parse --short HEAD)
BUILD_DATE=$(date +'%Y-%m-%d-%H:%M:%S')
VERSION_DETAILS="$BUILD_DATE-$COMMIT_HASH"

docker build \
  --build-arg NODE_IMAGE_TAG="$NODE_IMAGE_TAG" \
  --build-arg VERSION_DETAILS="$VERSION_DETAILS" \
  --tag fabrica "$FABRICA_HOME"
