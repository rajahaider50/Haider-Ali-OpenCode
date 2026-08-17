#!/usr/bin/env bash
#
# commands/08-node-repository.sh — Stage 08: Node.js repository.
#
# Wraps: curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
# The setup script is downloaded over HTTPS, validated, then executed —
# never blindly piped. Engine implementation: lib/opencode.sh (cmd_08_...)

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

stage_08_node_repository() {
  recovery_set_context "ubuntu"
  cmd_08_node_repository
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_08_node_repository; then
    printf '%s\n' "Stage 08 complete."
    exit 0
  fi
  exit $?
fi
