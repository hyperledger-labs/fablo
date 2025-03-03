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
TOOLS_IMAGE_BASE_NAME="ghcr.io/fablo-io/fabric-tools:3.0.0"

build_and_push_tools() {
    local platform
    local arch
    
    platform=$(uname -s | tr '[:upper:]' '[:lower:]')
    case $(uname -m) in
        x86_64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        *)
            echo "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac

    if [ "${1:-''}" = "--push" ]; then
        docker buildx build \
            --build-arg FABRIC_VERSION=3.0.0 \
            --build-arg ARCH="$arch" \
            --build-arg PLATFORM="$platform" \
            --platform linux/amd64,linux/arm64 \
            --tag "$TOOLS_IMAGE_BASE_NAME" \
            --push \
            "$FABLO_HOME/fabric-tools"
    else
        docker build \
            --build-arg FABRIC_VERSION=3.0.0 \
            --build-arg ARCH="$arch" \
            --build-arg PLATFORM="$platform" \
            --tag "$TOOLS_IMAGE_BASE_NAME" \
            "$FABLO_HOME/fabric-tools"
    fi
}

build_and_push_fablo() {
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

    if [ "${1:-''}" = "--push" ]; then
        docker buildx build \
            --build-arg VERSION_DETAILS="$VERSION_DETAILS" \
            --platform linux/amd64,linux/arm64 \
            --tag "$IMAGE_BASE_NAME" \
            --push \
            "$FABLO_HOME"
    else
        docker build \
            --build-arg VERSION_DETAILS="$VERSION_DETAILS" \
            --tag "$IMAGE_BASE_NAME" "$FABLO_HOME"

        docker tag "$IMAGE_BASE_NAME" "ghcr.io/fablo-io/fablo:$FABLO_VERSION"
    fi
}

if [ "${1:-''}" = "tools" ]; then
    build_and_push_tools "${2:-''}"
else
    build_and_push_fablo "${1:-''}"
fi