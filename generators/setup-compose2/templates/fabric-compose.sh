#!/bin/bash

source fabric-compose/scripts/base-help.sh
source fabric-compose/scripts/base-functions.sh
source fabric-compose/scripts/base-commands.sh

source fabric-compose/.env

if [ "$1" = "up" ]; then
  networkUp
elif [ "$1" = "down" ]; then
  networkDown
elif [ "$1" = "rerun" ]; then
  networkRerun
elif [ "$1" = "help" ]; then
  printHelp
elif [ "$1" = "--help" ]; then
  printHelp
else
  echo "No command specified"
  echo "Allowed options: up, down, start, stop, rerun"
  echo "Use help or --help for more information"
fi
