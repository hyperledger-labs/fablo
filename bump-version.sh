#!/usr/bin/env bash

set -eu

old_version=$(< package.json jq -r '.version')
include_readme=true
ver_arg="${1:-unstable}"

if [ "$ver_arg" = "patch" ] || [ "$ver_arg" = "minor" ] || [ "$ver_arg" = "major" ]; then
  new_version=$(semver next "$ver_arg" "$old_version")
elif [ "$ver_arg" = "unstable" ]; then
  new_version="$(semver next patch "$old_version")-unstable"
  include_readme=false
elif [ "$ver_arg" = "set" ]; then
  new_version="$2"
else
  echo "Invalid version parameter: $ver_arg"
  echo "Usage:"
  echo "  $0 <patch|minor|major|unstable>"
  echo "  $0 set <version>"
  exit 1
fi

echo "Updating version from $old_version to $new_version"
echo -n " - package.json...    "
npm version "$new_version" --no-git-tag-version > /dev/null
echo "done"

echo -n " - FABLO_VERSION...   "
perl -i -pe "s/FABLO_VERSION=.*\\n/FABLO_VERSION=${new_version}\\n/g" fablo.sh
perl -i -pe "s/FABLO_VERSION=.*\\n/FABLO_VERSION=${new_version}\\n/g" e2e/__snapshots__/*
echo "done"

echo -n " - JSON schema URL... "
schema_update_pattern="s/download\/[0-9-.a-zA-Z]*\/schema.json/download\/${new_version}\/schema.json/g"
if [ "$include_readme" = true ]; then
  perl -i -pe "$schema_update_pattern" README.md
fi
perl -i -pe "$schema_update_pattern" docs/sample.json
perl -i -pe "$schema_update_pattern" docs/schema.json
perl -i -pe "$schema_update_pattern" samples/*.json
perl -i -pe "$schema_update_pattern" samples/*.yaml
perl -i -pe "$schema_update_pattern" e2e/__snapshots__/*
echo "done"

if [ "$include_readme" = true ]; then
  echo -n " - download URL...    "
  download_update_pattern="s/download\/[0-9-.a-zA-Z]*\/fablo.sh/download\/${new_version}\/fablo.sh/g"
  perl -i -pe "$download_update_pattern" README.md
  echo "done"
fi
