#!/usr/bin/env bash

set -eu

# ========== CONFIGURATION ==========
CHAINCODE_NAME="chaincode1"
CHAINCODE_VERSION="0.0.1"
CHANNEL_NAME="my-channel1"
PEER_IP="0.0.0.0"
PEER_NAME="peer0.org1.example.com"
JAR_PATH="build/libs/chaincode-all.jar"

# ========== CHECK COMMANDS ==========
for cmd in docker java grep gradle awk; do
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

# ========== GET DYNAMIC CHAINCODE PORT FROM DOCKER ==========
CHAINCODE_PORT=$(docker port "$PEER_NAME" 7050 | grep '0.0.0.0' | awk -F: '{print $2}' | head -n1)

if [ -z "$CHAINCODE_PORT" ]; then
    echo "Error: Could not find mapped host port for container port 7050."
    exit 1
fi


echo "Testing connectivity to peer at $PEER_IP:$CHAINCODE_PORT..."
if ! nc -z $PEER_IP $CHAINCODE_PORT 2>/dev/null; then
    echo "Error: Cannot connect to peer chaincode port $PEER_IP:$CHAINCODE_PORT."
    echo "Ensure the peer is running in dev mode and listening on port $CHAINCODE_PORT."
    exit 1
fi

# ========== EXPORT ENVIRONMENT VARIABLES ==========
export CHAINCODE_SERVER_ADDRESS=0.0.0.0:$CHAINCODE_PORT
export CORE_CHAINCODE_ID_NAME="$CHAINCODE_NAME:$CHAINCODE_VERSION"
export CORE_CHAINCODE_LOGGING_LEVEL="DEBUG"
export CORE_CHAINCODE_LOGGING_SHIM="debug"
export CORE_PEER_ADDRESS="$PEER_IP:$CHAINCODE_PORT"
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

if java -jar "$JAR_PATH" -peer.address $PEER_IP:$CHAINCODE_PORT; then
    echo "========================================"
    echo "Successfully running Java in dev Mode"
    echo "========================================"
else
    echo "Error: Failed to start the chaincode JAR"
    exit 1
fi
