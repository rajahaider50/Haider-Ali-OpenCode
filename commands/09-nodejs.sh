#!/usr/bin/env bash
#
# commands/09-nodejs.sh — Stage 09: Node.js runtime inside Ubuntu.
#
# Wraps: apt install -y nodejs  (inside Ubuntu)
# Already-installed Node with the required major version is skipped.
# Engine implementation: lib/opencode.sh (cmd_09_nodejs)

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

stage_09_nodejs() {
  recovery_set_context "ubuntu"
  cmd_09_nodejs
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_09_nodejs; then
    printf '%s\n' "Stage 09 complete."
    exit 0
  fi
  exit $?
fi
