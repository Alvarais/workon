#!/usr/bin/env bash
set -euo pipefail

roots_list() {
  grep -E '^root=' "$CONFIG_FILE" 2>/dev/null | cut -d= -f2- || true
}

roots_add() {
  local dir="$1"
  [[ -n "$dir" ]] || die "usage: workon --add-root <dir>"
  dir="$(realpath -m "$dir")"
  [[ -d "$dir" ]] || die "root not found: $dir"

  if roots_list | grep -Fxq "$dir"; then
    echo "workon: root already exists: $dir"
    return 0
  fi

  echo "root=$dir" >> "$CONFIG_FILE"
  echo "workon: added root: $dir"
}

roots_rm() {
  local dir="$1"
  [[ -n "$dir" ]] || die "usage: workon --rm-root <dir>"
  dir="$(realpath -m "$dir")"

  if ! roots_list | grep -Fxq "$dir"; then
    die "root not found in config: $dir"
  fi

  grep -v -F "root=$dir" "$CONFIG_FILE" 2>/dev/null > "${CONFIG_FILE}.tmp" || true
  mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
  echo "workon: removed root: $dir"
}

ensure_default_root() {
  # Portabilidade: default em ~/Projects (sem assumir pt_BR)
  if ! roots_list | grep -q .; then
    local default="$HOME/Projects"
    mkdir -p "$default"
    echo "root=$default" >> "$CONFIG_FILE"
    echo "workon: no roots configured; created default root: $default" >&2
  fi
}
