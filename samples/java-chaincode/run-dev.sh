#!/bin/bash

# Build the chaincode (using shadowJar)
./gradlew clean shadowJar

peer_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' peer0.org1.example.com)
if [ -z "$peer_ip" ]; then
  echo "Error: Could not find peer0.org1.example.com IP address."
  exit 1
fi
# Run the chaincode in dev mode
CORE_CHAINCODE_LOGLEVEL=debug \
CORE_PEER_TLS_ENABLED= true \
CORE_CHAINCODE_ID_NAME=simple-asset:1.0 \
CORE_PEER_ADDRESS=$peer_ip:7051 \
java -jar build/libs/java-chaincode-1.0-SNAPSHOT-all.jar
