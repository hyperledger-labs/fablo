#!/usr/bin/env bash

rest_api_url="$1"
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

enroll_admin_response="$(
  curl \
    -s \
    --request POST \
    --url "$rest_api_url/user/enroll" \
    --header 'Content-Type: application/json' \
    --data '{"id": "admin", "secret": "adminpw"}'
)"

echo "$enroll_admin_response"

access_token="$(echo "$enroll_admin_response" | jq -r '.token')"

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
  echo "✅ ok: $label"
else
  echo "❌ failed: $label | expected: $expected"
  exit 1
fi
