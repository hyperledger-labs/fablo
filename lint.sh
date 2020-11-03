#!/bin/bash

# This script runs linter for all Fabrikka script/yaml files and for generated
# network configs in 'e2e-network' directory. It fails if generated network
# configs are missing.
#
# Required libs: shellcheck and yamllint

set -e

FABRIKKA_HOME="$(dirname "$0")"
shellcheck "$FABRIKKA_HOME"/*.sh

E2E_NETWORK="$FABRIKKA_HOME/e2e-network"
yamllint "$E2E_NETWORK"

# wildcards like **/*.sh does not work on MacOS
# shellcheck disable=2044
for file in $(find "$E2E_NETWORK" -name "*.sh"); do
  shellcheck "$file"
done

for t in "$E2E_NETWORK"/test-*.sh; do
  if [ -z "$(ls -A "$t.tmpdir")" ]; then
    echo "Missing network in $t.tmpdir"
    exit 1
  fi
done
