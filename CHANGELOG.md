# Changelog

## v0.1.1 — 2026-02-08
- UX improvements in selector.
- Ctrl-Y clipboard copy is silent by default (optional notifications via config).
- systemd user units are generated automatically under ~/.config/systemd/user.
- Documentation cleanup.

## v0.1.0 — 2026-02-07
- Initial public release.
- Installs binary to `/usr/local/bin/workon` and libraries to `/usr/lib/workon/lib`.
- Project detection based on local `.venv/bin/activate`.
- Added `--print` mode to support safe shell activation via wrapper.
