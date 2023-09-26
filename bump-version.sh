#!/usr/bin/env bash

set -eu

old_version=$(< package.json jq -r '.version')
ver_arg="${1:-unstable}"

if [ "$ver_arg" = "patch" ] || [ "$ver_arg" = "minor" ] || [ "$ver_arg" = "major" ]; then
  new_version=$(semver "$old_version" -i "$ver_arg")
elif [ "$ver_arg" = "unstable" ]; then
  new_version=$(semver "$old_version" -i prerelease --preid unstable)
else
  echo "Invalid version parameter: $ver_arg"
  echo "Usage: $0 [patch|minor|major|unstable]"
  exit 1
fi

echo "Updating version from $old_version to $new_version"
echo -n " - package.json...    "
npm version "$new_version" --no-git-tag-version > /dev/null
echo "done"

echo -n " - FABLO_VERSION...   "
perl -i -pe "s/FABLO_VERSION=\"[^\"]*\"/FABLO_VERSION=\"${new_version}\"/g" fablo.sh
perl -i -pe "s/FABLO_VERSION=\"[^\"]*\"/FABLO_VERSION=\"${new_version}\"/g" e2e/__snapshots__/*
echo "done"

echo -n " - JSON schema URL... "
schema_update_pattern="s/download\/[0-9-.a-zA-Z]*\/schema.json/download\/${new_version}\/schema.json/g"
perl -i -pe "$schema_update_pattern" README.md
perl -i -pe "$schema_update_pattern" docs/schema.json
perl -i -pe "$schema_update_pattern" samples/*.json
perl -i -pe "$schema_update_pattern" samples/*.yaml
perl -i -pe "$schema_update_pattern" e2e/__snapshots__/*
echo "done"

echo -n " - download URL...    "
download_update_pattern="s/download\/[0-9-.a-zA-Z]*\/fablo.sh/download\/${new_version}\/fablo.sh/g"
perl -i -pe "$download_update_pattern" README.md
echo "done"