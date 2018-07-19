#!/usr/bin/env bash
# remove solc from truffle to use our version
rm -rf node_modules/truffle/node_modules/solc
CONFIG=$1
CONFIG="${CONFIG:-investment-pool-config.json}"
source $(dirname "$0")/compile-template.sh "$CONFIG"
