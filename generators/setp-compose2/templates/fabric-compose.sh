#!/bin/bash

function printHelp() {
  echo 'Fabrikka is powered by SoftwareMill'
  echo 'Usage: '
  echo ''
}

function certsRemove() {
  local CERTS_DIR_PATH=$1
  rm -rf "$CERTS_DIR_PATH"/*
}

function certsGenerate() {
  local CONTAINER_NAME=certGen

  local CONFIG_PATH=$1
  local OUTPUT_PATH=$2

  docker run -it -d --name $CONTAINER_NAME hyperledger/fabric-tools:${FABRIC_VERSION} bash
  docker cp $CONFIG_PATH $CONTAINER_NAME:/fabric-config

  docker exec -it $CONTAINER_NAME cryptogen generate --config=./fabric-config/crypto-config.yaml

  docker cp $CONTAINER_NAME:/crypto-config $OUTPUT_PATH
  docker rm -f $CONTAINER_NAME

  for file in $(find $OUTPUT_PATH/ -iname *_sk); do dir=$(dirname $file); mv ${dir}/*_sk ${dir}/private-key.pem; done
}


source fabric-compose/.env

certsGenerate "fabric-config" "./fabric-config/crypto-config"

