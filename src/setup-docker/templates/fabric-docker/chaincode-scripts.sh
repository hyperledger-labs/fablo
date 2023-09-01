#!/usr/bin/env bash

# Function to perform chaincode invoke
chaincodeInvoke() {
  local CHANNEL="$1"
  local CHAINCODE="$2"
  local PEERS="$3"
  local COMMAND="$4"
  local TRANSIENT="$5"

  echo "-> Chaincode invoke:"
  inputLog "CHANNEL: $CHANNEL"
  inputLog "CHAINCODE: $CHAINCODE"
  inputLog "PEERS: $PEERS"
  inputLog "COMMAND: $COMMAND"
  inputLog "TRANSIENT: $TRANSIENT"

# Validate the input parameters
  if [[ -z $CHANNEL || -z $CHAINCODE || -z $PEERS || -z $COMMAND || -z $TRANSIENT ]]; then
    echo "Error: Insufficient arguments provided."
    echo "Usage: fablo chaincode invoke <channel_name> <chaincode_name> <peers_domains_comma_separated> <command> <transient>"
    return 1
  fi


 PEER_ADDRESSES="--peerAddresses $(echo "$PEERS" | sed 's/,/ --peerAddresses  /g')"

CLI=""

<% orgs.forEach((org) => { -%>
  <% org.peers.forEach((peer) => { -%>
    if [ "$PEERS" = "<%= peer.fullAddress %>" ]; then
      CLI="<%= org.cli.address %>"
    fi
  <% }) -%>
<% }) -%>
if [ -z "$CLI" ]; then
  echo "Unknown peer: $PEERS"
  exit 1
fi

# shellcheck disable=SC2086
  docker exec "$CLI"  peer chaincode invoke \
    $PEER_ADDRESSES \
    -C "$CHANNEL" \
    -n "$CHAINCODE" \
    -c "$COMMAND" \
    --transient "$TRANSIENT" \
    --waitForEvent \
    --waitForEventTimeout 90s \
    2>&1 
}


chaincodeList() {
  echo " chaincodeList $1 $2 "
  if [ "$#" -ne 2 ]; then
    echo "Expected 2 parameters for chaincode list, but got: $@"
    exit 1
  <% orgs.forEach((org) => { org.peers.forEach((peer) => { %>
  elif [ "$1" = "<%= peer.address %>" ]; then
    <% if(!global.tls) { %>
      peerChaincodeList "<%= org.cli.address %>" "<%= peer.fullAddress %>" "$2" # $2 is channel name
    <% } else { %>
      peerChaincodeListTls "<%= org.cli.address %>" "<%= peer.fullAddress %>" "$2" "crypto-orderer/tlsca.<%= ordererGroups[0].ordererHeads[0].domain %>-cert.pem" # Third argument is channel name
    <% } %>
  <% })}) %>
  else
  echo "Fail to call listChaincodes. No peer or channel found. Provided peer: $1, channel: $2"
  exit 1

  fi
}

