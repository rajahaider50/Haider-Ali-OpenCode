#!/usr/bin/env bash
#
# test-system.sh — system / environment detection tests.
#
# Config defaults, architecture detection, Node version parsing, Termux,
# proot-distro, Ubuntu state, storage, network and Ubuntu engine presence.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# shellcheck source=config.sh
. "$PROJECT_ROOT/config.sh"
# shellcheck disable=SC1091 # libs are sourced through a dynamic name
for lib in logger ui checker ubuntu; do
  # shellcheck source=lib/$lib.sh
  . "$PROJECT_ROOT/lib/$lib.sh"
done
# shellcheck source=tests/harness.sh
. "$PROJECT_ROOT/tests/harness.sh"

test_config() {
  t_assert_eq "APP_NAME is set" "Haider Ali OpenCode System" "$APP_NAME"
  t_assert_eq "APP_OWNER is set" "Haider Ali" "$APP_OWNER"
  t_assert_eq "APP_VERSION is set" "1.0.0" "$APP_VERSION"
  t_assert_eq "UBUNTU_NAME is set" "ubuntu" "$UBUNTU_NAME"
  t_assert_contains "storage bind configured" "/storage/emulated/0" "$UBUNTU_STORAGE_BIND"
  t_assert_contains "storage bind target" "/mobile_storage" "$UBUNTU_STORAGE_BIND"
  t_assert_eq "NODE_MAJOR_VERSION is set" "20" "$NODE_MAJOR_VERSION"
  t_assert_eq "OPENCODE_PACKAGE is set" "opencode-ai" "$OPENCODE_PACKAGE"
  t_assert_eq "MAX_RECOVERY_ATTEMPTS is 3" "3" "$MAX_RECOVERY_ATTEMPTS"
  t_assert_eq "AUTO_RECOVERY defaults to true" "true" "$AUTO_RECOVERY"
  t_assert_eq "STAGE_TOTAL is 11" "11" "$STAGE_TOTAL"
}

test_architecture() {
  local arch
  arch=$(check_architecture)
  t_assert "architecture is non-empty" test -n "$arch"
  t_assert_eq "architecture matches uname" "$(uname -m)" "$arch"
}

test_node_version_parsing() {
  t_assert_eq "v20.11.0 -> 20" "20" "$(node_major_from_version "v20.11.0")"
  t_assert_eq "v18.19.1 -> 18" "18" "$(node_major_from_version "v18.19.1")"
  t_assert_eq "22.1.0 -> 22" "22" "$(node_major_from_version "22.1.0")"
  t_assert_eq "empty input -> empty" "" "$(node_major_from_version "")"
}

test_termux_detection() {
  if [ -n "${PREFIX:-}" ] && [ -d "${PREFIX:-}" ]; then
    t_assert "check_termux succeeds in Termux" check_termux
  else
    t_assert_rc "check_termux fails outside Termux" 1 check_termux
  fi
}

test_proot_detection() {
  if command -v proot-distro >/dev/null 2>&1; then
    t_assert "proot-distro detected" check_proot_distro
  else
    t_assert_rc "proot-distro missing returns failure" 1 check_proot_distro
  fi
}

test_ubuntu_state_detection() {
  local state
  state=$(ubuntu_detect_state)
  case "$state" in
    NO_PROOT|NOT_INSTALLED|INSTALLED|HEALTHY|BUSY|BROKEN|UNKNOWN)
      t_ok "ubuntu_detect_state returned a known state ($state)"
      ;;
    *)
      t_not_ok "ubuntu_detect_state returned an unknown value ($state)"
      ;;
  esac
}

test_storage_detection() {
  if [ -d "/storage/emulated/0" ]; then
    t_assert "shared storage detected" check_storage
  else
    t_assert_rc "shared storage missing returns failure" 1 check_storage
  fi
}

test_network_detection() {
  if check_network; then
    t_ok "network is reachable in this environment"
  else
    t_ok "network is not reachable in this environment"
  fi
}

test_ubuntu_engine_availability() {
  local rc
  t_assert "run_in_ubuntu is defined" declare -F run_in_ubuntu
  t_assert "cmd_04_ubuntu is defined" declare -F cmd_04_ubuntu
  t_assert "cmd_05_ubuntu_login is defined" declare -F cmd_05_ubuntu_login
  t_assert "cmd_06_ubuntu_update is defined" declare -F cmd_06_ubuntu_update
  if command -v proot-distro >/dev/null 2>&1; then
    t_skip "proot-distro present — not testing missing-tool path"
  else
    run_in_ubuntu "true" >/dev/null 2>&1
    rc=$?
    t_assert "run_in_ubuntu fails cleanly without proot-distro" test "$rc" -ne 0
  fi
}

t_section "Configuration"
test_config
t_section "Architecture"
test_architecture
t_section "Node version parsing"
test_node_version_parsing
t_section "Termux detection"
test_termux_detection
t_section "proot-distro detection"
test_proot_detection
t_section "Ubuntu state detection"
test_ubuntu_state_detection
t_section "Storage detection"
test_storage_detection
t_section "Network detection"
test_network_detection
t_section "Ubuntu engine functions"
test_ubuntu_engine_availability

printf '\n'
t_report
