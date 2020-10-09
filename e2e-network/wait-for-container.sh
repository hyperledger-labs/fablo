#!/bin/sh

container="$1"
expected_message="$2"

for i in $(seq 1 90); do
  echo "Verifying if container $container is ready ($i)..."

  if docker logs "$container" 2>&1 | grep -q "$expected_message"; then
    echo "Container $container is ready!"
    exit 0
  else
    sleep 1
  fi
done

#timeout
echo "Failed to verify $container"
echo "Last log messages:"
docker logs "$container" | tail -n 30
exit 1
