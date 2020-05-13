#!/bin/sh

dir="$(dirname "$0")/__tmp__/sample-01/"
(
  cd "$dir" &&
    ls -l &&
    ./fabric-compose.sh down
)
