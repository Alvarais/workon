#!/usr/bin/env bash
set -euo pipefail

do_reindex() {
  ensure_default_root

  local roots
  mapfile -t roots < <(roots_list)

  echo "workon: reindexing projects..."
  : > "${INDEX_FILE}.tmp"

  local r dir name base
  for r in "${roots[@]}"; do
    [[ -d "$r" ]] || continue

    # Apenas 1 nível abaixo do root
        for dir in "$r"/*; do
      [[ -d "$dir" ]] || continue
      base="$(basename "$dir")"

      case "$base" in
        .*|__pycache__|node_modules|dist|build|.venv|venv|.tox|.mypy_cache|.pytest_cache)
          continue
          ;;
      esac

      # Workon is for venv projects only
      [[ -f "$dir/.venv/bin/activate" ]] || continue

      name="$base"
      index_write_line "$name" "$dir" "0" >> "${INDEX_FILE}.tmp"
    done
  done

  mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
  set_state last_reindex "$(now_epoch)"
  echo "workon: indexed $(wc -l < "$INDEX_FILE") projects"
}

reindex_if_due() {
  local days last now delta limit
  days="$(get_config reindex.days || echo "$DEFAULT_REINDEX_DAYS")"
  last="$(get_state last_reindex || echo 0)"
  now="$(now_epoch)"
  delta=$(( now - last ))
  limit=$(( days * 86400 ))
  (( delta >= limit )) && do_reindex
}
