#!/usr/bin/env bash

source "$FABLO_NETWORK_ROOT/fabric-docker/scripts/channel-query-functions.sh"

set -eu

channelQuery() {
  echo "-> Channel query: " + "$@"

if [ "$#" -eq 1 ]; then
  printChannelsHelp
<% orgs.forEach((org) => { org.peers.forEach((peer) => { %>
elif [ "$1" = "list" ] && [ "$2" = "<%= org.name.toLowerCase(); %>" ] && [ "$3" = "<%= peer.name %>" ]; then
  <% if(!global.tls) { %>
    peerChannelList "<%= org.cli.address %>" "<%= peer.fullAddress %>"
  <% } else { %>
    peerChannelListTls "<%= org.cli.address %>" "<%= peer.fullAddress %>" "crypto-orderer/tlsca.<%= ordererGroups[0].ordererHeads[0].domain %>-cert.pem"
  <% } %>
<% })}) %>

<% channels.forEach((channel) => { channel.orgs.forEach((org) => { org.peers.forEach((peer) => { %>
elif [ "$1" = "getinfo" ] && [ "$2" = "<%= channel.name %>" ] && [ "$3" = "<%= org.name.toLowerCase(); %>" ] && [ "$4" = "<%= peer.name %>" ]; then
  <% if(!global.tls) { %>
    peerChannelGetInfo "<%= channel.name %>" "<%= org.cli.address %>" "<%= peer.fullAddress %>"
  <% } else { %>
    peerChannelGetInfoTls "<%= channel.name %>" "<%= org.cli.address %>" "<%= peer.fullAddress %>" "crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "config" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.name.toLowerCase(); %>" ] && [ "$5" = "<%= peer.name %>" ] && [ "$#" = 7 ]; then
  FILE_NAME=$6
  <% if(!global.tls) { %>
    peerChannelFetchConfig "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "<%= peer.fullAddress %>"
  <% } else { %>
    peerChannelFetchConfigTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "<%= peer.fullAddress %>" "crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "lastBlock" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.name.toLowerCase(); %>" ] && [ "$5" = "<%= peer.name %>" ] && [ "$#" = 7 ]; then
  FILE_NAME=$6
  <% if(!global.tls) { %>
    peerChannelFetchLastBlock "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "<%= peer.fullAddress %>"
  <% } else { %>
    peerChannelFetchLastBlockTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "<%= peer.fullAddress %>" "crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "firstBlock" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.name.toLowerCase(); %>" ] && [ "$5" = "<%= peer.name %>" ] && [ "$#" = 7 ]; then
  FILE_NAME=$6
  <% if(!global.tls) { %>
    peerChannelFetchFirstBlock "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "<%= peer.fullAddress %>"
  <% } else { %>
    peerChannelFetchFirstBlockTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "<%= peer.fullAddress %>" "crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$2" = "block" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.name.toLowerCase(); %>" ] && [ "$5" = "<%= peer.name %>" ] && [ "$#" = 8 ]; then
  FILE_NAME=$6
  BLOCK_NUMBER=$7
  <% if(!global.tls) { %>
    peerChannelFetchBlock "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${BLOCK_NUMBER}" "<%= peer.fullAddress %>"
  <% } else { %>
    peerChannelFetchBlockTls "<%= channel.name %>" "<%= org.cli.address %>" "${FILE_NAME}" "${BLOCK_NUMBER}" "<%= peer.fullAddress %>" "crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem"
  <% } %>
<% })})}) %>
else
  printChannelsHelp
fi

}

printChannelsHelp() {
  echo "Channel management commands:"
  echo ""
  <% orgs.forEach((org) => { org.peers.forEach((peer) => { %>
    echo "fablo channel list <%= org.name.toLowerCase(); %> <%= peer.name %>"
    echo -e "\t List channels on '<%= peer.name %>' of '<%= org.name %>'".
    echo ""
  <% })}) %>
  <% channels.forEach((channel) => { channel.orgs.forEach((org) => { org.peers.forEach((peer) => { %>
    echo "fablo channel getinfo <%= channel.name %> <%= org.name.toLowerCase(); %> <%= peer.name %>"
    echo -e "\t Get channel info on '<%= peer.name %>' of '<%= org.name %>'".
    echo ""
    echo "fablo channel fetch config <%= channel.name %> <%= org.name.toLowerCase(); %> <%= peer.name %> <fileName.json>"
    echo -e "\t Download latest config block to current dir. Uses first peer '<%= peer.name %>' of '<%= org.name %>'".
    echo ""
    echo "fablo channel fetch lastBlock <%= channel.name %> <%= org.name.toLowerCase(); %> <%= peer.name %> <fileName.json>"
    echo -e "\t Download last, decrypted block to current dir. Uses first peer '<%= peer.name %>' of '<%= org.name %>'".
    echo ""
    echo "fablo channel fetch firstBlock <%= channel.name %> <%= org.name.toLowerCase(); %> <%= peer.name %> <fileName.json>"
    echo -e "\t Download first, decrypted block to current dir. Uses first peer '<%= peer.name %>' of '<%= org.name %>'".
    echo ""
  <% })})}) %>
}
