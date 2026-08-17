#!/usr/bin/env bash
#
# commands/10-opencode.sh — Stage 10: OpenCode AI inside Ubuntu.
#
# Wraps: npm i -g opencode-ai  (inside Ubuntu)
# Already-installed OpenCode is verified, not reinstalled.
# Engine implementation: lib/opencode.sh (cmd_10_opencode)

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

stage_10_opencode() {
  recovery_set_context "ubuntu"
  cmd_10_opencode
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_10_opencode; then
    printf '%s\n' "Stage 10 complete."
    exit 0
  fi
  exit $?
fi
