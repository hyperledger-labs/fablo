#!/bin/sh

FABRIKKA_HOME="$(cd "$(dirname "$0")" && pwd)"

CONFIG="$1"
TARGET="$2"

if [ -z "$TARGET" ]; then
  echo "Usage: docker-generate.sh ./fabrikka-config.json ./target-network"
  exit 1
fi

echo "Creating network config for $CONFIG in $TARGET"

docker build --tag fabrikka "$FABRIKKA_HOME" &&
  docker run \
    -v "$CONFIG":/network/config.json \
    -v "$TARGET":/network/target \
    fabrikka
