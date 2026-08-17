#!/usr/bin/env bash
#
# test-recovery.sh — recovery engine tests.
#
# Recovery must never blindly repeat a failing command, must honour
# MAX_RECOVERY_ATTEMPTS, must honour AUTO_RECOVERY=false, and must never
# trigger destructive actions for a busy/broken Ubuntu container.

# shellcheck disable=SC2034 # globals are consumed by the sourced recovery engine
# shellcheck disable=SC2329 # test functions are invoked indirectly via run_with_recovery
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# shellcheck source=config.sh
. "$PROJECT_ROOT/config.sh"
# shellcheck disable=SC1091 # libs are sourced through a dynamic name
for lib in logger ui runner checker recovery; do
  # shellcheck source=lib/$lib.sh
  . "$PROJECT_ROOT/lib/$lib.sh"
done
# shellcheck source=tests/harness.sh
. "$PROJECT_ROOT/tests/harness.sh"

MAX_RECOVERY_ATTEMPTS=3
RECOVERY_RETRY_DELAY=0
AUTO_RECOVERY="true"

test_recovery_does_not_exceed_max_attempts() {
  local calls=0 rc
  always_fail() {
    calls=$((calls + 1))
    RECOVERY_HINT="permission"
    return 7
  }
  run_with_recovery "always-fail-test" always_fail
  rc=$?
  t_assert_eq "failing step returns its own exit code" "7" "$rc"
  t_assert_eq "recovery never exceeds MAX_RECOVERY_ATTEMPTS" "3" "$calls"
}

test_recovery_retries_until_success() {
  local calls=0 rc
  fail_twice_then_ok() {
    calls=$((calls + 1))
    if [ "$calls" -lt 3 ]; then
      RECOVERY_HINT="permission"
      return 3
    fi
    return 0
  }
  run_with_recovery "fail-twice-test" fail_twice_then_ok
  rc=$?
  t_assert_eq "step recovers and completes" "0" "$rc"
  t_assert_eq "step retried exactly until success" "3" "$calls"
}

test_recovery_honors_auto_recovery_off() {
  local calls=0 rc
  always_fail() {
    calls=$((calls + 1))
    return 5
  }
  AUTO_RECOVERY="false"
  run_with_recovery "no-auto-recovery-test" always_fail
  rc=$?
  t_assert_eq "AUTO_RECOVERY=false fails immediately" "5" "$rc"
  t_assert_eq "AUTO_RECOVERY=false runs once" "1" "$calls"
  AUTO_RECOVERY="true"
}

test_classify_error_hint_override() {
  RECOVERY_HINT="network"
  t_assert_eq "explicit hint overrides classification" "network" "$(recovery_classify_error 0)"
  RECOVERY_HINT=""
}

test_runner_exit_codes() {
  local rc
  run_command "true-test" true
  rc=$?
  t_assert_eq "run_command returns 0 for success" "0" "$rc"
  run_command "false-test" false
  rc=$?
  t_assert_eq "run_command returns 1 for failure" "1" "$rc"
}

test_run_step_display() {
  local out rc
  ok_fn() { return 0; }
  out=$(run_step 1 3 "Fake Stage" ok_fn 2>&1)
  rc=$?
  t_assert_eq "run_step returns success for passing function" "0" "$rc"
  t_assert_contains "run_step displays PASS" "PASS" "$out"
}

test_run_step_failure() {
  local out rc
  bad_fn() { return 9; }
  AUTO_RECOVERY="false"
  out=$(run_step 2 3 "Failing Stage" bad_fn 2>&1)
  rc=$?
  t_assert_eq "run_step returns failure for failing function" "9" "$rc"
  t_assert_contains "run_step displays FAIL" "FAIL" "$out"
  AUTO_RECOVERY="true"
}

test_ubuntu_busy_recovery_is_safe() {
  local installs=0 rc
  proot_distro_install_guard() { installs=$((installs + 1)); }
  RECOVERY_RETRY_DELAY=0
  recovery_attempt "busy-test" "ubuntu_busy"
  rc=$?
  t_assert_eq "ubuntu_busy recovery returns success" "0" "$rc"
  t_assert_eq "ubuntu_busy recovery never re-installs" "0" "$installs"
}

test_unknown_class_stops() {
  local rc
  recovery_attempt "unknown-test" "unknown"
  rc=$?
  t_assert_eq "unknown classification aborts recovery" "1" "$rc"
}

t_section "Retry behaviour"
test_recovery_does_not_exceed_max_attempts
test_recovery_retries_until_success
t_section "Configuration flags"
test_recovery_honors_auto_recovery_off
test_classify_error_hint_override
t_section "Command runner"
test_runner_exit_codes
test_run_step_display
test_run_step_failure
t_section "Safe Ubuntu handling"
test_ubuntu_busy_recovery_is_safe
test_unknown_class_stops

printf '\n'
t_report
