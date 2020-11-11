#!/bin/bash

# This script runs linter for bash and YAML files in Fabrikka root and for
# generated network configs in 'e2e/__tmp__' directory. It fails if generated
# network configs are missing.
#
# Required libs: shellcheck and yamllint

set -e

FABRIKKA_HOME="$(dirname "$0")"
shellcheck "$FABRIKKA_HOME"/*.sh

EXPECTED_NETWORKS=(
  "$FABRIKKA_HOME/e2e/__tmp__/network-01-simple"
  "$FABRIKKA_HOME/e2e/__tmp__/network-02-simple-tls"
  "$FABRIKKA_HOME/e2e/__tmp__/network-03-simple-raft"
  "$FABRIKKA_HOME/e2e/__tmp__/network-04-2orgs"
  "$FABRIKKA_HOME/e2e/__tmp__/network-05-2orgs-tls"
  "$FABRIKKA_HOME/e2e/__tmp__/network-06-2orgs-raft"
)

for network in "${EXPECTED_NETWORKS[@]}"; do
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
