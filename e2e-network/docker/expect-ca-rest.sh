#!/usr/bin/env bash

set -eu

rest_api_path="$1"
token="${2:-""}"
data="${3:-""}"
expected="$4"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-ca-rest.sh <rest_api_path> <auth-token> <data> <expected>"
  exit 1
fi

response="$(
  curl \
    -s \
    --request POST \
    --url "$rest_api_path" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $token" \
    --data "$data"
)"

if echo "$response" | grep -F "$expected"; then
  # in case of success this is a single echo, since the response might be
  # required by other tests, without additional noise
  echo ""
else
  label="$rest_api_path / $token / $data"
  echo ""
  echo "➜ testing: $label"
  echo "$response"
  echo "❌ failed (rest): $label | expected: $expected"
fi
