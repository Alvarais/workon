#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Paths & constants (centralized)
# ============================================================
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/workon"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/workon"

CONFIG_FILE="$CONFIG_DIR/config"
STATE_FILE="$CACHE_DIR/state"
INDEX_FILE="$CACHE_DIR/index.tsv"

SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
BOOT_TIMER="workon-reindex-boot.timer"
AUTO_TIMER="workon-reindex-auto.timer"

DEFAULT_REINDEX_DAYS=10

mkdir -p "$CONFIG_DIR" "$CACHE_DIR" "$SYSTEMD_USER_DIR"
touch "$INDEX_FILE"
touch "$STATE_FILE"

# ============================================================
# Generic helpers
# ============================================================
now_epoch() { date +%s; }

die() { echo "workon: $*" >&2; exit 1; }

get_state() { grep -E "^$1=" "$STATE_FILE" 2>/dev/null | cut -d= -f2-; }

set_state() {
  grep -v "^$1=" "$STATE_FILE" 2>/dev/null > "${STATE_FILE}.tmp" || true
  echo "$1=$2" >> "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

get_config() { grep -E "^$1=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2-; }

set_config() {
  grep -v "^$1=" "$CONFIG_FILE" 2>/dev/null > "${CONFIG_FILE}.tmp" || true
  echo "$1=$2" >> "${CONFIG_FILE}.tmp"
  mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

