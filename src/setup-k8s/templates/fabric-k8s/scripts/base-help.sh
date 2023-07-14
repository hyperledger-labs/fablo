#!/usr/bin/env bash

printHelp() {
  echo "Fablo is powered by SoftwareMill"

  echo ""
  echo "usage: ./fabric-k8.sh <command>"
  echo ""

  echo "Commands: "
  echo ""
  echo "./fabric-k8.sh up"
  echo -e "\t Use for first run. Creates all needed artifacts (certs, genesis block) and starts network for the first time."
  echo -e "\t After 'up' commands start/stop are used to manage network and rerun to rerun it"
  echo ""
  echo "./fabric-k8.sh down"
  echo -e "\t Back to empty state - destorys created containers, prunes generated certificates, configs."
  echo ""
  echo "./fabric-k8.sh channel --help"
  echo -e "\t Detailed help for channel management scripts."
  echo ""
}
