#!/usr/bin/env bash
set -euo pipefail

__workon_shell_block() {
cat <<'EOF'
# >>> workon shell integration >>>
workon() {
  local out line
  if declare -F deactivate >/dev/null 2>&1; then
    deactivate >/dev/null 2>&1 || true
  fi

  out="$(/usr/local/bin/workon --print)" || return
  [[ -n "$out" ]] || return

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    case "$line" in
      "cd -- "*|"source -- "*) ;;
      *)
        echo "workon: refused unexpected command: $line" >&2
        return 2
        ;;
    esac
  done <<< "$out"

  eval "$out"
}
# <<< workon shell integration <<<
EOF
}

install_shell_integration() {
  local shell="${1:-$(basename "${SHELL:-bash}")}"
  local rc

  case "$shell" in
    bash) rc="$HOME/.bashrc" ;;
    zsh)  rc="$HOME/.zshrc" ;;
    *) echo "workon: unsupported shell: $shell" >&2; return 2 ;;
  esac

  touch "$rc"

  if grep -q '^# >>> workon shell integration >>>$' "$rc"; then
    echo "workon: shell integration already installed"
    return 0
  fi

  cp -a "$rc" "$rc.bak.workon.$(date +%Y%m%d-%H%M%S)"

  {
    echo
    __workon_shell_block
  } >> "$rc"

  echo "workon: installed shell integration in $rc"
  echo "Reload: source $rc"
}

uninstall_shell_integration() {
  local shell="${1:-$(basename "${SHELL:-bash}")}"
  local rc tmp

  case "$shell" in
    bash) rc="$HOME/.bashrc" ;;
    zsh)  rc="$HOME/.zshrc" ;;
    *) echo "workon: unsupported shell: $shell" >&2; return 2 ;;
  esac

  [[ -f "$rc" ]] || return 0

  if ! grep -q '^# >>> workon shell integration >>>$' "$rc"; then
    echo "workon: no shell integration found"
    return 0
  fi

  cp -a "$rc" "$rc.bak.workon.$(date +%Y%m%d-%H%M%S)"

  tmp="$(mktemp)"
  awk '
    BEGIN{del=0}
    /^# >>> workon shell integration >>>$/ {del=1; next}
    /^# <<< workon shell integration <<</ {del=0; next}
    del==0 {print}
  ' "$rc" > "$tmp" && mv "$tmp" "$rc"

  echo "workon: removed shell integration from $rc"
}
