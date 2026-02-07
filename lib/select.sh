#!/usr/bin/env bash
set -euo pipefail

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------------
# Preview / actions (called by fzf)
# IMPORTANT: these receive the path as $1 (no extra quoting games)
# ------------------------------------------------------------
__workon_preview() {
  local p="${1:-}"
  [[ -n "$p" ]] || exit 0

  # Non-project rows
  [[ "$p" == "__SEP__" || "$p" == "__HDR__" ]] && exit 0

  # fzf may pass an already-escaped token; ensure we don't keep wrapping quotes as literal
  # If p looks like '...'(single-quoted) or "...", strip only the outermost quotes.
  if [[ "$p" =~ ^\'.*\'$ ]]; then p="${p:1:${#p}-2}"; fi
  if [[ "$p" =~ ^\".*\"$ ]]; then p="${p:1:${#p}-2}"; fi

  if [[ ! -d "$p" ]]; then
    echo "[error opening dir]"
    echo
    echo "PATH: $p"
    exit 0
  fi

  echo "PATH: $p"
  echo

  # README-first (maxdepth 1)
  local readme=""
  readme="$(find "$p" -maxdepth 1 -type f \
      \( -iname "README" -o -iname "README.*" -o -iname "README-*" -o -iname "README_*" \) \
      2>/dev/null | head -n 1 || true)"

  if [[ -n "$readme" && -r "$readme" ]]; then
    echo "README: $(basename "$readme")"
    echo "------------------------------------------------------------"
    if has_cmd bat; then
      bat --style=plain --color=always --paging=never "$readme" 2>/dev/null | sed -n "1,240p" || true
    else
      sed -n "1,240p" "$readme" 2>/dev/null || true
    fi
    exit 0
  fi

  # fallback: tree / ls
  if has_cmd tree; then
    tree -a -L 2 --dirsfirst -I ".git|.venv|__pycache__|node_modules|dist|build" "$p" 2>/dev/null | sed -n "1,260p"
  else
    echo "(Tip: install tree for a better preview: sudo apt install tree)"
    echo
    ls -la --color=always "$p" 2>/dev/null | sed -n "1,180p"
  fi
}

__workon_open_folder() {
  local p="${1:-}"
  [[ -n "$p" ]] || exit 0
  [[ "$p" == "__SEP__" || "$p" == "__HDR__" ]] && exit 0
  if [[ "$p" =~ ^\'.*\'$ ]]; then p="${p:1:${#p}-2}"; fi
  if [[ "$p" =~ ^\".*\"$ ]]; then p="${p:1:${#p}-2}"; fi
  [[ -d "$p" ]] || exit 0
  xdg-open "$p" >/dev/null 2>&1 || true
}

__workon_copy_path() {
  local p="${1:-}"
  [[ -n "$p" ]] || exit 0
  [[ "$p" == "__SEP__" || "$p" == "__HDR__" ]] && exit 0
  if [[ "$p" =~ ^\'.*\'$ ]]; then p="${p:1:${#p}-2}"; fi
  if [[ "$p" =~ ^\".*\"$ ]]; then p="${p:1:${#p}-2}"; fi

  if has_cmd wl-copy; then
    printf "%s" "$p" | wl-copy; exit 0
  fi
  if has_cmd xclip; then
    printf "%s" "$p" | xclip -selection clipboard; exit 0
  fi
  if has_cmd xsel; then
    printf "%s" "$p" | xsel --clipboard --input; exit 0
  fi
  exit 0
}

export -f __workon_preview __workon_open_folder __workon_copy_path has_cmd

# ------------------------------------------------------------
# Source printer (TSV)
# col1: kind   (INFO/HDR/ITEM/SEP)
# col2: label  (text to show in list)
# col3: path   (real path, or __HDR__/__SEP__ for non-project rows)
# ------------------------------------------------------------
fzf_source_print() {
  ensure_default_root
  [[ -s "$INDEX_FILE" ]] || die "no projects indexed yet (run: workon --reindex)"

  local -a roots
  mapfile -t roots < <(roots_list)
  (( ${#roots[@]} > 0 )) || die "no roots configured"

  # Unique existing paths count (no duplicates from recent)
  declare -A exists=()
  local stale=0
  while IFS=$'\t' read -r name path last; do
    [[ -n "${path:-}" ]] || continue
    if [[ -d "$path" ]]; then
      exists["$path"]=1
    else
      stale=$((stale+1))
    fi
  done < "$INDEX_FILE"
  local uniq_count="${#exists[@]}"

  # Header block (these will be pinned using --header-lines=2)
  printf "INFO\tProjects: %s\t\n" "$uniq_count"
  printf "INFO\t------------\t\n"

  # Section: Recents
  printf "HDR\tRecents:\t__HDR__\n"

  local printed_recent=0
  while IFS=$'\t' read -r name path last; do
    [[ -n "${path:-}" ]] || continue
    [[ -d "$path" ]] || continue
    printf "ITEM\t  %s\t%s\n" "$name" "$path"
    printed_recent=1
  done < <(
    awk -F'\t' '$3>0 {print}' "$INDEX_FILE" \
      | sort -t $'\t' -k3,3nr \
      | head -n 3
  ) || true

  # Separator between recents and roots
  if (( printed_recent == 1 )); then
    printf "SEP\t\t__SEP__\n"
  fi

  # Sections: Roots
  local r
  for r in "${roots[@]}"; do
    printf "HDR\t%s:\t__HDR__\n" "$r"

    while IFS=$'\t' read -r name path last; do
      [[ -n "${path:-}" ]] || continue
      [[ -d "$path" ]] || continue
      printf "ITEM\t  %s\t%s\n" "$name" "$path"
    done < <(
      awk -F'\t' -v root="$r" 'index($2, root"/")==1 {print $0}' "$INDEX_FILE" \
        | sort -t $'\t' -k1,1
    )
  done
}

# ------------------------------------------------------------
# fzf selector
# ------------------------------------------------------------
select_from_index_fzf() {
  command -v fzf >/dev/null || die "fzf is required (install: sudo apt install fzf)"

  local src_cmd="workon --_fzf-source"
  local reload_cmd="workon --_fzf-reindex-source"

  # Pass path as $1 to bash -lc (no quoting bugs)
  local preview_cmd='bash -lc "__workon_preview \"\$1\"" _ {3}'
  local open_cmd='bash -lc "__workon_open_folder \"\$1\"" _ {3}'
  local copy_cmd='bash -lc "__workon_copy_path \"\$1\"" _ {3}'

  $src_cmd \
    | fzf \
        --ansi \
        --cycle \
        --height=80% \
        --layout=reverse \
        --border \
        --prompt="workon> " \
        --info=hidden \
        --delimiter=$'\t' \
        --with-nth=2 \
        --header-lines=2 \
        --tiebreak=index \
        --header=$'↑/↓ move | Type: filter\nEnter: select | Esc: cancel\nCtrl-R: reindex+reload\nCtrl-O: open folder \nCtrl-C: copy path\n' \
        --preview="$preview_cmd" \
        --preview-window='right:60%:wrap' \
        --bind "ctrl-r:reload($reload_cmd)" \
        --bind "ctrl-o:execute-silent($open_cmd)" \
        --bind "ctrl-c:execute-silent($copy_cmd)" \
    | awk -F'\t' '
        # Only real selectable projects: ITEM + real path
        $1=="ITEM" && $3 != "" && $3 != "__HDR__" && $3 != "__SEP__" {print $3; exit}
      '
}
