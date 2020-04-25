#!/bin/sh

basedir="e2e/__tmp__"

generate() {
  name="$1"
  dir="$basedir/$name"
  echo "Generating $name in $dir..."
  mkdir -p "$dir" &&
    rm -rf "${dir:?}/*" &&
    (
      cd "$dir" &&
        yo --no-insight fabric-network:setup-compose "../../$name"
    )
}

sudo npm link &&
  sudo mkdir -p "$basedir" &&
  sudo chown -R yeoman:yeoman "$basedir" &&
  generate "sample-01.json"
