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
elif [ "$1" = "fetch" ] && [ "$2" = "config" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.name.toLowerCase(); %>" ] && [ "$5" = "<%= peer.name %>" ]; then
  TARGET_FILE=${6:-"$channel-config.json"}
  <% if(!global.tls) { %>
    peerChannelFetchConfig "<%= channel.name %>" "<%= org.cli.address %>" "$TARGET_FILE" "<%= peer.fullAddress %>"
  <% } else { %>
    peerChannelFetchConfigTls "<%= channel.name %>" "<%= org.cli.address %>" "$TARGET_FILE" "<%= peer.fullAddress %>" "crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem"
  <% } %>
elif [ "$1" = "fetch" ] && [ "$3" = "<%= channel.name %>" ] && [ "$4" = "<%= org.name.toLowerCase(); %>" ] && [ "$5" = "<%= peer.name %>" ]; then
  BLOCK_NAME=$2
  TARGET_FILE=${6:-"$BLOCK_NAME.block"}
  <% if(!global.tls) { %>
    peerChannelFetchBlock "<%= channel.name %>" "<%= org.cli.address %>" "${BLOCK_NAME}" "<%= peer.fullAddress %>" "$TARGET_FILE"
  <% } else { %>
    peerChannelFetchBlockTls "<%= channel.name %>" "<%= org.cli.address %>" "${BLOCK_NAME}" "<%= peer.fullAddress %>" "crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem" "$TARGET_FILE"
  <% } %>
<% })})}) %>
else
  echo "$@"
  echo "$1, $2, $3, $4, $5, $6, $7, $#"
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
    echo "fablo channel fetch config <%= channel.name %> <%= org.name.toLowerCase(); %> <%= peer.name %> [file-name.json]"
    echo -e "\t Download latest config block and save it. Uses first peer '<%= peer.name %>' of '<%= org.name %>'".
    echo ""
    echo "fablo channel fetch <newest|oldest|block-number> <%= channel.name %> <%= org.name.toLowerCase(); %> <%= peer.name %> [file name]"
    echo -e "\t Fetch a block with given number and save it. Uses first peer '<%= peer.name %>' of '<%= org.name %>'".
    echo ""
  <% })})}) %>
}
