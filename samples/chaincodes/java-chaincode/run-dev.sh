#!/usr/bin/env bash

set -eu

echo "Checking if chaincode is installed and running..."

if ! docker exec peer0.org1.example.com peer chaincode list --installed 2>/dev/null | grep -q "simple-asset"; then
    echo "ERROR: Chaincode 'simple-asset' is not installed on the peer."
    echo "Please install the chaincode first"
    exit 1
fi


if ! docker exec peer0.org1.example.com peer chaincode list --instantiated -C mychannel 2>/dev/null | grep -q "simple-asset"; then
    echo "ERROR: Chaincode 'simple-asset' is not committed to the channel."
    echo "Please commit the chaincode first."
    exit 1
fi


./gradlew clean shadowJar

if [ ! -f "build/libs/java-chaincode-1.0-SNAPSHOT-all.jar" ]; then
    echo "Error: JAR file was not created. Build may have failed."
    exit 1
fi

if ! docker ps | grep -q "peer0.org1.example.com"; then
    echo "Error: peer0.org1.example.com container is not running."
    echo "Please make sure the Fabric network is up and running."
    exit 1
fi

# Get the IP address of peer0.org1.example.com
peer_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' peer0.org1.example.com)
if [ -z "$peer_ip" ]; then
  echo "Error: Could not find peer0.org1.example.com IP address."
  exit 1
fi
# Run the chaincode in dev mode
CORE_CHAINCODE_LOGLEVEL=debug \
CORE_PEER_TLS_ENABLED=true \
CORE_CHAINCODE_ID_NAME=simple-asset:1.0 \
CORE_PEER_ADDRESS=$peer_ip:7051 \
CORE_CHAINCODE_LOGGING_LEVEL=DEBUG \
CORE_CHAINCODE_LOGGING_SHIM=debug \
java -jar build/libs/java-chaincode-1.0-SNAPSHOT-all.jar
