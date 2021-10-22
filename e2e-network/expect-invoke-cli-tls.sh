#!/usr/bin/env bash

cli="$1"
peer="$2"
channel="$3"
chaincode="$4"
orderer_cert="$5"
command="$6"
expected="$7"
transient_default="{}"
transient="${8:-$transient_default}"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke-tls.sh [cli] [peer:port[,peer:port]] [channel] [chaincode] [orderer_cert] [command] [expected_substring] [transient_data]"
  exit 1
fi

label="Invoke $channel/$cli/$peer ($orderer_cert) $command"
echo ""
echo "➜ testing: $label"

peerAddresses="--peerAddresses $(echo "$peer" | sed 's/,/ --peerAddresses /g')"

peerNoPort="$(echo "$peer" | sed -e 's/:[[:digit:]]\{2,\}//g')"
tlsRootCertFiles="--tlsRootCertFiles /var/hyperledger/cli/crypto/peers/$(echo "$peerNoPort" | sed 's/,/\/tls\/ca.crt --tlsRootCertFiles \/var\/hyperledger\/cli\/crypto\/peers\//g')/tls/ca.crt"

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
    --cafile "/var/hyperledger/cli/crypto-orderer/$orderer_cert" \
    2>&1
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "✅ ok (cli-tls): $label"
else
  echo "❌ failed (cli-tls): $label | expected: $expected"
  exit 1
fi
