#!/bin/bash
# Copies plugin source into KOReader's plugins dir, skipping Zone.Identifier files
rsync -av --exclude='*.Identifier' \
  ~/workspace/kindle-toddler-learn/plugins/toddlerlearn.koplugin/ \
  ~/workspace/kindle-toddler-learn/koreader/plugins/toddlerlearn.koplugin/
echo "✓ synced"
