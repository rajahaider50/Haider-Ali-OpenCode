#!/usr/bin/env bash
#
# commands/11-launch.sh — Stage 11: Launch OpenCode AI.
#
# Wraps: opencode  (inside Ubuntu)
# Refuses to launch unless Ubuntu is healthy and node/npm/opencode exist.
# Engine implementation: lib/opencode.sh (cmd_11_launch)

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

stage_11_launch() {
  recovery_set_context "ubuntu"
  cmd_11_launch
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_11_launch; then
    printf '%s\n' "Launch stage complete."
    exit 0
  fi
  exit $?
fi
