#!/usr/bin/env bash
mkdir -p build/template
echo "first pass"
node node_modules/.bin/c-preprocessor --config pre-firstpass-config.json template/InvestmentPool.sol build/template/InvestmentPool.sol
echo "second pass"
node node_modules/.bin/c-preprocessor --config $1 build/template/InvestmentPool.sol contracts/InvestmentPool.sol
