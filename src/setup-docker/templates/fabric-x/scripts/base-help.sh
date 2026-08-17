#!/usr/bin/env bash

printHelp() {
  echo "Fablo is powered by SoftwareMill"

  echo ""
  echo "usage: ./fabric-x-docker.sh <command>"
  echo ""

  echo "Commands: "
  echo ""
  echo "./fabric-x-docker.sh up"
  echo -e "\t Use for first run. Generates crypto material and config artifacts, then starts the Fabric-X network."
  echo -e "\t After 'up', start/stop manage the network, and reset reruns it from scratch."
  echo ""
  echo "./fabric-x-docker.sh down"
  echo -e "\t Back to empty state - destroys containers, removes generated crypto material and data."
  echo ""
  echo "./fabric-x-docker.sh start"
  echo -e "\t Starts an already created network."
  echo ""
  echo "./fabric-x-docker.sh stop"
  echo -e "\t Stops an already running network."
  echo ""
  echo "./fabric-x-docker.sh reset"
  echo -e "\t Fresh start - destroys the whole network, crypto material and data, then reruns everything."
  echo ""
  echo "./fabric-x-docker.sh namespace list"
  echo -e "\t Lists namespaces defined on the running network."
  echo ""
  echo "./fabric-x-docker.sh namespace init"
  echo -e "\t Creates the default namespace. Required before submitting or querying at the app level -"
  echo -e "\t not required just to bring the network up."
 
}