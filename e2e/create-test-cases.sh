#!/usr/bin/env bash

set -e

FABRICA_HOME="$(dirname "$0")/.."

(
  cd "$FABRICA_HOME/samples"
  for f in fabrica-config-*; do
    echo "import performTests from \"./performTests\";

const config = \"samples/$f\";

describe(config, () => {
  performTests(config);
});" >"../e2e/${f}.test.ts"
  done
)
