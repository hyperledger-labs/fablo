#!/usr/bin/env bash

cli="$1"
peer="$2"
channel="$3"
chaincode="$4"
command="$5"
expected="$6"
transient_default="{}"
transient="${7:-$transient_default}"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke-tls.sh [cli] [peer:port[,peer:port]] [channel] [chaincode] [command] [expected_substring] [transient_data]"
  exit 1
fi

label="Invoke $channel/$cli/$peer $command"
echo ""
echo "➜ testing: $label"

# shellcheck disable=SC2001
peerAddresses="--peerAddresses $(echo "$peer" | sed 's/,/ --peerAddresses /g')"

# shellcheck disable=SC2001
peerNoPort="$(echo "$peer" | sed -e 's/:[[:digit:]]\{2,\}//g')"
tlsRootCertFiles="--tlsRootCertFiles /var/hyperledger/cli/crypto/peers/$(echo "$peerNoPort" | sed 's/,/\/tls\/ca.crt --tlsRootCertFiles \/var\/hyperledger\/cli\/crypto\/peers\//g')/tls/ca.crt"

echo "$peerAddresses"
echo "$tlsRootCertFiles"

response="$(
  # shellcheck disable=SC2086
  docker exec "$cli" peer chaincode invoke \
    $peerAddresses \
    $tlsRootCertFiles \
    -C "$channel" \
    -n "$chaincode" \
    -c "$command" \
    --transient "$transient" \
    --waitForEvent \
    --waitForEventTimeout 90s \
    --tls \
    --cafile "/var/hyperledger/cli/crypto/orderer-tlscacerts/tlsca.root.com-cert.pem" \
    2>&1
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "✅ ok: $label"
else
  echo "❌ failed: $label | expected: $expected"
  exit 1
fi
