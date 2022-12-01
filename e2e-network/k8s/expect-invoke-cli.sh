#!/usr/bin/env bash

set -e

user="$1"
peer="$2"
channel="$3"
chaincode="$4"
fcn="$5"
key="$6"
value="$7"
expected="$8"
config="$(find . -type f -iname 'org1.yaml')"




if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke.sh [user] [peer] [chaincdoe] [channel] [fcn] [arg1] [arg2] [expected_substring]"
  exit 1
fi

label="Invoke $channel/$peer"
echo ""
echo "➜ testing: $label"

response="$(
  kubectl hlf chaincode invoke \
    --config "$config" \
    --user "$user" \
    --peer "$peer" \
    --chaincode "$chaincode" \
    --channel "$channel" \
    --fcn "$fcn" \
    -a "$key" \
    ${value:+ -a "$value"} \

    # shellcheck disable=SC2188
    2>&1
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "✅ ok (cli): $label"
else
  echo "❌ failed (cli): $label | expected: $expected"
  exit 1
fi
