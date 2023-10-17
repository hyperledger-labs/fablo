#!/usr/bin/env bash

peers="$1"
channel="$2"
chaincode="$3"
command="$4"
expected="$5"
transient_default="{}"
transient="${6:-$transient_default}"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke.sh [peer[,peer]] [channel] [chaincode] [command] [expected_substring] [transient_data]"
  exit 1
fi

label="Invoke $channel/$peers $command"
echo ""
echo "➜ testing: $label"


response="$(
   "$FABLO_HOME/fablo.sh" chaincode invoke "$peers" "$channel" "$chaincode" "$command" "$transient"
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "✅ ok (cli): $label"
else
  echo "❌ failed (cli): $label | expected: $expected"
  exit 1
fi
