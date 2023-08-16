#!/usr/bin/env bash

cli="$1"
peers="$2"
channel="$3"
chaincode="$4"
command="$5"
expected="$6"
transient_default="{}"
transient="${7:-$transient_default}"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke.sh [cli] [peer:port[,peer:port]] [channel] [chaincode] [command] [expected_substring] [transient_data]"
  exit 1
fi

label="Invoke $channel/$cli/$peer $command"
echo ""
echo "➜ testing: $label"


response="$(
   "$FABLO_HOME/fablo.sh" chaincode invoke "$channel" "$chaincode" "$peers" "$command" "$transient"
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "✅ ok (cli): $label"
else
  echo "❌ failed (cli): $label | expected: $expected"
  exit 1
fi
