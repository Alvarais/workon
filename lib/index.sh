#!/usr/bin/env bash
set -euo pipefail

index_write_line() {
  local name="$1" path="$2" last="$3"
  printf "%s\t%s\t%s\n" "$name" "$path" "$last"
}

index_update_last_used() {
  local name="$1" path="$2" now
  now="$(now_epoch)"

  # Remove existing entry by PATH (safe with duplicate names)
  awk -F'\t' -v p="$path" '($2 != p) {print}' "$INDEX_FILE" > "${INDEX_FILE}.tmp" || true
  index_write_line "$name" "$path" "$now" >> "${INDEX_FILE}.tmp"
  mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
}

index_forget() {
  local needle="$1"
  [[ -n "$needle" ]] || die "usage: workon --forget <name|path>"
  if grep -Fq "$needle" "$INDEX_FILE"; then
    grep -v -F "$needle" "$INDEX_FILE" > "${INDEX_FILE}.tmp" || true
    mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
    echo "workon: forgot entries matching: $needle"
  else
    echo "workon: no index entries match: $needle"
  fi
}

resolve_name_to_paths() {
  local name="$1"
  [[ -n "$name" ]] || return 1
  awk -F'\t' -v n="$name" '$1==n {print $2}' "$INDEX_FILE"
}

