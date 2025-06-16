#!/usr/bin/env bash

set -eu

# ========== CONFIGURATION ==========
CHAINCODE_NAME="chaincode1"
CHAINCODE_VERSION="0.0.1"
CHANNEL_NAME="my-channel1"
PEER_NAME="peer0.org1.example.com"
JAR_PATH="build/libs/java-chaincode-1.0-SNAPSHOT-all.jar"

# ========== CHECK COMMANDS ==========
for cmd in docker java grep gradle; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: '$cmd' command not found. Please install it first."
        exit 1
    fi
done

# ========== BUILD THE JAR ==========
gradle wrapper
./gradlew clean shadowJar

if [ ! -f "$JAR_PATH" ]; then
    echo "Error: JAR file was not created. Build may have failed."
    exit 1
fi

# ========== VALIDATE PEER CONTAINER ==========
if ! docker ps | grep -q "$PEER_NAME"; then
    echo "Error: $PEER_NAME container is not running."
    echo "Please make sure the Fabric network is up and running."
    exit 1
fi




# ========== GET PEER IP ==========
PEER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PEER_NAME)
if [ -z "$PEER_IP" ]; then
    echo "Error: Could not find $PEER_NAME IP address."
    exit 1
fi

echo "Testing connectivity to peer at $PEER_IP:7041..."
if ! nc -z $PEER_IP 7041 2>/dev/null; then
    echo "Error: Cannot connect to peer chaincode port $PEER_IP:7041."
    echo "Ensure the peer is running in dev mode and listening on port 7041."
    exit 1
fi


# ========== EXPORT ENVIRONMENT VARIABLES ==========
export CORE_CHAINCODE_ID_NAME="$CHAINCODE_NAME:$CHAINCODE_VERSION"
# export CORE_CHAINCODE_SERVER_ADDRESS="0.0.0.0:7041"
export CORE_CHAINCODE_LISTENADDRESS=0.0.0.0:7041
export CORE_CHAINCODE_LOGGING_LEVEL="DEBUG"
export CORE_CHAINCODE_LOGGING_SHIM="debug"
export CORE_PEER_ADDRESS="$PEER_IP:7041"               
export CORE_PEER_LOCALMSPID="Org1MSP"                   
export CORE_PEER_TLS_ENABLED=false
export CORE_CHAINCODE_LOGLEVEL=debug
export FABRIC_LOGGING_SPEC=debug 

# ========== RUN CHAINCODE ==========
echo "========================================"
echo "Running Java chaincode in dev mode..."
echo "Chaincode Name: $CORE_CHAINCODE_ID_NAME"
echo "Peer Address: $CORE_PEER_ADDRESS"
echo "========================================"

if java -jar "$JAR_PATH" -peer.address $PEER_IP:7041; then
    echo "========================================"
    echo "Successfully running Java in dev Mode"
    echo "========================================"
else
    echo "Error: Failed to start the chaincode JAR"
    exit 1
fi