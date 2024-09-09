#!/usr/bin/env bash

peer=$1
channel=$2
chaincode=$3
version=$4
search_string="Name: $chaincode, Version: $version"

if [ -z "$version" ]; then
  echo "Usage: ./wait-for-chaincode.sh [peer:port] [channel] [chaincode] [version]"
  exit 1
fi

listChaincodes() {
  "$FABLO_HOME/fablo.sh" chaincodes list "$peer" "$channel" 
}

for i in $(seq 1 90); do
  echo "➜ verifying if chaincode ($chaincode/$version) is committed on $channel/$peer ($i)..."
  if listChaincodes 2>&1 | grep "$search_string"; then
    listChaincodes
    echo "✅ ok: Chaincode $chaincode/$version is ready on $channel/$peer!"
    exit 0
  else 
    sleep 1
  fi
done

#timeout
echo "❌ failed: Failed to verify chaincode $chaincode/$version on $channel/$peer"
listChaincodes
exit 1
