#!/usr/bin/env bash
#
# test-opencode.sh — Node.js / OpenCode detection tests.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# shellcheck source=config.sh
. "$PROJECT_ROOT/config.sh"
# shellcheck disable=SC1091 # libs are sourced through a dynamic name
for lib in logger ui checker; do
  # shellcheck source=lib/$lib.sh
  . "$PROJECT_ROOT/lib/$lib.sh"
done
# shellcheck source=tests/harness.sh
. "$PROJECT_ROOT/tests/harness.sh"

test_config_versions() {
  t_assert_eq "NODE_MAJOR_VERSION is 20" "20" "$NODE_MAJOR_VERSION"
  t_assert_eq "OPENCODE_PACKAGE is opencode-ai" "opencode-ai" "$OPENCODE_PACKAGE"
  t_assert_contains "NodeSource URL targets configured major" "setup_20.x" "$NODESOURCE_SETUP_URL"
}

test_node_detection() {
  if command -v node >/dev/null 2>&1; then
    t_assert "node binary detected" check_node
  else
    t_assert_rc "node missing returns failure" 1 check_node
  fi
}

test_npm_detection() {
  if command -v npm >/dev/null 2>&1; then
    t_assert "npm binary detected" check_npm
  else
    t_assert_rc "npm missing returns failure" 1 check_npm
  fi
}

test_opencode_detection() {
  if command -v opencode >/dev/null 2>&1; then
    t_assert "opencode binary detected" check_opencode
  else
    t_assert_rc "opencode missing returns failure" 1 check_opencode
  fi
}

test_version_parsing() {
  t_assert_eq "v20.19.0 -> 20" "20" "$(node_major_from_version "v20.19.0")"
  t_assert_eq "v22.1.0 -> 22" "22" "$(node_major_from_version "v22.1.0")"
  t_assert_eq "no leading v" "18" "$(node_major_from_version "18.5.0")"
  t_assert_eq "empty input yields empty" "" "$(node_major_from_version "")"
}

t_section "Version configuration"
test_config_versions
t_section "Node.js detection"
test_node_detection
t_section "npm detection"
test_npm_detection
t_section "OpenCode detection"
test_opencode_detection
t_section "Version parsing"
test_version_parsing

printf '\n'
t_report
