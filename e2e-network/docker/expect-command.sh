#!/usr/bin/env bash

command="$1"
expected="$2"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-command.sh [command] [expected value]"
  exit 1
fi

echo ""
echo "➜ testing: $command"

response="$(eval "$command" 2>&1)"

echo "$response"

if echo "$response" | grep -a -F "$expected"; then
  echo "✅ ok (cli): $command"
else
  echo "❌ failed (cli): $command | expected: $expected"
  exit 1
fi
