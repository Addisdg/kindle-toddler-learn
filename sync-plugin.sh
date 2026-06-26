#!/bin/bash
# Copies plugin source into KOReader's plugins dir, skipping Zone.Identifier files
rsync -av --exclude='*.Identifier' \
  ~/workspace/kindle-toddler-learn/plugins/toddlerlearn.koplugin/ \
  ~/workspace/kindle-toddler-learn/koreader/plugins/toddlerlearn.koplugin/

cp ~/workspace/kindle-toddler-learn/plugins/toddlerlearn.koplugin/toddlerlearn_spec.lua \
  ~/workspace/kindle-toddler-learn/koreader/koreader-emulator-x86_64-linux-gnu-debug/koreader/spec/front/unit/toddlerlearn_spec.lua
echo "✓ synced"
