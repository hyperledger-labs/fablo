#!/bin/sh

if [ -z "$2" ]; then
  echo "Usage: docker-generate.sh ./fabrikka-config.json ./target-network-dir"
  exit 1
fi

fullPath() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

FABRIKKA_HOME="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$(fullPath "$1")"
TARGET="$(mkdir -p "$(dirname "$2")" && fullPath "$2")"

echo "Creating network config in $TARGET for $CONFIG"

docker build --tag fabrikka "$FABRIKKA_HOME" &&
  docker run \
    -v "$CONFIG":/network/config.json \
    -v "$TARGET":/network/target \
    fabrikka
