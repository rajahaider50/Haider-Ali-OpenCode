#!/usr/bin/env bash
#
# commands/05-ubuntu-login.sh — Stage 05: Ubuntu login / storage bind.
#
# Wraps: proot-distro login ubuntu --bind /storage/emulated/0:/mobile_storage
# Non-interactive; the bind is verified inside the container.
# Engine implementation: lib/ubuntu.sh (cmd_05_ubuntu_login, run_in_ubuntu)

if [ -z "${HAIDER_OPENCODE_LOADED:-}" ]; then
  HAIDER_CMD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  # shellcheck source=config.sh
  . "$HAIDER_CMD_ROOT/config.sh"
  # shellcheck disable=SC1091 # libs are sourced through a dynamic name
  for lib in logger ui runner checker recovery system ubuntu opencode; do
    # shellcheck source=lib/$lib.sh
    . "$HAIDER_CMD_ROOT/lib/$lib.sh"
  done
  HAIDER_OPENCODE_LOADED=1
fi

stage_05_ubuntu_login() {
  recovery_set_context "termux"
  cmd_05_ubuntu_login
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_05_ubuntu_login; then
    printf '%s\n' "Stage 05 complete."
    exit 0
  fi
  exit $?
fi
