#!/usr/bin/env bash

printHelp() {
  echo "Fablo is powered by SoftwareMill"

  echo ""
  echo "usage: ./fabric-docker.sh <command>"
  echo ""

  echo "Commands: "
  echo ""
  echo "./fabric-docker.sh up"
  echo -e "\t Use for first run. Creates all needed artifacts (certs, genesis block) and starts network for the first time."
  echo -e "\t After 'up' commands start/stop are used to manage network and rerun to rerun it"
  echo ""
  echo "./fabric-docker.sh down"
  echo -e "\t Back to empty state - destorys created containers, prunes generated certificates, configs."
  echo ""
  echo "./fabric-docker.sh start"
  echo -e "\t Starts already created network."
  echo ""
  echo "./fabric-docker.sh stop"
  echo -e "\t Stops already running network."
  echo ""
  echo "./fabric-docker.sh reset"
  echo -e "\t Fresh start - it destroys whole network, certs, configs and then reruns everything."
  echo ""
  echo "./fabric-docker.sh channel --help"
  echo -e "\t Detailed help for channel management scripts."
  echo ""
}
