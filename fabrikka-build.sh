#!/bin/sh

FABRIKKA_HOME="$(cd "$(dirname "$0")" && pwd)"

docker build --tag fabrikka "$FABRIKKA_HOME"
