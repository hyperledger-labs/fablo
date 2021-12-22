#!/usr/bin/env bash

container="$1"
expected_message="$2"
max_attempts="${3:-90}"

end='\e[0m'
darkGray='\e[90m'

if [ -z "$expected_message" ]; then
  echo "Usage: ./wait-for-container.sh [container_name] [expected_message]"
  exit 1
fi

for i in $(seq 1 "$max_attempts"); do
  echo "➜ verifying if container $container logs contain ($i)... ${darkGray}'$expected_message'${end}"

  if docker logs "$container" 2>&1 | grep -q "$expected_message"; then
    echo "✅ ok: Container $container is ready!"
    exit 0
  else
    sleep 1
  fi
done

#timeout
echo "❌ failed: Container $container logs does not contain ${darkGray}'$expected_message'${end}"
echo "Last log messages:"
docker logs "$container" | tail -n 30
exit 1
