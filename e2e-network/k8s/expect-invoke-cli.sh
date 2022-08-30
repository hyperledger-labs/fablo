#!/usr/bin/env bash

set -e

user="$1"
peer="$2"
chaincode="$3"
channel="$4"
func="$5"
expected="$6"
config=/home/great/work/new/fablo/fablo-target/fabric-config/fabric-k8/org1.yaml

if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke.sh [cli] [peer:port[,peer:port]] [channel] [chaincode] [command] [expected_substring] [transient_data]"
  exit 1
fi

label="Invoke $channel/$cli/$peer $command"
echo ""
echo "➜ testing: $label"

response="$(
  # shellcheck disable=SC2086
  kubectl hlf chaincode invoke \
    --config $config \
    --user $user \
    --peer $peer \
    --chaincode $chaincode \
    --channel $channel \
    --fcn $func
    2>&1
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "✅ ok (cli): $label"
else
  echo "❌ failed (cli): $label | expected: $expected"
  exit 1
fi
