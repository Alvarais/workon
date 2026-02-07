#!/usr/bin/env bash
set -euo pipefail

systemd_enable() {
  local unit="$1"
  [[ -f "$SYSTEMD_USER_DIR/$unit" ]] || die "systemd unit not installed: $unit"
  systemctl --user daemon-reload
  systemctl --user enable "$unit" >/dev/null
  systemctl --user start "$unit" >/dev/null
}

systemd_disable() {
  local unit="$1"
  systemctl --user disable "$unit" >/dev/null 2>&1 || true
  systemctl --user stop "$unit" >/dev/null 2>&1 || true
}
