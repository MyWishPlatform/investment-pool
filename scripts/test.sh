#!/usr/bin/env bash
CONFIG=$1
CONFIG="${CONFIG:-investment-pool-config.json}"
source $(dirname "$0")/test-template.sh "$CONFIG"
