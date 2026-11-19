#!/usr/bin/env bash

# Publish the npm package for a release tag. Called by the publish-npm job of
# .github/workflows/release-on-tag.yml.
#
# Checks that the tag matches package.json, then publishes. Pre-releases
# (e.g. 2.7.0-rc.1) go to the `next` dist-tag so `npm install` keeps getting
# the stable version.
#
# Reads from the environment: RELEASE_TAG, NODE_AUTH_TOKEN (until trusted
# publishing is configured), DRY_RUN (set to 1 to run `npm publish --dry-run`).
#
# Run locally: RELEASE_TAG=2.6.0 DRY_RUN=1 .github/scripts/publish-npm.sh

set -euo pipefail

cd "$(dirname "$0")/../.."

package_version=$(jq -r '.version' package.json)
if [ "$RELEASE_TAG" != "$package_version" ]; then
  echo "Tag $RELEASE_TAG does not match package.json version $package_version"
  exit 1
fi

if [[ "$RELEASE_TAG" == *-* ]]; then
  dist_tag=next
else
  dist_tag=latest
fi

publish_flags=(--tag "$dist_tag")
# provenance can only be generated inside GitHub Actions
if [ -n "${GITHUB_ACTIONS:-}" ]; then
  publish_flags+=(--provenance)
fi
if [ "${DRY_RUN:-}" = 1 ]; then
  publish_flags+=(--dry-run)
fi

npm ci
npm publish "${publish_flags[@]}"
