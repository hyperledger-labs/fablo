#!/bin/sh

set -euo

tag=$1
login=$2
FABRICA_HOME="$(mktemp -d -t fabrica.XXXXXXXX)"

cleanup() {
  rm -rf "$FABRICA_HOME"
  docker logout
}

trap cleanup EXIT

git clone --depth 1 --branch "$tag" "https://github.com/softwaremill/fabrica" "$FABRICA_HOME"
"$FABRICA_HOME/fabrica-build.sh"
FABRICA_VERSION="$(jq -r '.version' "$FABRICA_HOME/package.json")"

echo "Pushing to docker hub.."
echo "   FABRICA_HOME: $FABRICA_HOME"
echo "   FABRICA_VERSION: $FABRICA_VERSION"
echo "   GIT_TAG:         $tag"

docker login -u "$login"
docker push softwaremill/fabrica:"$FABRICA_VERSION"
