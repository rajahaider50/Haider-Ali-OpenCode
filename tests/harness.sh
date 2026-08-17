#!/usr/bin/env bash
#
# tests/harness.sh — minimal test harness for the Haider Ali OpenCode System.

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

t_ok() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf '  ok  - %s\n' "$1"
}

t_not_ok() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '  not ok - %s\n' "$1"
}

t_skip() {
  SKIP_COUNT=$((SKIP_COUNT + 1))
  printf '  skip - %s\n' "$1"
}

t_assert() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    t_ok "$desc"
  else
    t_not_ok "$desc"
  fi
}

t_assert_rc() {
  local desc="$1" expected="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq "$expected" ]; then
    t_ok "$desc"
  else
    t_not_ok "$desc (expected rc=$expected, got rc=$rc)"
  fi
}

t_assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    t_ok "$desc"
  else
    t_not_ok "$desc (expected '$expected', got '$actual')"
  fi
}

t_assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  case "$haystack" in
    *"$needle"*) t_ok "$desc" ;;
    *) t_not_ok "$desc (missing '$needle')" ;;
  esac
}

t_section() {
  printf '\n# === %s ===\n' "$1"
}

t_report() {
  printf '\n----------------------------------------\n'
  printf 'Passed: %d   Failed: %d   Skipped: %d\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
  if [ "$FAIL_COUNT" -eq 0 ]; then
    printf 'RESULT: PASS\n'
    return 0
  fi
  printf 'RESULT: FAIL\n'
  return 1
}
