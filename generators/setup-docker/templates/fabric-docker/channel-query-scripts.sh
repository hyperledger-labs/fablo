#!/usr/bin/env bash

source "$FABRICA_NETWORK_ROOT/fabric-docker/scripts/channel-query-functions.sh"

set -eu

function channelQuery() {

if [ "$#" -eq 1 ]; then
  printChannelsHelp
<% orgs.forEach(function(org) { org.peers.forEach(function(peer) { %>
elif [ "$1" = "list" ] && [ "$2" = "<%= org.name.toLowerCase(); %>" ] && [ "$3" = "<%= peer.name %>" ]; then
  <% if(!networkSettings.tls) { -%>
    peerChannelList "<%= org.cli.address %>" "<%= peer.fullAddress %>"
  <% } else { -%>
    peerChannelListTls "<%= org.cli.address %>" "$<%= peer.fullAddress %>" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
<% })}) %>

<% channels.forEach(function(channel) { channel.orgs.forEach(function(org) { %>
elif [ "$1" = "getinfo" ] && [ "$2" = "<%= channel.name %>" ] && [ "$3" = "<%= org.mspName.toLowerCase(); %>" ] && [ -n "$4" ]; then
  PEER_NAME=$4
  <% if(!networkSettings.tls) { -%>
    peerChannelGetInfo "<%= channel.name %>" "<%= org.cli.address %>" "${PEER_NAME}.<%= org.domain %>:7051"
  <% } else { -%>
    peerChannelGetInfoTls "<%= channel.name %>" "<%= org.cli.address %>" "${PEER_NAME}.<%= org.domain %>:7051" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "config" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.mspName.toLowerCase(); %>" ] && [ "$#" = 5 ]; then
  FILE_NAME=$5
  <% if(!networkSettings.tls) { -%>
    peerChannelFetchConfigDefault "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}"
  <% } else { -%>
    peerChannelFetchConfigDefaultTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "config" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.mspName.toLowerCase(); %>" ] && [ "$#" = 6 ]; then
  FILE_NAME=$6
  PEER_NAME=$7
  <% if(!networkSettings.tls) { -%>
    peerChannelFetchConfig "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${PEER_NAME}.<%= org.domain %>:7051"
  <% } else { -%>
    peerChannelFetchConfigTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${PEER_NAME}.<%= org.domain %>:7051" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "lastBlock" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.mspName.toLowerCase(); %>" ] && [ "$#" = 5 ]; then
  FILE_NAME=$6
  <% if(!networkSettings.tls) { -%>
    peerChannelFetchLastBlockDefault "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}"
  <% } else { -%>
    peerChannelFetchLastBlockDefaultTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "lastBlock" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.mspName.toLowerCase(); %>" ] && [ "$#" = 6 ]; then
  FILE_NAME=$6
  PEER_NAME=$7
  <% if(!networkSettings.tls) { -%>
    peerChannelFetchLastBlock "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${PEER_NAME}.<%= org.domain %>:7051"
  <% } else { -%>
    peerChannelFetchLastBlockTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${PEER_NAME}.<%= org.domain %>:7051" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "firstBlock" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.mspName.toLowerCase(); %>" ] && [ "$#" = 5 ]; then
  FILE_NAME=$6
  <% if(!networkSettings.tls) { -%>
    peerChannelFetchFirstBlockDefault "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}"
  <% } else { -%>
    peerChannelFetchFirstBlockDefaultTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "firstBlock" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.mspName.toLowerCase(); %>" ] && [ "$#" = 6 ]; then
  FILE_NAME=$6
  PEER_NAME=$7
  <% if(!networkSettings.tls) { -%>
    peerChannelFetchFirstBlockDefault "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${PEER_NAME}.<%= org.domain %>:7051"
  <% } else { -%>
    peerChannelFetchFirstBlockDefaultTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${PEER_NAME}.<%= org.domain %>:7051" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "block" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.mspName.toLowerCase(); %>" ] && [ "$#" = 6 ]; then
  FILE_NAME=$6
  BLOCK_NUMBER=$7
  <% if(!networkSettings.tls) { -%>
    peerChannelFetchBlockDefault "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${BLOCK_NUMBER}"
  <% } else { -%>
    peerChannelFetchBlockDefaultTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${BLOCK_NUMBER}" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "block" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.mspName.toLowerCase(); %>" ] && [ "$#" = 7 ]; then
  FILE_NAME=$6
  BLOCK_NUMBER=$7
  PEER_NAME=$8
  <% if(!networkSettings.tls) { -%>
    peerChannelFetchBlock "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${BLOCK_NUMBER}" "${PEER_NAME}.<%= org.domain %>:7051"
  <% } else { -%>
    peerChannelFetchBlockTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${BLOCK_NUMBER}" "${PEER_NAME}.<%= org.domain %>:7051" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } %>
<% })}) %>
else
  printChannelsHelp
fi

}

function printChannelsHelp() {
  echo "Channel managment commands:"
  echo ""
  <% orgs.forEach(function(org) { org.peers.forEach(function(peer) { %>
    echo "fabrica channel list <%= org.name.toLowerCase(); %> <%= peer.name %>"
    echo -e "\t List channels on '<%= peer.name %>' of '<%= org.name %>'".
    echo ""
  <% })}) %>
  <% channels.forEach(function(channel) { channel.orgs.forEach(function(org) { %>
    echo "fabrica channel getinfo <%= channel.name %> <%= org.name.toLowerCase(); %> <peer0>"
    echo -e "\t Get channel info on given peer of <%= org.name %>".
    echo ""
    echo "fabrica channel fetch config <%= channel.name %> <%= org.name.toLowerCase(); %> <fileName.json> [peer0]"
    echo -e "\t Download latest config block to current dir. By default it uses first peer of <%= org.name %>".
    echo ""
    echo "fabrica channel fetch lastBlock <%= channel.name %> <%= org.name.toLowerCase(); %> <fileName.json> [peer0]"
    echo -e "\t Download last, decrypted block to current dir. By default it uses first peer of <%= org.name %>".
    echo ""
    echo "fabrica channel fetch firstBlock <%= channel.name %> <%= org.name.toLowerCase(); %> <fileName.json> [peer0]"
    echo -e "\t Download first, decrypted block to current dir. By default it uses first peer of <%= org.name %>".
    echo ""
  <% })}) %>
}
