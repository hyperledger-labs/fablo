#!/bin/bash

set -euo

source ./fabrica.sh "help"

FABRICA_SCRIPT_VERSION="$FABRICA_VERSION"
FABRICA_NODE_VERSION="$(jq -r .version package.json)"

echo "Checking Fabrica version"
echo "    FABRICA_SCRIPT_VERSION: $FABRICA_SCRIPT_VERSION"
echo "    FABRICA_NODE_VERSION:   $FABRICA_NODE_VERSION"

if [ "$FABRICA_SCRIPT_VERSION" != "$FABRICA_NODE_VERSION" ]; then
  echo "Error !"
  echo "Fabrica version in 'fabrica.sh' is not matching version in 'package.json'"
  exit 1
fi
