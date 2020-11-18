#!/bin/sh

FABRICA_HOME="$(cd "$(dirname "$0")" && pwd)"

docker build --tag fabrica "$FABRICA_HOME"
