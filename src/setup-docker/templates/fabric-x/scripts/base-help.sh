#!/usr/bin/env bash

printHelp() {
  echo "Fablo is powered by SoftwareMill"

  echo ""
  echo "usage: ./fabric-x-docker.sh <command>"
  echo ""

  echo "Network commands:"
  echo "  up             Generate artifacts and start the Fabric-X network"
  echo "  start          Start an existing Fabric-X network"
  echo "  stop           Stop the running Fabric-X network"
  echo "  down           Stop containers and remove generated crypto/data"
  echo "  reset          Run down, then up"
  echo ""

  echo "Namespace commands:"
  echo "  namespace list   List namespaces defined on the running network"
  echo "  namespace init   Create the default namespace (required for app-level"
  echo "                   submit/query, not required to bring the network up)"
  echo ""
}
