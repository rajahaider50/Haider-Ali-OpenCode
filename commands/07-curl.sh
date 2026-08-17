#!/usr/bin/env bash
#
# commands/07-curl.sh — Stage 07: curl inside Ubuntu.
#
# Wraps: apt install curl -y  (inside Ubuntu)
# Skipped when curl is already present and verified.
# Engine implementation: lib/opencode.sh (cmd_07_curl)

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

stage_07_curl() {
  recovery_set_context "ubuntu"
  cmd_07_curl
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_07_curl; then
    printf '%s\n' "Stage 07 complete."
    exit 0
  fi
  exit $?
fi
