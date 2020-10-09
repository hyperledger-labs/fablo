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

for i in $(seq 1 90); do
  echo "Verifying if chaincode ($chaincode/$version) is ready on $channel/$cli ($i)..."

  if listChaincodes 2>&1 | grep "$search_string"; then
    echo "Chaincode $chaincode/$version is ready on $channel/$cli!"
    exit 0
  else
    sleep 1
  fi
done

#timeout
echo "Failed to verify chaincode $chaincode/$version on $channel/$cli"
listChaincodes
exit 1
