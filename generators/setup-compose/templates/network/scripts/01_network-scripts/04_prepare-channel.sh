#!/usr/bin/env bash
set -ev

CHANNEL_NAME=sml-channel

#=== peer0 - Create & Join Channel ================================
docker exec -e CHANNEL_NAME=$CHANNEL_NAME cli /scripts/create_channel.sh

#=== peer1 - Fetch & Join Channel =================================
docker exec -e "CHANNEL_NAME=$CHANNEL_NAME" -e "CORE_PEER_ADDRESS=peer1.org1.softwaremill.com:7051" cli /scripts/join_channel.sh
