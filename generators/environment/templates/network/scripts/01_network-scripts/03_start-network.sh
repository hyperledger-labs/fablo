#!/usr/bin/env bash
set -ev

cd ..

docker-compose -f fabric-compose.yaml down
docker-compose -f fabric-compose.yaml up -d

sleep 5