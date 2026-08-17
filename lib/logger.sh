#!/usr/bin/env bash
#
# logger.sh — Logging system.
#
# Every installation run gets its own log file under $LOG_DIRECTORY named:
#   haider-opencode-YYYY-MM-DD-HHMMSS.log
# Logs contain commands, exit codes, stage progress, recovery attempts and
# the final result. Secrets and authentication tokens must never be logged.

LOG_FILE=""

log_init() {
  if [ "${ENABLE_LOGGING:-true}" != "true" ]; then
    LOG_FILE="/dev/null"
    return 0
  fi
  mkdir -p "$LOG_DIRECTORY" || return 1
  LOG_FILE="${LOG_DIRECTORY}/${LOG_FILENAME_PREFIX}-$(date +%Y-%m-%d-%H%M%S).log"
  : > "$LOG_FILE" || return 1
  return 0
}

log_write() {
  local level="$1"
  shift
  if [ -z "$LOG_FILE" ] || [ "$LOG_FILE" = "/dev/null" ]; then
    return 0
  fi
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

log_info()     { log_write "INFO"    "$*"; }
log_warn()     { log_write "WARN"    "$*"; }
log_error()    { log_write "ERROR"   "$*"; }
log_debug()    { log_write "DEBUG"   "$*"; }
log_step()     { log_write "STEP"    "$*"; }
log_command()  { log_write "CMD"     "$*"; }
log_result()   { log_write "RESULT"  "$*"; }
log_recovery() { log_write "RECOVERY" "$*"; }

log_command_output() {
  local file="$1"
  if [ -z "$LOG_FILE" ] || [ "$LOG_FILE" = "/dev/null" ]; then
    return 0
  fi
  while IFS= read -r line; do
    printf '  | %s\n' "$line" >> "$LOG_FILE" 2>/dev/null || true
  done < "$file"
}
