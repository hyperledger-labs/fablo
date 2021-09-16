#!/usr/bin/env bash

set -euo

source ./fablo.sh "help"

FABLO_SCRIPT_VERSION="$FABLO_VERSION"
FABLO_NODE_VERSION="$(jq -r .version package.json)"

echo "Checking Fablo version"
echo "    FABLO_SCRIPT_VERSION: $FABLO_SCRIPT_VERSION"
echo "    FABLO_NODE_VERSION:   $FABLO_NODE_VERSION"

if [ "$FABLO_SCRIPT_VERSION" != "$FABLO_NODE_VERSION" ]; then
  echo "Error !"
  echo "Fablo version in 'fablo.sh' is not matching version in 'package.json'"
  exit 1
fi
