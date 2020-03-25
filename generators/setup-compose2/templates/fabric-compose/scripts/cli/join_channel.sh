#!/usr/bin/env bash
set -ev

echo "Joining channel with name: ${CHANNEL_NAME}"
echo "Peer addres: ${CORE_PEER_ADDRESS}"
echo "TLS_CA_CERT_PATH is : ${TLS_CA_CERT_PATH}"

mkdir -p /var/steps/joinchannel && cd /var/steps/joinchannel

peer channel fetch newest -c ${CHANNEL_NAME} --orderer ${ORDERER_URL} --tls --cafile $TLS_CA_CERT_PATH
peer channel join -b ${CHANNEL_NAME}_newest.block --tls --cafile $TLS_CA_CERT_PATH

rm -rf /var/steps/joinchannel
