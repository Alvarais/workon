# workon

A lightweight, opinionated project launcher for Linux terminals.

workon indexes local development projects, lets you fuzzy-select them with fzf, jumps into the directory, and automatically activates a local virtual environment when present.

It is designed to be:
- fast (cached index)
- predictable (path-based, not name-based)
- shell-native (pure Bash)
- XDG-compliant
- safe (no implicit eval from user input)

---

WHAT workon CONSIDERS A PROJECT

A directory is indexed only if it contains a local virtual environment:

<project>/.venv/bin/activate

This is intentional.

workon is not a generic directory jumper — it is a Python-centric workflow tool where:
- one project = one venv
- activation is implicit and safe
- no heuristics (.git, pyproject.toml, etc.)

If a directory has no .venv, it is ignored.

---

FEATURES

- Fuzzy project selection via fzf
- Multiple project roots
- Recent projects tracking
- README preview (with bat if available)
- Directory preview fallback (tree / ls)
- Automatic venv activation
- Manual and automatic reindexing
- Optional systemd user timers
- XDG-compliant config and cache layout

---

REQUIREMENTS

- Bash >= 4.3
- fzf (required)
- systemd (optional, for auto/boot reindex)
- bat, tree (optional, preview quality)

Ubuntu example:
sudo apt install fzf tree

---

INSTALLATION

git clone https://github.com/Alvarais/workon.git
cd workon
./install.sh

This installs:
- /usr/local/bin/workon
- /usr/lib/workon/lib/*

---

SHELL INTEGRATION (RECOMMENDED)

Add this to your ~/.bashrc:

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

Reload:
source ~/.bashrc

---

FIRST-TIME SETUP

workon --add-root ~/Projects
workon --reindex
workon

---

USAGE KEYS (INSIDE SELECTOR)

Up/Down : move
Type    : filter
Enter   : open project
Ctrl-R  : reindex and reload
Ctrl-O  : open folder
Esc     : cancel

---

REINDEX CONFIGURATION

Set mode:
workon --set reindex.mode off
workon --set reindex.mode shell
workon --set reindex.mode boot
workon --set reindex.mode auto

Auto mode interval:
workon --set reindex.days 10

Manual reindex:
workon --reindex

Status:
workon --status

---

COMMAND SUMMARY

workon
workon --status
workon --reindex
workon --add-root <dir>
workon --rm-root <dir>
workon --forget <pattern>
workon --set <key> <value>

---

FILE LAYOUT (XDG)

~/.config/workon/config
~/.cache/workon/index.tsv
~/.cache/workon/state

---

DESIGN PRINCIPLES

- Path is identity
- Local venv only
- Explicit automation
- Shell safety
- Fail fast

---

MIT License
