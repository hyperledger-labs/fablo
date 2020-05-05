#!/bin/sh

basedir="/fabrikka/e2e/__tmp__"
samples="/fabrikka/samples"

generate() {
  name="$2"
  dir="$basedir/$1"
  source="$samples/$name"
  echo "Generating $source in $dir..."
  mkdir -p "$dir" &&
    cp "$source" "$dir/"
    (
      cd "$dir" &&
        yo --no-insight fabric-network:setup-compose "$name"
    )
}

sudo npm link &&
  sudo rm -rf "$basedir" &&
  sudo mkdir -p "$basedir" &&
  sudo chown -R yeoman:yeoman "$basedir" &&
  generate "sample-01" "fabrikkaConfig-1org-1channel-1chaincode.json" &&
  generate "sample-02" "fabrikkaConfig-2orgs-2channels-1chaincode.json" &&
  sudo chown -R root:root "$basedir"
