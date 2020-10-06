#!/bin/sh

cli=$1
channel=$2
chaincode=$3
version=$4
search_string="Name: $chaincode, Version: $version"

listChaincodes() {
  docker exec "$cli" peer chaincode list \
    -C "$channel" \
    --instantiated
}

for i in $(seq 1 60); do
  echo "Verifying if chaincode ($chaincode/$version) is ready on $channel ($i)..."

  if listChaincodes 2>&1 | grep "$search_string"; then
    echo "Chaincode $chaincode/$version is ready on $channel!"
    exit 0
  else
    sleep 1
  fi
done

#timeout
echo "Failed to verify chaincode $chaincode/$version on $channel"
exit 1
