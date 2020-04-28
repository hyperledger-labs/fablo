#!/bin/sh

expected_message="XXX"

for i in $(seq 1 120); do
  echo "Verifying if docker compose services are ready ($i)..."

  if docker logs generic-auth_outbox_listener_1 | grep -q "$expected_message"; then
    echo "Docker compose services are ready!"
    break
  else
    sleep 1
  fi
done
