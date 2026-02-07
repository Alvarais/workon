#!/usr/bin/env bash
set -euo pipefail

DEST="${DEST:-/usr/local/bin}"

sudo install -m 755 workon "$DEST/workon"
echo "workon installed to: $DEST/workon"
