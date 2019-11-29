#!/usr/bin/env bash
set -ev

cd ../network-config

CHANNEL_NAME=sml-channel

configtxgen -profile OneOrgOrdererGenesis -outputBlock ./config/genesis.block

configtxgen -profile OneOrgChannel -outputCreateChannelTx ./config/channel.tx -channelID ${CHANNEL_NAME}

configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./config/Org1MSPanchors.tx -channelID ${CHANNEL_NAME} -asOrg Org1MSP