#!/usr/bin/env bash

set -e

peers="$1"
channel="$2"
chaincode="$3"
command="$4"
expected="$5"
transient="${6:-}"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-query.sh [peer[,peer]] [channel] [chaincode] [command] [expected_substring] [transient_data]"
  exit 1
fi

label="Query $channel/$peers $command"
echo ""
echo "➜ testing: $label"

args=(chaincode query "$peers" "$channel" "$chaincode" "$command")
if [ -n "$transient" ]; then
  args+=("$transient")
fi

response="$("$FABLO_HOME/fablo.sh" "${args[@]}")"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "✅ ok (cli): $label"
else
  echo "❌ failed (cli): $label | expected: $expected"
  exit 1
fi
