#!/usr/bin/env bash
#
# install.sh — Haider Ali OpenCode System (professional orchestrator).
#
# Termux → Ubuntu → Node.js → OpenCode AI
#
# This script is an orchestrator only. All implementation lives in the
# configuration, libraries and command modules below.
#
# Failure handling is explicit: global `set -e` / `set -u` are intentionally
# not enabled. Every critical command's exit status is captured, classified
# and routed through the recovery engine.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=config.sh
. "$PROJECT_ROOT/config.sh"

# shellcheck disable=SC1091 # libs are sourced through a dynamic name
for lib in logger ui runner checker recovery system ubuntu opencode; do
  # shellcheck source=lib/$lib.sh
  . "$PROJECT_ROOT/lib/$lib.sh"
done

# shellcheck disable=SC2034 # read by commands/*.sh guards
HAIDER_OPENCODE_LOADED=1

# shellcheck disable=SC1091 # command modules are sourced dynamically
for cmd in "$PROJECT_ROOT"/commands/*.sh; do
  # shellcheck source=commands/$cmd
  . "$cmd"
done

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --help       Show this help and exit
  --version    Show version information and exit
  --no-color   Disable ANSI colours
  --no-log     Disable file logging
  --check      Verify the environment and exit without installing
EOF
}

env_status() {
  local fn="$1"
  if "$fn" >/dev/null 2>&1; then
    printf 'OK'
  else
    printf 'MISSING'
  fi
}

check_environment_report() {
  local s
  printf '%s\n' "----------------------------------------"
  printf '%-22s %s\n' "COMPONENT" "STATUS"
  printf '%s\n' "----------------------------------------"
  s=$(env_status check_termux);       printf '%-22s %s\n' "Termux"          "$s"
  s=$(env_status check_android);      printf '%-22s %s\n' "Android"         "$s"
  s=$(env_status check_network);      printf '%-22s %s\n' "Network"         "$s"
  s=$(env_status check_storage);      printf '%-22s %s\n' "Shared storage"  "$s"
  s=$(env_status check_pkg);          printf '%-22s %s\n' "pkg"             "$s"
  s=$(env_status check_proot_distro); printf '%-22s %s\n' "proot-distro"    "$s"
  printf '%-22s %s\n' "Ubuntu" "$(ubuntu_detect_state)"
  s=$(env_status check_curl);         printf '%-22s %s\n' "curl"            "$s"
  s=$(env_status check_node);         printf '%-22s %s\n' "Node.js"         "$s"
  s=$(env_status check_npm);          printf '%-22s %s\n' "npm"             "$s"
  s=$(env_status check_opencode);     printf '%-22s %s\n' "OpenCode"        "$s"
  printf '%-22s %s\n' "Architecture" "$(check_architecture)"
}

run_stage_or_abort() {
  local number="$1" name="$2" fn="$3"
  local rc
  run_step "$number" "$STAGE_TOTAL" "$name" "$fn"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    recovery_summary
    ui_abort_screen "$rc"
    return "$rc"
  fi
  return 0
}

main() {
  local arg rc
  for arg in "$@"; do
    case "$arg" in
      --help)
        usage
        return 0
        ;;
      --version)
        printf '%s\n' "$APP_NAME — version $APP_VERSION"
        return 0
        ;;
      --no-color)
        # shellcheck disable=SC2034 # read by ui_init at runtime
        ENABLE_COLORS="false"
        ;;
      --no-log)
        # shellcheck disable=SC2034 # read by log_init at runtime
        ENABLE_LOGGING="false"
        ;;
      --check)
        DO_CHECK_ONLY="true"
        ;;
      *)
        printf '%s\n' "Unknown option: $arg" >&2
        usage >&2
        return 2
        ;;
    esac
  done

  ui_init
  if ! log_init; then
    printf '%s\n' "ERROR: could not initialize logging directory: $LOG_DIRECTORY" >&2
    return 1
  fi
  recovery_init

  ui_banner
  ui_secondary "Owner:   $APP_OWNER"
  ui_secondary "Version: $APP_VERSION"
  ui_secondary "Log file: $LOG_FILE"
  printf '\n'

  log_info "=== $APP_NAME v$APP_VERSION — run started ==="
  log_info "Bash: $BASH_VERSION | Arch: $(check_architecture)"

  ui_header "Environment Verification"
  if ! check_termux; then
    ui_error "This installer must be executed inside Termux on Android."
    ui_secondary "The current environment does not look like Termux."
    ui_abort_screen 1
    log_result "ABORT: environment is not Termux"
    return 1
  fi
  ui_success "Termux environment detected."

  if check_network; then
    ui_success "Network connectivity confirmed."
  else
    ui_warn "Network check failed now — it will be re-verified before each network stage."
  fi

  if check_android; then
    ui_success "Android platform confirmed."
  else
    ui_warn "Android markers not detected; continuing with Termux assumptions."
  fi

  ui_secondary "Architecture: $(check_architecture)"

  if [ "$DO_CHECK_ONLY" = "true" ]; then
    printf '\n'
    ui_header "Environment Report"
    check_environment_report
    printf '\n'
    return 0
  fi

  printf '\n'
  ui_header "Installation Stages"

  run_stage_or_abort 1  "${STAGE_NAMES[0]}"  stage_01_termux_update   || return $?
  run_stage_or_abort 2  "${STAGE_NAMES[1]}"  stage_02_proot_distro    || return $?
  run_stage_or_abort 3  "${STAGE_NAMES[2]}"  stage_03_storage         || return $?
  run_stage_or_abort 4  "${STAGE_NAMES[3]}"  stage_04_ubuntu          || return $?
  run_stage_or_abort 5  "${STAGE_NAMES[4]}"  stage_05_ubuntu_login    || return $?
  run_stage_or_abort 6  "${STAGE_NAMES[5]}"  stage_06_ubuntu_update   || return $?
  run_stage_or_abort 7  "${STAGE_NAMES[6]}"  stage_07_curl            || return $?
  run_stage_or_abort 8  "${STAGE_NAMES[7]}"  stage_08_node_repository || return $?
  run_stage_or_abort 9  "${STAGE_NAMES[8]}"  stage_09_nodejs          || return $?
  run_stage_or_abort 10 "${STAGE_NAMES[9]}"  stage_10_opencode        || return $?

  if run_step_plain 11 "${STAGE_NAMES[10]}" stage_11_launch; then
    rc=0
  else
    rc=$?
    ui_abort_screen "$rc"
  fi

  printf '\n'
  ui_success "Thank you for using $APP_NAME."
  ui_secondary "Log file: $LOG_FILE"
  log_result "INSTALLATION COMPLETE"
  return "$rc"
}

DO_CHECK_ONLY="false"
main "$@"
exit $?
