#!/usr/bin/env bash
set -e
rm -rf build
rm -f contracts/InvestmentPool.sol
source $(dirname "$0")/preprocess-template.sh $1
node_modules/.bin/truffle compile --all
yarn combine-contracts
