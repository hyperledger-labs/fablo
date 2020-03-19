#!/usr/bin/env bash
set -ev

rm -rf crypto-config/*
mkdir -p crypto-config

cryptogen generate --config=../../config/crypto-config.yaml
for file in $(find crypto-config/ -iname *_sk); do dir=$(dirname $file); mv ${dir}/*_sk ${dir}/key.pem; done
