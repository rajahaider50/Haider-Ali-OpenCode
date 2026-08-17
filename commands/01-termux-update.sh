#!/usr/bin/env bash
#
# commands/01-termux-update.sh — Stage 01: Termux package engine.
#
# Wraps: pkg update && pkg upgrade -y
# Engine implementation: lib/system.sh (cmd_01_termux_update)

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

stage_01_termux_update() {
  recovery_set_context "termux"
  cmd_01_termux_update
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_01_termux_update; then
    printf '%s\n' "Stage 01 complete."
    exit 0
  fi
  exit $?
fi
