# workon

**workon** is a fast, terminal‑first project selector designed to:

- jump between projects (`cd` safely in the current shell)
- activate a local Python virtual environment automatically (`.venv/`)
- keep a lightweight index of recent and known projects
- integrate cleanly with `fzf` for interactive selection

It is intentionally minimal, dependency‑light, and auditable.

---

## Features

- Interactive project selection using `fzf`
- Automatic activation of `.venv` when present
- Recent projects tracking
- Multiple project roots support
- Safe shell integration (opt‑in)
- Wayland and X11 clipboard support
- Optional systemd user timers for background reindexing

---

## Requirements

- bash ≥ 4
- `fzf`
- Optional:
  - `wl-clipboard` (Wayland)
  - `xclip` or `xsel` (X11)
  - `systemd` (for background reindex timers)

---

## Installation

```bash
git clone https://github.com/Alvarais/workon.git
cd workon
sudo ./install.sh
```

This installs:
- `/usr/local/bin/workon`
- supporting scripts under `/usr/local/lib/workon`

No shell configuration is modified automatically.

---

## Shell integration (recommended)

To allow `workon` to change directory and activate virtualenvs **in your current shell**, enable the opt‑in shell integration:

```bash
workon --install-shell
source ~/.bashrc
```

To remove it:

```bash
workon --uninstall-shell
```

### Why this exists

A subprocess cannot modify the parent shell environment.
This integration installs a **validated wrapper** that:

- executes only `cd --` and `source --`
- rejects any unexpected commands
- avoids unsafe `eval` usage

The integration is:
- opt‑in
- idempotent
- reversible
- backed up automatically

Supported shells:
- bash
- zsh

---

## Usage

```bash
workon
```

Keys inside selector:

- `Enter` → activate project
- `Ctrl‑O` → open folder
- `Ctrl‑Y` → copy project path to clipboard (silent by default)
- `Ctrl‑R` → reindex projects
- `Esc` / `Ctrl‑C` → cancel

---

## Clipboard behavior

Clipboard copy is **silent by default**.

Enable notification feedback:

```bash
workon --set ui.copy_feedback on
```

Disable again:

```bash
workon --set ui.copy_feedback off
```

---

## Reindexing

Manual:

```bash
workon --reindex
```

Automatic (systemd user timers):

```bash
workon --set reindex.mode boot
workon --set reindex.mode auto
```

Timers are generated automatically under:

```
~/.config/systemd/user/
```

---

## Philosophy

- predictable behavior
- no magic shell modification
- no hidden eval
- explicit opt‑in for anything invasive

---

## License

MIT
