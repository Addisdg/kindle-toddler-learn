#!/bin/bash
# Run the Toddler Learn test suite
# Usage: ./run-tests.sh

set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
EMULATOR="$REPO/koreader/koreader-emulator-x86_64-linux-gnu-debug/koreader"
SPEC="$REPO/koreader/base/build/x86_64-linux-gnu-debug/spec"
PLUGIN="plugins/toddlerlearn.koplugin"

# Sync plugin to KOReader first
"$REPO/sync-plugin.sh"

cd "$EMULATOR"

LUA_PATH="$SPEC/rocks/share/lua/5.1/?.lua;$SPEC/rocks/share/lua/5.1/?/init.lua;./frontend/?.lua;./$PLUGIN/?.lua;./?.lua;;" \
LUA_CPATH="$SPEC/rocks/lib/lua/5.1/?.so;;" \
KO_HOME="$SPEC/run/front_toddlerlearn" \
LSAN_OPTIONS=exitcode=0 \
./luajit -e 'require "busted.runner" {standalone = false}' /dev/null \
  --output=gtest \
  -Xoutput=--color \
  --run=front \
  spec/front/unit/toddlerlearn_spec.lua \
  --config-file=spec/config.lua \
  --exclude-tags=notest \
  --helper=spec/helper.lua \
  --loaders=lua \
  --lazy
