#!/usr/bin/env bash

user=$1
peer=$2
channel=$3
chaincode=$4
version=$5
config="$(find . -type f -iname 'org1.yaml')"

if [ -z "$version" ]; then
  echo "Usage: ./wait-for-chaincode.sh [user] [peer] [channel] [chaincode] [version]"
  exit 1
fi

listChaincodes() {
  kubectl hlf chaincode querycommitted \
    --config "$config" \
    --user "$user" \
    --peer "$peer" \
    --channel "$channel"
}

echo "➜ verifying if chaincode ($chaincode/$version) is committed on $channel/$peer ..."

if listChaincodes 2>&1 | grep -q "$chaincode\|$version"; then
  echo "✅ ok: Chaincode $chaincode/$version is ready on $channel/$peer!"
  exit 0
else
  sleep 1
fi

#timeout
echo "❌ failed: Failed to verify chaincode $chaincode/$version on $channel/$peer"
listChaincodes
exit 1
