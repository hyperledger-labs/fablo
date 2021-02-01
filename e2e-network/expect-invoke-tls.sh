#!/usr/bin/env bash

cli="$1"
peer="$2"
channel="$3"
chaincode="$4"
command="$5"
expected="$6"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke-tls.sh [cli] [peer:port] [channel] [chaincode] [command] [expected_substring]"
  exit 1
fi

label="Invoke $channel/$cli/$peer $command"
echo "[testing] $label"

response="$(
  docker exec "$cli" peer chaincode invoke \
    --peerAddresses "$peer" \
    --tlsRootCertFiles "/var/hyperledger/cli/crypto/peers/${peer%?????}/tls/ca.crt" \
    -C "$channel" \
    -n "$chaincode" \
    -c "$command" \
    --waitForEvent \
    --tls \
    --cafile "/var/hyperledger/cli/crypto/orderer-tlscacerts/tlsca.root.com-cert.pem" \
    2>&1
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "[ok] $label"
else
  echo "[failed] $label | expected: $expected"
  exit 1
fi
