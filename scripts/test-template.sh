#!/usr/bin/env bash
set -e
node node_modules/.bin/c-preprocessor --config pre-firstpass-config.json template/investmentPool.js build/investmentPool.js
node node_modules/.bin/c-preprocessor --config $1 build/investmentPool.js test/investmentPool.js
node node_modules/.bin/truffle test
