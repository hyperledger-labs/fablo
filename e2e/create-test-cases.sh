#!/usr/bin/env bash

set -e

FABLO_HOME="$(dirname "$0")/.."

cd "$FABLO_HOME/samples"

for f in fablo-config-*; do
    cat > "../e2e/${f}.test.ts" <<EOF
import performTests from "./performTests";

const config = "samples/$f";

describe(config, () => {
  performTests(config);
});
EOF
done
