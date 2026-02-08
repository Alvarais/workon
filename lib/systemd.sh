#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# systemd user timers (optional)
#
# Units are generated into:
#   $SYSTEMD_USER_DIR   (usually ~/.config/systemd/user)
# ------------------------------------------------------------

__workon_systemd_bin() {
  local bin=""
  bin="$(command -v workon 2>/dev/null || true)"
  [[ -n "$bin" ]] || die "workon not found in PATH (required to generate systemd units)"
  echo "$bin"
}

__workon_write_service() {
  local bin="$1"
  cat > "$SYSTEMD_USER_DIR/workon-reindex.service" <<EOF
[Unit]
Description=workon: reindex projects

[Service]
Type=oneshot
ExecStart=$bin --reindex
EOF
}

__workon_write_boot_timer() {
  cat > "$SYSTEMD_USER_DIR/$BOOT_TIMER" <<'EOF'
[Unit]
Description=workon: reindex projects once after boot/login

[Timer]
OnBootSec=2min
AccuracySec=1min
Unit=workon-reindex.service

[Install]
WantedBy=timers.target
EOF
}

__workon_write_auto_timer() {
  local days="$1"
  cat > "$SYSTEMD_USER_DIR/$AUTO_TIMER" <<EOF
[Unit]
Description=workon: periodic reindex projects

[Timer]
OnUnitActiveSec=${days}d
AccuracySec=1h
Persistent=true
Unit=workon-reindex.service

[Install]
WantedBy=timers.target
EOF
}

systemd_refresh_units() {
  local days bin
  days="$(get_config reindex.days 2>/dev/null || true)"
  days="${days:-$DEFAULT_REINDEX_DAYS}"
  [[ "$days" =~ ^[0-9]+$ ]] || days="$DEFAULT_REINDEX_DAYS"

  bin="$(__workon_systemd_bin)"

  mkdir -p "$SYSTEMD_USER_DIR"
  __workon_write_service "$bin"
  __workon_write_boot_timer
  __workon_write_auto_timer "$days"
}

systemd_enable() {
  local unit="$1"
  systemd_refresh_units

  systemctl --user daemon-reload
  systemctl --user enable "$unit" >/dev/null
  systemctl --user start "$unit" >/dev/null
}

systemd_disable() {
  local unit="$1"
  systemctl --user disable "$unit" >/dev/null 2>&1 || true
  systemctl --user stop "$unit" >/dev/null 2>&1 || true
  systemctl --user daemon-reload >/dev/null 2>&1 || true
}
