#!/usr/bin/env bash

set -eu

rest_api_url="$(echo "$1" | awk '{print $1}')"
access_token="$(echo "$1" | awk '{print $2}')"
channel="$2"
chaincode="$3"
method="$4"
args_json_array="$5"
expected="$6"
transient_default="{}"
transient="${7:-$transient_default}"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke.sh <rest_api_url> <channel> <chaincode> <contract:method> <args_json_array> <expected_substring> <transient_data>"
  exit 1
fi

label="Invoke $rest_api_url/invoke/$channel/$chaincode $method"
echo ""
echo "➜ testing: $label"

if [ -z "$access_token" ]; then
  the_same_dir="$(cd "$(dirname "$0")" && pwd)"
  enroll_admin_response="$("$the_same_dir/expect-ca-rest.sh" "$rest_api_url/user/enroll" '' '{"id": "admin", "secret": "adminpw"}' "token")"
  echo "enroll admin response: $enroll_admin_response"
  access_token="$(echo "$enroll_admin_response" | jq -r '.token')"
else
  echo "using provided token: $access_token"
fi

response=$(
  curl \
    -s \
    --request POST \
    --url "$rest_api_url/invoke/$channel/$chaincode" \
    --header "Authorization: Bearer $access_token" \
    --header 'Content-Type: application/json' \
    --data "{
      \"method\": \"$method\",
      \"args\": $args_json_array,
      \"transient\": $transient
    }"
)

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "✅ ok (rest): $label"
else
  echo "❌ failed (rest): $label | expected: $expected"
  exit 1
fi
