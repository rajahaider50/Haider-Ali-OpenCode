#!/usr/bin/env bash
#
# recovery.sh — Safe recovery engine.
#
# Policy:
#   - Classify a failure before acting on it.
#   - Never blindly repeat the same failing command.
#   - Never delete Ubuntu, user files or package databases.
#   - Stop with diagnostics when no safe recovery exists.
#
# Stages can steer classification by setting a hint before returning an
# error (e.g. recovery_set_hint "ubuntu_busy"), which the recovery engine
# uses to choose a safe, non-destructive action.

RECOVERY_HINT=""
RECOVERY_CONTEXT="termux"
RECOVERY_LAST_LABEL=""
RECOVERY_LAST_CLASS=""
RECOVERY_LAST_RC=0

recovery_init() {
  RECOVERY_HINT=""
  RECOVERY_CONTEXT="termux"
  RECOVERY_LAST_LABEL=""
  RECOVERY_LAST_CLASS=""
  RECOVERY_LAST_RC=0
}

recovery_set_hint()    { RECOVERY_HINT="$1"; }
recovery_set_context() { RECOVERY_CONTEXT="$1"; }

recovery_classify_error() {
  local rc="$1"
  if [ -n "$RECOVERY_HINT" ]; then
    printf '%s\n' "$RECOVERY_HINT"
    return 0
  fi
  if ! check_network; then
    printf '%s\n' "network"
    return 0
  fi
  case "$rc" in
    126) printf '%s\n' "permission" ;;
    127) printf '%s\n' "missing_command" ;;
    *)   printf '%s\n' "unknown" ;;
  esac
}

recovery_attempt() {
  local label="$1" class="$2"
  ui_warn "Recovery attempt for: $label"
  ui_secondary "Classification: $class"
  log_recovery "class=$class label=$label"
  case "$class" in
    network)
      if check_network; then
        ui_info "Network restored. Waiting ${RECOVERY_RETRY_DELAY}s before retry."
        sleep "$RECOVERY_RETRY_DELAY"
        return 0
      fi
      ui_error "Network is unavailable — retry is not possible."
      return 1
      ;;
    package)
      recovery_repair_package
      return $?
      ;;
    ubuntu_busy)
      ui_info "Ubuntu container is busy. Waiting ${RECOVERY_RETRY_DELAY}s and re-checking state."
      sleep "$RECOVERY_RETRY_DELAY"
      ui_secondary "Ubuntu state now: $(ubuntu_detect_state)"
      return 0
      ;;
    ubuntu_broken)
      if [ "$(ubuntu_detect_state)" = "HEALTHY" ]; then
        ui_success "Ubuntu is healthy again."
        return 0
      fi
      ui_error "Ubuntu remains unhealthy. No safe automatic repair is available."
      return 1
      ;;
    missing_command)
      ui_info "Refreshing package indexes to resolve missing prerequisites."
      if [ "$RECOVERY_CONTEXT" = "ubuntu" ]; then
        run_in_ubuntu 'export DEBIAN_FRONTEND=noninteractive; apt-get update -y'
      else
        command -v pkg >/dev/null 2>&1 && pkg update -y
      fi
      return $?
      ;;
    permission)
      ui_info "Re-checking environment permissions..."
      sleep "$RECOVERY_RETRY_DELAY"
      return 0
      ;;
    *)
      ui_error "No safe automatic recovery exists for classification '$class'."
      return 1
      ;;
  esac
}

recovery_repair_package() {
  ui_info "Applying safe package-manager repair (--fix-broken)."
  if [ "$RECOVERY_CONTEXT" = "ubuntu" ] && command -v run_in_ubuntu >/dev/null 2>&1; then
    run_in_ubuntu 'export DEBIAN_FRONTEND=noninteractive; apt-get -f install -y'
    return $?
  fi
  if command -v apt-get >/dev/null 2>&1; then
    apt-get -f install -y
    return $?
  fi
  ui_error "No package manager available for safe repair."
  return 1
}

run_with_recovery() {
  local label="$1"
  shift
  local attempts=0 rc class
  RECOVERY_HINT=""
  while :; do
    attempts=$((attempts + 1))
    if [ "$attempts" -gt 1 ]; then
      ui_warn "Retry $attempts of $MAX_RECOVERY_ATTEMPTS for: $label"
    fi

    "$@"
    rc=$?

    if [ "$rc" -eq 0 ]; then
      RECOVERY_LAST_LABEL="$label"
      RECOVERY_LAST_CLASS="none"
      RECOVERY_LAST_RC=0
      return 0
    fi

    RECOVERY_LAST_LABEL="$label"
    RECOVERY_LAST_RC="$rc"

    if [ "${AUTO_RECOVERY:-true}" != "true" ]; then
      RECOVERY_LAST_CLASS="disabled"
      return "$rc"
    fi

    class=$(recovery_classify_error "$rc")
    RECOVERY_LAST_CLASS="$class"

    if [ "$attempts" -ge "$MAX_RECOVERY_ATTEMPTS" ]; then
      ui_error "Stage failed after $MAX_RECOVERY_ATTEMPTS attempt(s) (exit $rc)."
      return "$rc"
    fi

    if ! recovery_attempt "$label" "$class"; then
      ui_error "Recovery aborted for: $label"
      return "$rc"
    fi
  done
}

recovery_summary() {
  printf '\n'
  ui_header "Failure Summary"
  ui_secondary "Stage:      ${RECOVERY_LAST_LABEL:-unknown}"
  ui_secondary "Class:      ${RECOVERY_LAST_CLASS:-unknown}"
  ui_secondary "Exit code:  ${RECOVERY_LAST_RC:-unknown}"
  ui_secondary "Log file:   ${LOG_FILE:-logging disabled}"
  printf '\n'
}
