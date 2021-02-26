#!/usr/bin/env bash

cli="$1"
peer="$2"
channel="$3"
chaincode="$4"
command="$5"
expected="$6"
transient="${7:-"{}"}"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke.sh [cli] [peer:port] [channel] [chaincode] [command] [expected_substring] [transient_data]"
  exit 1
fi

label="Invoke $channel/$cli/$peer $command"
echo "[testing] $label"

response="$(
  docker exec "$cli" peer chaincode invoke \
    --peerAddresses "$peer" \
    -C "$channel" \
    -n "$chaincode" \
    -c "$command" \
    --transient "$transient" \
    --waitForEvent \
    2>&1
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "[ok] $label"
else
  echo "[failed] $label | expected: $expected"
  exit 1
fi
