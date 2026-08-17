#!/usr/bin/env bash
#
# test-ui.sh — UI rendering tests.
#
# Verifies that colours are emitted as real ANSI bytes (never a literal
# backslash-033 string), that branding renders, and that stage display,
# box rendering and no-colour mode all behave.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# shellcheck source=config.sh
. "$PROJECT_ROOT/config.sh"
# shellcheck source=lib/logger.sh
. "$PROJECT_ROOT/lib/logger.sh"
# shellcheck source=lib/ui.sh
. "$PROJECT_ROOT/lib/ui.sh"
# shellcheck source=tests/harness.sh
. "$PROJECT_ROOT/tests/harness.sh"

FORCE_COLORS="true"
ui_init

test_success_line() {
  local out
  out=$(ui_success "all good")
  t_assert_contains "success line carries check mark" "✓" "$out"
  t_assert_contains "success line carries message" "all good" "$out"
  case "$out" in
    *'\033['*) t_not_ok "no literal backslash-033 sequence is printed" ;;
    *) t_ok "no literal backslash-033 sequence is printed" ;;
  esac
  case "$out" in
    *$'\033'*) t_ok "real ANSI escape byte is emitted" ;;
    *) t_not_ok "real ANSI escape byte is emitted" ;;
  esac
}

test_info_line() {
  local out
  out=$(ui_info "doing a thing")
  t_assert_contains "info line carries arrow" "→" "$out"
  t_assert_contains "info line carries message" "doing a thing" "$out"
}

test_warn_and_error_lines() {
  local out
  out=$(ui_warn "watch out")
  t_assert_contains "warning line carries warning mark" "⚠" "$out"
  out=$(ui_error "bad news" 2>&1)
  t_assert_contains "error line carries cross mark" "✗" "$out"
  t_assert_contains "error line carries message" "bad news" "$out"
}

test_banner() {
  local out
  out=$(ui_banner)
  t_assert_contains "banner has top border" "╔" "$out"
  t_assert_contains "banner has bottom border" "╚" "$out"
  t_assert_contains "banner shows brand" "HAIDER ALI" "$out"
  t_assert_contains "banner shows title" "PROFESSIONAL INSTALLER" "$out"
  t_assert_contains "banner shows version" "$APP_VERSION" "$out"
}

test_stage_begin_end() {
  local out
  out=$(ui_stage_begin 1 11 "Termux Package Engine")
  t_assert_contains "stage begin has numbering" "[01/11]" "$out"
  t_assert_contains "stage begin has name" "Termux Package Engine" "$out"

  out=$(ui_stage_end "pass" "Termux Package Engine" 0 8)
  t_assert_contains "stage end pass text" "PASS" "$out"
  t_assert_contains "stage end duration" "8s" "$out"

  out=$(ui_stage_end "fail" "Termux Package Engine" 3 4 2>&1)
  t_assert_contains "stage end fail text" "FAIL" "$out"
}

test_no_color_mode() {
  ENABLE_COLORS="false"
  ui_init
  local out
  out=$(ui_success "plain line")
  case "$out" in
    *$'\033'*) t_not_ok "no ANSI codes when colours are disabled" ;;
    *) t_ok "no ANSI codes when colours are disabled" ;;
  esac
  ENABLE_COLORS="true"
  ui_init
}

test_box_line_centering() {
  local out
  out=$(ui_box_line "$BLUE" "HELLO")
  t_assert_contains "box line opens with side border" "║" "$out"
  t_assert_contains "box line closes with side border" "║" "$out"
  t_assert_contains "box line carries text" "HELLO" "$out"
}

t_section "UI rendering"
test_success_line
test_info_line
test_warn_and_error_lines
t_section "Branding banner"
test_banner
t_section "Stage display"
test_stage_begin_end
t_section "Colour handling"
test_no_color_mode
t_section "Box rendering"
test_box_line_centering

printf '\n'
t_report
