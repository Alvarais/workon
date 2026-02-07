# workon

A lightweight, opinionated **project launcher** for Linux terminals.

`workon` indexes local development projects, lets you **fuzzy‑select** them with `fzf`, jumps into the directory, and **automatically activates a local virtual environment** when present.

It is designed to be:

* fast (cached index)
* predictable (path‑based, not name‑based)
* shell‑native (pure Bash)
* XDG‑compliant

---

## What `workon` considers a project

A directory is indexed **only if it contains a local virtual environment**:

```
<project>/.venv/bin/activate
```

This is intentional.

`workon` is not a generic directory jumper — it is a **Python‑centric workflow tool** where:

* one project = one venv
* activation is implicit and safe

Other markers (`.git`, `pyproject.toml`, etc.) may exist, but **`.venv` is the gating rule**.

---

## Features

* 🔍 Fuzzy project selection via `fzf`
* 📂 Multiple project roots supported
* 🧠 Recents tracking (last‑used projects)
* 📖 README preview (with `bat` if available)
* 🌳 Directory preview fallback (`tree` / `ls`)
* ⚙️ Automatic venv activation
* 🔁 Manual and automatic reindexing
* 🕒 systemd user timers (optional)
* 📁 XDG‑compliant config/cache layout

---

## Installation

### Requirements

* Bash ≥ 4.3
* `fzf`
* (optional) `bat`, `tree`

Install dependencies:

```bash
sudo apt install fzf tree
```

### Install `workon`

```bash
git clone https://github.com/<you>/workon.git
cd workon
sudo install -m 755 workon /usr/local/bin/workon
```

> `workon` is a single entrypoint script that sources its internal modules.

---

## First‑time setup

Add a project root (directories containing your projects):

```bash
workon --add-root ~/Projects
```

Index projects:

```bash
workon --reindex
```

Launch:

```bash
workon
```

---

## Usage

### Open project selector

```bash
workon
```

### Inside the selector

| Key    | Action                      |
| ------ | --------------------------- |
| ↑ ↓    | Move                        |
| Type   | Filter                      |
| Enter  | Open project                |
| Ctrl‑R | Reindex & reload            |
| Ctrl‑O | Open folder in file manager |
| Ctrl‑C | Copy project path           |
| Esc    | Cancel                      |

---

## Commands

```bash
workon --reindex           # rebuild project index
workon --add-root <dir>    # add a root directory
workon --rm-root <dir>     # remove a root directory
workon --forget <pattern> # remove index entries
```

---

## File layout

```text
~/.config/workon/
  └── config           # roots & settings

~/.cache/workon/
  ├── index.tsv        # project index
  └── state            # last reindex timestamp
```

---

## Design principles

* **Path is identity** — names may collide, paths must not
* **Local venv only** — no global Python pollution
* **Explicit automation** — timers are opt‑in
* **Fail fast** — `set -euo pipefail`

---

## Roadmap (deliberately small)

* `--init` helper (create `.venv`)
* Shell completion
* Optional non‑Python project mode

---

## Philosophy

`workon` exists to reduce cognitive overhead.

You shouldn’t think about:

* where the project is
* whether the venv is active
* how to jump contexts

You should think about **the work**.

---

MIT License

