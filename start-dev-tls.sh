#!/bin/bash
set -euo pipefail

# Get absolute paths - the script should be run from the chaincode directory
CURRENT_DIR="$(pwd)"
CRYPTO_CONFIG_DIR="${CURRENT_DIR}/../../fablo-target/fabric-config/crypto-config"
TLS_DIR="${CRYPTO_CONFIG_DIR}/ccaas/chaincode1/tls"

export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_A

# Set up TLS environment variables for chaincode
export CORE_PEER_TLS_ENABLED=true
# export CORE_PEER_TLS_ROOTCERT_FILE=${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# export CORE_PEER_TLS_ROOTCERT_FILE=${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/users/Admin@org1.example.com/tls/ca.crt
# export CORE_TLS_CLIENT_KEY_PATH=${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/users/Admin@org1.example.com/tls/client.key
# export CORE_TLS_CLIENT_CERT_PATH=${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/users/Admin@org1.example.com/tls/client.crt
# export CORE_PEER_TLS_ROOTCERT_FILE=${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
# export CORE_TLS_CLIENT_KEY_PATH=${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key
# export CORE_TLS_CLIENT_CERT_PATH=${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt
# export CORE_PEER_TLS_ROOTCERT_FILE="${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
# export CORE_TLS_CLIENT_KEY_PATH_RAW="${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key"
# export CORE_TLS_CLIENT_CERT_PATH_RAW="${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt"

export CORE_PEER_TLS_ROOTCERT_FILE="${CRYPTO_CONFIG_DIR}/ccaas/chaincode1/tls/peer.crt"
export CORE_TLS_CLIENT_KEY_PATH_RAW="${CRYPTO_CONFIG_DIR}/ccaas/chaincode1/tls/client.key"
export CORE_TLS_CLIENT_CERT_PATH_RAW="${CRYPTO_CONFIG_DIR}/ccaas/chaincode1/tls/client.crt"

export CORE_TLS_CLIENT_KEY_PATH=$CORE_TLS_CLIENT_KEY_PATH_RAW.b64
cat $CORE_TLS_CLIENT_KEY_PATH_RAW | base64 > $CORE_TLS_CLIENT_KEY_PATH

export CORE_TLS_CLIENT_CERT_PATH=$CORE_TLS_CLIENT_CERT_PATH_RAW.b64
cat $CORE_TLS_CLIENT_CERT_PATH_RAW | base64 > $CORE_TLS_CLIENT_CERT_PATH

echo "CORE_PEER_TLS_ENABLED: ${CORE_PEER_TLS_ENABLED}"
echo "CORE_PEER_TLS_ROOTCERT_FILE: ${CORE_PEER_TLS_ROOTCERT_FILE}"
echo "CORE_TLS_CLIENT_KEY_PATH: ${CORE_TLS_CLIENT_KEY_PATH}"
echo "CORE_TLS_CLIENT_CERT_PATH: ${CORE_TLS_CLIENT_CERT_PATH}"

echo "Content of client cert:"
head -n 5 "${CORE_TLS_CLIENT_CERT_PATH}"
echo "..."
echo "Content of client key:"
head -n 5 "${CORE_TLS_CLIENT_KEY_PATH}"
echo "..."
echo "Content of root cert:"
head -n 5 "${CORE_PEER_TLS_ROOTCERT_FILE}"
echo "..."

export GRPC_TRACE=all
export GRPC_VERBOSITY=DEBUG

CORE_PEER_LOCALMSPID=Org1MSP

PEER_ADDRESS="localhost:8541"
# PEER_ADDRESS="peer0.org1.example.com:8541"

# Start the chaincode with TLS enabled
npx fabric-chaincode-node start \
  --peer.address "${PEER_ADDRESS}" \
  --chaincode-id-name "chaincode1:0.0.1" \
  --ssl-target-name-override "peer0.org1.example.com"

# localhost:7041 => Error: 12 UNIMPLEMENTED: unknown service protos.ChaincodeSupport
# localhost:8041 => Error: 14 UNAVAILABLE: No connection established. Last error: 004C49F901000000:error:0A00010B:SSL routines:ssl3_get_record:wrong version number
# localhost:8541 => Error: 14 UNAVAILABLE: No connection established. Last error: unable to verify the first certificate (2025-10-15T21:58:41.795Z)