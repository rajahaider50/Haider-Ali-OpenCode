#!/usr/bin/env bash
#
# commands/02-proot.sh — Stage 02: proot-distro.
#
# Wraps: pkg install proot-distro -y
# Engine implementation: lib/system.sh (cmd_02_proot)

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

stage_02_proot_distro() {
  recovery_set_context "termux"
  cmd_02_proot
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ui_init
  log_init
  recovery_init
  if stage_02_proot_distro; then
    printf '%s\n' "Stage 02 complete."
    exit 0
  fi
  exit $?
fi
