#!/bin/sh

generate() {
  name="$1"
  dir="e2e/__tmp__/$name"
  echo "Generating $name in $dir..."
  mkdir -p "$dir" &&
    rm -rf "${dir:?}/*" &&
    (
      cd "$dir" &&
        yo --no-insight fabric-network:setup-compose "../../$name"
    )
}

sudo npm link &&
  generate "sample-01.json"
