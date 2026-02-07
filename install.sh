#!/usr/bin/env bash
set -euo pipefail

BIN_DEST="${BIN_DEST:-/usr/local/bin}"
LIB_DEST="${LIB_DEST:-/usr/lib/workon/lib}"

sudo install -m 755 workon "$BIN_DEST/workon"

sudo mkdir -p "$LIB_DEST"
sudo rsync -a --delete lib/ "$LIB_DEST/"

echo "workon installed to: $BIN_DEST/workon"
echo "workon libs installed to: $LIB_DEST"
