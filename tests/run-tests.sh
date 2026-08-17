#!/usr/bin/env bash
#
# tests/run-tests.sh — run all tests for the Haider Ali OpenCode System.
#
# 1. bash -n syntax check against every .sh file
# 2. each test suite (ui, system, recovery, opencode)
# 3. shellcheck when available

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

ALL_OK=1

syntax_check() {
  local f
  for f in "$PROJECT_ROOT"/*.sh "$PROJECT_ROOT"/lib/*.sh "$PROJECT_ROOT"/commands/*.sh "$PROJECT_ROOT"/tests/*.sh; do
    [ -e "$f" ] || continue
    if bash -n "$f" 2>/dev/null; then
      printf '  ok  - syntax %s\n' "${f#"$PROJECT_ROOT"/}"
    else
      printf '  not ok - syntax %s\n' "${f#"$PROJECT_ROOT"/}"
      ALL_OK=0
    fi
  done
}

shellcheck_all() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    printf '%s\n' "  skip - shellcheck not installed"
    return
  fi
  local f
  for f in "$PROJECT_ROOT"/*.sh "$PROJECT_ROOT"/lib/*.sh "$PROJECT_ROOT"/commands/*.sh "$PROJECT_ROOT"/tests/*.sh; do
    [ -e "$f" ] || continue
    if shellcheck -x "$f" >/dev/null 2>&1; then
      printf '  ok  - shellcheck %s\n' "${f#"$PROJECT_ROOT"/}"
    else
      printf '  not ok - shellcheck %s\n' "${f#"$PROJECT_ROOT"/}"
      shellcheck -x "$f" | sed 's/^/         /'
      ALL_OK=0
    fi
  done
}

printf '%s\n' "== Syntax checks (bash -n) =="
syntax_check

printf '\n%s\n' "== shellcheck (if available) =="
shellcheck_all

printf '\n%s\n' "== Running test suites =="
for t in test-ui.sh test-system.sh test-recovery.sh test-opencode.sh; do
  printf '\n--- %s ---\n' "$t"
  bash "$PROJECT_ROOT/tests/$t"
  rc=$?
  [ "$rc" -eq 0 ] || ALL_OK=0
done

printf '\n'
if [ "$ALL_OK" -eq 1 ]; then
  printf '%s\n' "ALL TESTS PASSED"
  exit 0
fi
printf '%s\n' "SOME TESTS FAILED"
exit 1
