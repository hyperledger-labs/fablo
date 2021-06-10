#!/usr/bin/env bash

# This script runs linter for bash and YAML files in Fabrica root and for
# generated network configs in 'e2e/__tmp__' directory. It fails if generated
# network configs are missing.
#
# Required libs: shellcheck and yamllint

set -e

FABRICA_HOME="$(dirname "$0")"
shellcheck "$FABRICA_HOME"/*.sh
shellcheck "$FABRICA_HOME"/e2e-network/*.sh

for config in samples/fabrica-config-*; do
  network="$FABRICA_HOME/e2e/__tmp__/${config}.tmpdir"

  if [ -z "$(ls -A "$network")" ]; then
    echo "Missing network $network"
    exit 1
  fi

  echo "Linting network $network"

  # shellcheck disable=2044
  for file in $(find "$network" -name "*.sh"); do
    shellcheck "$file"
  done

  yamllint "$network"

done
