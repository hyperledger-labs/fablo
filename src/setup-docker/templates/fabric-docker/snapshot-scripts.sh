#!/usr/bin/env bash

__getSnapshotNodes() {
  network_name="${COMPOSE_PROJECT_NAME}_basic"
  docker ps --format "{{.Names}}" --filter "network=$network_name" --all |
    grep -v "cli\." |
    grep -v "dev-peer" |
    grep -v "ca\." |
    grep -v "couchdb\." |
    grep -v "fablo-rest"
}

__createSnapshot() {
  cd "$FABLO_NETWORK_ROOT/.."
  backup_dir="${1:-$(echo "backup-$(date -u +"%Y%m%d%H%M%S")")}"
  echo "Creating network snapshot in $backup_dir"

  if [ -d "$backup_dir" ]; then
    echo "Error: Directory '$backup_dir' already exists!"
    exit 1
  fi

  mkdir -p "$backup_dir"
  cp -R ./fablo-target "$backup_dir/"

  source ./fablo-target/fabric-docker/.env

  for node in $(__getSnapshotNodes); do
    echo "Saving state of $node..."
    docker cp "$node:/var/hyperledger/production/" "$backup_dir/$node/"
  done
}

__cloneSnapshot() {
  cd "$FABLO_NETWORK_ROOT/.."
  target_dir="$1"
  echo "Restoring network from $(pwd) to $target_dir"

  cp -R ./fablo-target "$target_dir/fablo-target"
  (cd "$target_dir/fablo-target/fabric-docker" && docker-compose up --no-start)

  source "$target_dir/fablo-target/fabric-docker/.env"
  network_name="${COMPOSE_PROJECT_NAME}_basic"

  for node in $(__getSnapshotNodes); do
    echo "Restoring $node..."
    docker cp "./$node/" "$node:/var/hyperledger/production/"
  done
}

createSnapshot() {
  (set -eu && __createSnapshot "$1")
}

cloneSnapshot() {
  (set -eu && __cloneSnapshot "$1")
}
