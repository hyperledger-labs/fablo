#!/bin/sh

method="$1"
param1="$2"
param2="$3"

getCommand() {
  if [ -n "$param2" ]; then
    echo "{\"Args\":[\"$method\", \"$param1\", \"$param2\"]}"
  elif [ -n "$param1" ]; then
    echo "{\"Args\":[\"$method\", \"$param1\"]}"
  else
    echo "{\"Args\":[\"$method\"]}"
  fi
}

docker exec "cli.org1.com" peer chaincode invoke \
  -C "my-channel1" \
  -n "chaincode1" \
  -c "$(getCommand)" \
  --waitForEvent

# sample: ./invoke-chaincode.sh "KVContract:put" "name" "Willy Wonka"