#!/bin/sh

cli="$1"
peer="$2"
command="$3"
expected="$4"

label="Invoke $cli/$peer $command"
echo "[testing] $label"

response="$(
  docker exec -e CORE_PEER_ADDRESS="$peer:7051" "$cli" peer chaincode invoke \
    -C "my-channel1" \
    -n "chaincode1" \
    -c "$command" \
    --waitForEvent \
    2>&1
)"

if echo "$response" | grep -F "$expected"; then
  echo "[ok] $label"
else
  echo "[failed] $label
    expected: $expected
    actual:   $response"
  exit 1
fi
