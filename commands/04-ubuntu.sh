#!/usr/bin/env bash
#
# commands/04-ubuntu.sh — Stage 04: Ubuntu container.
#
# Wraps: proot-distro install ubuntu
# The install is NEVER run blindly: ubuntu_detect_state drives the action.
# Engine implementation: lib/ubuntu.sh (cmd_04_ubuntu)

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

stage_04_ubuntu() {
  recovery_set_context "termux"
  cmd_04_ubuntu
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_04_ubuntu; then
    printf '%s\n' "Stage 04 complete."
    exit 0
  fi
  exit $?
fi
