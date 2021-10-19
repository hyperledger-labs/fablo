#!/usr/bin/env bash

# This script runs linter for bash and YAML files in Fablo root and for
# generated network configs in 'e2e/__tmp__' directory. It fails if generated
# network configs are missing.
#
# Required libs: shellcheck and yamllint

set -e

FABLO_HOME="$(dirname "$0")"
shellcheck "$FABLO_HOME"/*.sh
shellcheck "$FABLO_HOME"/e2e-network/*.sh

for config in samples/fablo-config-*; do
  network="$FABLO_HOME/e2e/__tmp__/${config}.tmpdir"

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
