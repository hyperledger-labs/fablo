#!/bin/sh

waitFor() {
  container="$1"
  expected_message="$2"

  for i in $(seq 1 120); do
    echo "Verifying if container $container is ready ($i)..."

    if docker logs "$container" 2>&1 | grep -q "$expected_message"; then
      echo "Container $container is ready!"
      return 0
    else
      sleep 1
    fi
  done

  #timeout
  echo "Failed to verify $container"
  exit 1
}

waitFor "ca.root.com" "Listening on http://0.0.0.0:7054"
waitFor "orderer0.root.com" "Created and starting new chain my-channel1"
waitFor "ca.org1.com" "Listening on http://0.0.0.0:7054"
waitFor "peer0.org1.com" "Elected as a leader, starting delivery service for channel my-channel1"
waitFor "peer1.org1.com" "Elected as a leader, starting delivery service for channel my-channel1"
