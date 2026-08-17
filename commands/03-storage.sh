#!/usr/bin/env bash
#
# commands/03-storage.sh — Stage 03: Android shared storage.
#
# Wraps: termux-setup-storage
# Only requested when /storage/emulated/0 is not already accessible.
# Engine implementation: lib/system.sh (cmd_03_storage)

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

stage_03_storage() {
  recovery_set_context "termux"
  cmd_03_storage
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_03_storage; then
    printf '%s\n' "Stage 03 complete."
    exit 0
  fi
  exit $?
fi
