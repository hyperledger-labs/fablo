#!/usr/bin/env bash

cli=$1
peer=$2
channel=$3
chaincode=$4
version=$5
search_string="Name: $chaincode, Version: $version"

if [ -z "$version" ]; then
  echo "Usage: ./wait-for-chaincode.sh [cli] [peer:port] [channel] [chaincode] [version]"
  exit 1
fi

listChaincodes() {
  docker exec -e CORE_PEER_ADDRESS="$peer" "$cli" peer chaincode list \
    -C "$channel" \
    --instantiated
}

for i in $(seq 1 90); do
  echo "➜ verifying if chaincode ($chaincode/$version) is instantiated on $channel/$cli/$peer ($i)..."

  if listChaincodes 2>&1 | grep "$search_string"; then
    echo "✅ ok: Chaincode $chaincode/$version is ready on $channel/$cli/$peer!"
    exit 0
  else
    sleep 1
  fi
done

#timeout
echo "❌ failed: Failed to verify chaincode $chaincode/$version on $channel/$cli/$peer"
listChaincodes
exit 1
