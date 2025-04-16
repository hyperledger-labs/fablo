#!/usr/bin/env bash

chaincodeList() {
  if [ "$#" -ne 2 ]; then
    echo "Expected 2 parameters for chaincode list, but got: $*"
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

# Function to perform chaincode invoke. Accepts 5 parameters:
#   1. comma-separated peers
#   2. channel name
#   3. chaincode name
#   4. chaincode command
#   5. transient data (optional)
chaincodeInvoke() {
  if [ "$#" -ne 4 ] && [ "$#" -ne 5 ]; then
    echo "Expected 4 or 5 parameters for chaincode list, but got: $*"
    echo "Usage: fablo chaincode invoke <peer_domains_comma_separated> <channel_name> <chaincode_name> <command> [transient]"
    exit 1
  fi
  cli=""
  peer_addresses=""
  <% if (global.tls) { %>
     peer_certs=""
  <% } %>
  <% orgs.forEach((org) => { -%>
    <% org.peers.forEach((peer) => { -%>
      if [[ "$1" == *"<%= peer.address %>"* ]]; then
        cli="<%= org.cli.address %>"
        peer_addresses="$peer_addresses,<%= peer.fullAddress %>"
        <% if(global.tls) { %>
           peer_certs="$peer_certs,crypto/peers/<%= peer.address %>/tls/ca.crt"
        <% } %>
      fi
    <% }) -%>
  <% }) -%>
  if [ -z "$peer_addresses" ]; then
    echo "Unknown peers: $1"
    exit 1
  fi
  <% if(!global.tls) { %>
    peerChaincodeInvoke "$cli" "${peer_addresses:1}" "$2" "$3" "$4" "$5"
  <% } else { %>
    <% channels.forEach((channel) => { %>
      if [ "$2" = "<%= channel.name %>" ]; then
        ca_cert="crypto-orderer/tlsca.<%= ordererGroups[0].ordererHeads[0].domain %>-cert.pem"
      fi
    <% }) %>
    peerChaincodeInvokeTls "$cli" "${peer_addresses:1}" "$2" "$3" "$4" "$5" "${peer_certs:1}" "$ca_cert"
  <% } %>
}

# Function to perform chaincode query. Accepts 4 parameters:
#   1. comma-separated peers
#   2. channel name
#   3. chaincode name
#   4. chaincode command
chaincodeQuery() {
  if [ "$#" -ne 4 ]; then
    echo "Expected 4 parameters for chaincode query, but got: $*"
    echo "Usage: fablo chaincode query <peer_domains_comma_separated> <channel_name> <chaincode_name> <command>"
    exit 1
  fi
  cli=""
  peer_addresses=""
  <% if (global.tls) { %>
     peer_certs=""
  <% } %>
  <% orgs.forEach((org) => { -%>
    <% org.peers.forEach((peer) => { -%>
      if [[ "$1" == *"<%= peer.address %>"* ]]; then
        cli="<%= org.cli.address %>"
        peer_addresses="$peer_addresses,<%= peer.fullAddress %>"
        <% if(global.tls) { %>
           peer_certs="$peer_certs,crypto/peers/<%= peer.address %>/tls/ca.crt"
        <% } %>
      fi
    <% }) -%>
  <% }) -%>
  if [ -z "$peer_addresses" ]; then
    echo "Unknown peers: $1"
    exit 1
  fi
  <% if(!global.tls) { %>
    peerChaincodeQuery "$cli" "${peer_addresses:1}" "$2" "$3"
  <% } else { %>
    <% channels.forEach((channel) => { %>
      if [ "$2" = "<%= channel.name %>" ]; then
        ca_cert="crypto-orderer/tlsca.<%= ordererGroups[0].ordererHeads[0].domain %>-cert.pem"
      fi
    <% }) %>
    peerChaincodeQueryTls "$cli" "${peer_addresses:1}" "$2" "$3" "${peer_certs:1}" "$ca_cert"
  <% } %>
}
