#!/bin/sh

set -euo

login=$1
pass=$2

FABRICA_HOME="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=2002
FABRICA_VERSION=$(cat "$FABRICA_HOME"/package.json | jq -r '.version')

./fabrica-build.sh

echo "Pushing to docker hub.."
echo "   FABRICA_HOME:    $FABRICA_HOME"
echo "   FABRICA_VERSION: $FABRICA_VERSION"

docker login -u "$login" -p "$pass"

docker push softwaremill/fabrica:"$FABRICA_VERSION"

docker logout
