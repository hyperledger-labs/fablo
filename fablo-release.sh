#!/usr/bin/env sh

set -euo

tag=$1
login=$2
FABLO_HOME="$(mktemp -d -t fablo.XXXXXXXX)"

cleanup() {
  rm -rf "$FABLO_HOME"
  docker logout
}

trap cleanup EXIT

git clone --depth 1 --branch "$tag" "https://github.com/softwaremill/fablo" "$FABLO_HOME"
("$FABLO_HOME/check-if-fablo-version-matches.sh")

FABLO_VERSION="$(jq -r '.version' "$FABLO_HOME/package.json")"

echo "Pushing to Docker Hub..."
echo "   FABLO_HOME:    $FABLO_HOME"
echo "   FABLO_VERSION: $FABLO_VERSION"
echo "   GIT_TAG:       $tag"

# shellcheck disable=SC2039
read -r -p "Are you sure? [y/N] " response

# shellcheck disable=SC2039
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  (cd "$FABLO_HOME" && ./fablo-build.sh)
  docker login -u "$login"
  docker push softwaremill/fablo:"$FABLO_VERSION"
else
  echo "Aborted."
fi
