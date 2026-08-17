#!/usr/bin/env bash
#
# runner.sh — Command execution engine.
#
#   run_command           run a command with live output, logging, exit code
#   capture_command_output run a command quietly and store its stdout
#   run_with_logging      alias of run_command for readability
#   run_step              run a stage function under the recovery engine
#   run_step_plain        run a stage function WITHOUT recovery (launch stage)

run_command() {
  local label="$1"
  shift
  local tmp rc
  tmp=$(mktemp) || { ui_error "Could not create temporary output file."; return 1; }
  log_command "RUN: $*"
  ui_secondary "Running: $*"
  if "$@" > >(tee "$tmp") 2>&1; then
    rc=0
  else
    rc=$?
  fi
  log_command_output "$tmp"
  rm -f "$tmp"
  log_result "EXIT: $rc — $label"
  return "$rc"
}

capture_command_output() {
  local var="$1"
  shift
  local out rc
  out=$("$@" 2>&1)
  rc=$?
  printf -v "$var" '%s' "$out"
  log_command "CAPTURE: $*"
  log_result "CAPTURED: $var (exit=$rc)"
  return "$rc"
}

run_with_logging() {
  run_command "$@"
}

run_step() {
  local number="$1" total="$2" name="$3"
  shift 3
  local start duration rc
  ui_stage_begin "$number" "$total" "$name"
  start=$(date +%s)
  run_with_recovery "$name" "$@"
  rc=$?
  duration=$(( $(date +%s) - start ))
  if [ "$rc" -eq 0 ]; then
    ui_stage_end "pass" "$name" "$rc" "$duration"
  else
    ui_stage_end "fail" "$name" "$rc" "$duration"
  fi
  return "$rc"
}

run_step_plain() {
  local number="$1" total="$2" name="$3" fn="$4"
  local start duration rc
  ui_stage_begin "$number" "$total" "$name"
  start=$(date +%s)
  "$fn"
  rc=$?
  duration=$(( $(date +%s) - start ))
  if [ "$rc" -eq 0 ]; then
    ui_stage_end "pass" "$name" "$rc" "$duration"
  else
    ui_stage_end "fail" "$name" "$rc" "$duration"
  fi
  return "$rc"
}
