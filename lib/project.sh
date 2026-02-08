#!/usr/bin/env bash
set -euo pipefail

is_project_dir() {
  local dir="$1"
  [[ -f "$dir/.venv/bin/activate" ]]
}

find_project_upwards() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    is_project_dir "$dir" && { echo "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  return 1
}

activate_venv_if_present() {
  local dir="$1"
  if [[ -f "$dir/.venv/bin/activate" ]]; then
    # shellcheck disable=SC1090
    source "$dir/.venv/bin/activate"
    [[ -t 1 ]] && echo "workon: activated venv in $dir"
  else
    [[ -t 1 ]] && echo "workon: no .venv found in $dir"
  fi
}

open_project() {
  local path="$1"
  [[ -d "$path" ]] || die "path not found: $path"
  local name
  name="$(basename "$path")"
  cd "$path"
  index_update_last_used "$name" "$path"
  activate_venv_if_present "$path"
}
