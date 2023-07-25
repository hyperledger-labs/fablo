#!/usr/bin/env bash

# Function to perform chaincode invoke
chaincodeInvoke() {
  local channel="$1"
  local chaincode="$2"
  local peers="$3"
  local command="$4"
  local transient="$5"

  echo "-> Chaincode invoke:"
  echo "Channel: $channel"
  echo "Chaincode: $chaincode"
  echo "Peers: $peers"
  echo "Command: $command"
  echo "Transient: $transient"

# Validate the input parameters
  if [[ -z $channel || -z $chaincode || -z $peers || -z $command || -z $transient ]]; then
    echo "Error: Insufficient arguments provided."
    echo "Usage: fablo chaincode invoke <channel_name> <chaincode_name> <peers_domains_comma_separated> <command> <transient>"
    return 1
  fi


  peerAddresses="--peerAddresses $(echo "$peers" | sed 's/,/ --peerAddresses /g')"

  docker exec "cli.org1.example.com" peer chaincode invoke \
    $peerAddresses \
    -C "$channel" \
    -n "$chaincode" \
    -c "$command" \
    --transient "$transient" \
    --waitForEvent \
    --waitForEventTimeout 90s \
    2>&1 

  echo "Executing chaincode invoke command..."
}
