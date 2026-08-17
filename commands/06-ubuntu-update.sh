#!/usr/bin/env bash
#
# commands/06-ubuntu-update.sh — Stage 06: Ubuntu package engine.
#
# Wraps: apt update && apt upgrade -y  (inside Ubuntu, non-interactive)
# Engine implementation: lib/ubuntu.sh (cmd_06_ubuntu_update)

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

stage_06_ubuntu_update() {
  recovery_set_context "ubuntu"
  cmd_06_ubuntu_update
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_06_ubuntu_update; then
    printf '%s\n' "Stage 06 complete."
    exit 0
  fi
  exit $?
fi
