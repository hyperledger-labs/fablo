#!/bin/sh

chaincode=$1
version=$2
search_string="Name: $chaincode, Version: $version"

listChaincodes() {
  docker exec "cli.org1.com" peer chaincode list \
    -C "my-channel1" \
    --instantiated
}

for i in $(seq 1 120); do
  echo "Verifying if chaincode ($chaincode/$version) is ready ($i)..."

  if listChaincodes 2>&1 | grep "$search_string"; then
    echo "Chaincode $chaincode/$version is ready!"
    exit 0
  else
    sleep 1
  fi
done

#timeout
echo "Failed to verify chaincode $chaincode/$version"
exit 1
