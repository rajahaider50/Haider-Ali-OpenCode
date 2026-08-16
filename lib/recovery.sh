#!/usr/bin/env bash
#
# ============================================================================
#  HAIDER ALI — OPENCODE PROFESSIONAL INSTALLER
# ============================================================================
#
#  File    : lib/recovery.sh
#  Version : 1.0.0
#  Purpose : Controlled error detection, recovery, retry and verification
#
#  Responsibilities:
#
#      • Capture failed installation stages
#      • Classify common failures
#      • Diagnose known problems
#      • Execute safe, whitelisted recovery actions
#      • Retry failed operations
#      • Prevent infinite recovery loops
#      • Provide detailed recovery reporting
#      • Preserve the original failure information
#
#  Required modules:
#
#      config.sh
#      lib/ui.sh
#      lib/system.sh
#
#  Public functions:
#
#      recovery_run
#      recovery_retry
#      recovery_diagnose
#      recovery_reset
#
# ============================================================================


# ============================================================================
# MODULE GUARD
# ============================================================================

if [[ "${HAIDER_RECOVERY_MODULE_LOADED:-false}" == "true" ]]; then
    return 0 2>/dev/null || exit 0
fi

export HAIDER_RECOVERY_MODULE_LOADED="true"


# ============================================================================
# RUNTIME STATE
# ============================================================================

RECOVERY_LAST_STAGE=""

RECOVERY_LAST_ERROR_CODE=0

RECOVERY_LAST_ERROR_MESSAGE=""

RECOVERY_LAST_COMMAND=""

RECOVERY_LAST_OUTPUT=""

RECOVERY_ATTEMPTS=0

RECOVERY_SUCCESS_COUNT=0

RECOVERY_FAILURE_COUNT=0

RECOVERY_ACTION=""

RECOVERY_CLASSIFICATION="unknown"

RECOVERY_IN_PROGRESS="false"


# ============================================================================
# CONFIGURATION FALLBACKS
# ============================================================================

RECOVERY_MAX_ATTEMPTS="${HAIDER_MAX_RECOVERY_ATTEMPTS:-3}"

RECOVERY_RETRY_DELAY="${HAIDER_RECOVERY_RETRY_DELAY:-2}"

RECOVERY_ENABLE_AUTO="${HAIDER_AUTO_RECOVERY:-true}"


# ============================================================================
# LOGGING HELPERS
# ============================================================================

recovery_log() {

    if declare -F ui_log >/dev/null 2>&1; then
        ui_log "$*"
    fi

    return 0
}


recovery_info() {

    if declare -F ui_info >/dev/null 2>&1; then
        ui_info "$*"
    else
        printf '[INFO] %s\n' "$*"
    fi

    return 0
}


recovery_warning() {

    if declare -F ui_warning >/dev/null 2>&1; then
        ui_warning "$*"
    else
        printf '[WARNING] %s\n' "$*" >&2
    fi

    return 0
}


recovery_error() {

    if declare -F ui_error >/dev/null 2>&1; then
        ui_error "$*"
    else
        printf '[ERROR] %s\n' "$*" >&2
    fi

    return 0
}


recovery_message() {

    if declare -F ui_recovery >/dev/null 2>&1; then
        ui_recovery "$*"
    else
        printf '[RECOVERY] %s\n' "$*"
    fi

    return 0
}


# ============================================================================
# RESET RECOVERY STATE
# ============================================================================

recovery_reset() {

    RECOVERY_LAST_STAGE=""

    RECOVERY_LAST_ERROR_CODE=0

    RECOVERY_LAST_ERROR_MESSAGE=""

    RECOVERY_LAST_COMMAND=""

    RECOVERY_LAST_OUTPUT=""

    RECOVERY_ATTEMPTS=0

    RECOVERY_ACTION=""

    RECOVERY_CLASSIFICATION="unknown"

    RECOVERY_IN_PROGRESS="false"

    return 0
}


# ============================================================================
# CAPTURE FAILURE
# ============================================================================

recovery_capture_failure() {

    local stage="$1"

    local error_code="${2:-${SYSTEM_LAST_EXIT_CODE:-1}}"

    local message="${3:-${SYSTEM_LAST_OUTPUT:-Unknown error}}"

    RECOVERY_LAST_STAGE="$stage"

    RECOVERY_LAST_ERROR_CODE="$error_code"

    RECOVERY_LAST_ERROR_MESSAGE="$message"

    RECOVERY_LAST_COMMAND="${SYSTEM_LAST_COMMAND:-unknown}"

    RECOVERY_LAST_OUTPUT="${SYSTEM_LAST_OUTPUT:-}"

    recovery_log \
        "FAILURE CAPTURED: stage=${stage} code=${error_code}"

    recovery_log \
        "FAILED COMMAND: ${RECOVERY_LAST_COMMAND}"

    return 0
}


# ============================================================================
# ERROR CLASSIFICATION
# ============================================================================
#
# The classifier deliberately uses known patterns instead of guessing.
#
# Possible classifications:
#
#      network
#      package-lock
#      package-manager
#      storage
#      ubuntu
#      proot
#      permission
#      command-missing
#      repository
#      node
#      unknown
#
# ============================================================================

recovery_classify() {

    local output="${RECOVERY_LAST_OUTPUT}"

    local command="${RECOVERY_LAST_COMMAND}"

    local combined

    combined="${command}
${output}"

    RECOVERY_CLASSIFICATION="unknown"

    # ------------------------------------------------------------
    # Network errors
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'could not resolve|temporary failure resolving|network is unreachable|connection timed out|connection refused|failed to connect|unable to connect|network unreachable|could not connect'; then

        RECOVERY_CLASSIFICATION="network"

        return 0
    fi

    # ------------------------------------------------------------
    # Repository / package index errors
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'failed to fetch|unable to fetch|repository|release file|404.*not found|hash sum mismatch|failed to download'; then

        RECOVERY_CLASSIFICATION="repository"

        return 0
    fi

    # ------------------------------------------------------------
    # Package manager / dpkg lock
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'could not get lock|unable to acquire the dpkg frontend lock|dpkg was interrupted|dpkg.*error|package manager'; then

        RECOVERY_CLASSIFICATION="package-manager"

        return 0
    fi

    # ------------------------------------------------------------
    # Permission errors
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'permission denied|operation not permitted|access denied'; then

        RECOVERY_CLASSIFICATION="permission"

        return 0
    fi

    # ------------------------------------------------------------
    # Storage errors
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'storage.*not found|no such file.*storage|/storage/emulated/0|mobile_storage'; then

        RECOVERY_CLASSIFICATION="storage"

        return 0
    fi

    # ------------------------------------------------------------
    # proot errors
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'proot|proot-distro|rootfs|cannot.*mount'; then

        RECOVERY_CLASSIFICATION="proot"

        return 0
    fi

    # ------------------------------------------------------------
    # Ubuntu errors
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'ubuntu.*not installed|ubuntu.*rootfs|distribution.*not found'; then

        RECOVERY_CLASSIFICATION="ubuntu"

        return 0
    fi

    # ------------------------------------------------------------
    # Missing commands
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'command not found|no such file or directory'; then

        RECOVERY_CLASSIFICATION="command-missing"

        return 0
    fi

    # ------------------------------------------------------------
    # Node.js
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'nodejs|node\.js|npm'; then

        RECOVERY_CLASSIFICATION="node"

        return 0
    fi

    return 0
}


# ============================================================================
# DIAGNOSTICS
# ============================================================================

recovery_diagnose() {

    local stage="${1:-$RECOVERY_LAST_STAGE}"

    recovery_message \
        "Diagnosing failure in stage: ${stage}"

    recovery_classify

    recovery_log \
        "ERROR CLASSIFICATION: ${RECOVERY_CLASSIFICATION}"

    case "$RECOVERY_CLASSIFICATION" in

        network)

            recovery_message \
                "Network connectivity problem detected."

            recovery_message \
                "Checking network before retry..."

            if declare -F system_check_network >/dev/null 2>&1; then

                if system_check_network; then

                    recovery_message \
                        "Network check passed."

                    return 0

                fi

            fi

            return 1
            ;;

        repository)

            recovery_message \
                "Package repository or metadata problem detected."

            return 0
            ;;

        package-manager)

            recovery_message \
                "Package manager state problem detected."

            return 0
            ;;

        permission)

            recovery_message \
                "Permission problem detected."

            return 0
            ;;

        storage)

            recovery_message \
                "Android storage access problem detected."

            return 0
            ;;

        proot)

            recovery_message \
                "proot-distro environment problem detected."

            return 0
            ;;

        ubuntu)

            recovery_message \
                "Ubuntu environment problem detected."

            return 0
            ;;

        command-missing)

            recovery_message \
                "A required command appears to be unavailable."

            return 0
            ;;

        node)

            recovery_message \
                "Node.js/npm related problem detected."

            return 0
            ;;

        *)

            recovery_message \
                "No known error signature matched."

            return 1
            ;;

    esac
}


# ============================================================================
# SAFE RECOVERY ACTIONS
# ============================================================================
#
# IMPORTANT:
#
# Recovery actions are intentionally explicit and limited.
#
# There is no generic:
#
#      rm -rf
#      chmod -R
#      killall
#      reinstall-everything
#
# mechanism here.
#
# ============================================================================


# ============================================================================
# NETWORK RECOVERY
# ============================================================================

recovery_network() {

    recovery_message \
        "Running network recovery..."

    sleep "$RECOVERY_RETRY_DELAY"

    if declare -F system_check_network >/dev/null 2>&1; then

        if system_check_network; then

            recovery_message \
                "Network recovery check passed."

            return 0
        fi
    fi

    recovery_warning \
        "Network is still unavailable."

    return 1
}


# ============================================================================
# TERMUX PACKAGE RECOVERY
# ============================================================================

recovery_termux_packages() {

    recovery_message \
        "Refreshing Termux package state..."

    if ! command -v pkg >/dev/null 2>&1; then

        recovery_error \
            "Termux package manager is unavailable."

        return 1
    fi

    pkg update -y

    local result=$?

    if (( result != 0 )); then

        recovery_error \
            "Termux package metadata refresh failed."

        return "$result"
    fi

    return 0
}


# ============================================================================
# UBUNTU PACKAGE RECOVERY
# ============================================================================

recovery_ubuntu_packages() {

    recovery_message \
        "Repairing Ubuntu package state..."

    if ! declare -F system_ubuntu >/dev/null 2>&1; then

        recovery_error \
            "Ubuntu command interface is unavailable."

        return 1
    fi

    # First refresh package metadata.
    if ! system_ubuntu \
        "Ubuntu package metadata recovery" \
        apt-get \
        update; then

        return 1
    fi

    # Then finish interrupted dpkg configuration.
    if ! system_ubuntu \
        "Ubuntu package configuration recovery" \
        env \
        DEBIAN_FRONTEND=noninteractive \
        dpkg \
        --configure \
        -a; then

        return 1
    fi

    return 0
}


# ============================================================================
# PROOT RECOVERY
# ============================================================================

recovery_proot() {

    recovery_message \
        "Checking proot-distro installation..."

    if command -v proot-distro >/dev/null 2>&1; then

        recovery_message \
            "proot-distro command is available."

        return 0
    fi

    recovery_message \
        "Installing missing proot-distro package..."

    if ! pkg install proot-distro -y; then

        recovery_error \
            "Unable to install proot-distro."

        return 1
    fi

    command -v proot-distro >/dev/null 2>&1
}


# ============================================================================
# STORAGE RECOVERY
# ============================================================================

recovery_storage() {

    recovery_message \
        "Refreshing Android storage access..."

    if ! command -v termux-setup-storage >/dev/null 2>&1; then

        recovery_error \
            "termux-setup-storage is unavailable."

        return 1
    fi

    termux-setup-storage

    sleep 1

    if declare -F system_check_storage >/dev/null 2>&1; then

        if system_check_storage; then

            recovery_message \
                "Android storage access is available."

            return 0
        fi
    fi

    recovery_warning \
        "Android storage access still requires attention."

    return 1
}


# ============================================================================
# UBUNTU RECOVERY
# ============================================================================

recovery_ubuntu() {

    recovery_message \
        "Checking Ubuntu installation..."

    if ! command -v proot-distro >/dev/null 2>&1; then

        recovery_error \
            "proot-distro is unavailable."

        return 1
    fi

    if declare -F system_is_ubuntu_installed >/dev/null 2>&1; then

        if system_is_ubuntu_installed; then

            recovery_message \
                "Ubuntu installation exists."

            return 0
        fi
    fi

    recovery_message \
        "Ubuntu installation is missing."

    recovery_message \
        "Attempting controlled Ubuntu installation..."

    proot-distro install "${HAIDER_UBUNTU_NAME:-ubuntu}"

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    if declare -F system_is_ubuntu_installed >/dev/null 2>&1; then

        system_is_ubuntu_installed

        return $?
    fi

    return 1
}


# ============================================================================
# COMMAND-MISSING RECOVERY
# ============================================================================

recovery_missing_command() {

    recovery_message \
        "Checking required base commands..."

    if ! command -v pkg >/dev/null 2>&1; then

        recovery_error \
            "Termux package manager is missing."

        return 1
    fi

    if ! command -v proot-distro >/dev/null 2>&1; then

        recovery_proot

        return $?
    fi

    return 0
}


# ============================================================================
# NODE.JS RECOVERY
# ============================================================================
#
# Node.js itself belongs to opencode.sh.
#
# Therefore this recovery layer only restores the package prerequisites
# required for the Node.js installation process.
# ============================================================================

recovery_node() {

    recovery_message \
        "Repairing Node.js installation prerequisites..."

    if ! declare -F system_ubuntu >/dev/null 2>&1; then
        return 1
    fi

    system_ubuntu \
        "Node.js prerequisite recovery" \
        env \
        DEBIAN_FRONTEND=noninteractive \
        apt-get \
        install \
        -y \
        ca-certificates \
        curl \
        gnupg

    return $?
}


# ============================================================================
# SELECT RECOVERY ACTION
# ============================================================================

recovery_select_action() {

    RECOVERY_ACTION=""

    case "$RECOVERY_CLASSIFICATION" in

        network)
            RECOVERY_ACTION="network"
            ;;

        repository|package-manager)
            RECOVERY_ACTION="ubuntu_packages"
            ;;

        storage|permission)
            RECOVERY_ACTION="storage"
            ;;

        proot)
            RECOVERY_ACTION="proot"
            ;;

        ubuntu)
            RECOVERY_ACTION="ubuntu"
            ;;

        command-missing)
            RECOVERY_ACTION="missing_command"
            ;;

        node)
            RECOVERY_ACTION="node"
            ;;

        unknown)
            RECOVERY_ACTION=""
            ;;

    esac

    [[ -n "$RECOVERY_ACTION" ]]
}


# ============================================================================
# EXECUTE SELECTED RECOVERY ACTION
# ============================================================================

recovery_execute_action() {

    local action="$1"

    recovery_message \
        "Executing recovery action: ${action}"

    recovery_log \
        "RECOVERY ACTION START: ${action}"

    case "$action" in

        network)

            recovery_network
            ;;

        ubuntu_packages)

            recovery_ubuntu_packages
            ;;

        storage)

            recovery_storage
            ;;

        proot)

            recovery_proot
            ;;

        ubuntu)

            recovery_ubuntu
            ;;

        missing_command)

            recovery_missing_command
            ;;

        node)

            recovery_node
            ;;

        *)

            recovery_error \
                "Unknown recovery action: ${action}"

            return 1
            ;;

    esac

    local result=$?

    recovery_log \
        "RECOVERY ACTION END: ${action} — exit=${result}"

    return "$result"
}


# ============================================================================
# RETRY FAILED STAGE
# ============================================================================
#
# Arguments:
#
#      recovery_retry <stage-name> <command/function>
#
# Example:
#
#      recovery_retry "System Installation" system_install
#
# ============================================================================

recovery_retry() {

    local stage="$1"

    shift

    local retry_command=( "$@" )

    if (( ${#retry_command[@]} == 0 )); then

        recovery_error \
            "No retry command was supplied."

        return 2
    fi

    recovery_capture_failure \
        "$stage" \
        "${SYSTEM_LAST_EXIT_CODE:-1}" \
        "${SYSTEM_LAST_OUTPUT:-}"

    recovery_classify

    recovery_log \
        "RETRY REQUESTED FOR: ${stage}"

    recovery_log \
        "CLASSIFICATION: ${RECOVERY_CLASSIFICATION}"

    # ------------------------------------------------------------
    # Automatic recovery disabled
    # ------------------------------------------------------------

    if [[ "$RECOVERY_ENABLE_AUTO" != "true" ]]; then

        recovery_warning \
            "Automatic recovery is disabled."

        return 1
    fi

    # ------------------------------------------------------------
    # Prevent nested recovery loops
    # ------------------------------------------------------------

    if [[ "$RECOVERY_IN_PROGRESS" == "true" ]]; then

        recovery_error \
            "Nested recovery attempt detected. Aborting recovery loop."

        return 1
    fi

    RECOVERY_IN_PROGRESS="true"

    local attempt

    for (( attempt=1; attempt<=RECOVERY_MAX_ATTEMPTS; attempt++ )); do

        RECOVERY_ATTEMPTS="$attempt"

        if declare -F ui_retry >/dev/null 2>&1; then

            ui_retry \
                "$attempt" \
                "$RECOVERY_MAX_ATTEMPTS" \
                "Recovery attempt for ${stage}"

        fi

        # --------------------------------------------------------
        # Diagnose current failure
        # --------------------------------------------------------

        recovery_diagnose "$stage" || true

        # --------------------------------------------------------
        # Select known recovery action
        # --------------------------------------------------------

        if ! recovery_select_action; then

            recovery_warning \
                "No safe automatic repair is available for this failure."

            recovery_log \
                "NO AUTOMATIC RECOVERY AVAILABLE."

            RECOVERY_IN_PROGRESS="false"

            ((RECOVERY_FAILURE_COUNT++))

            return 1
        fi

        # --------------------------------------------------------
        # Execute repair
        # --------------------------------------------------------

        if ! recovery_execute_action "$RECOVERY_ACTION"; then

            recovery_warning \
                "Recovery action failed."

            if (( attempt < RECOVERY_MAX_ATTEMPTS )); then

                recovery_message \
                    "Waiting before next recovery attempt..."

                sleep "$RECOVERY_RETRY_DELAY"

                continue
            fi

            break
        fi

        # --------------------------------------------------------
        # Retry original operation
        # --------------------------------------------------------

        recovery_message \
            "Retrying failed stage: ${stage}"

        "${retry_command[@]}"

        local retry_result=$?

        if (( retry_result == 0 )); then

            recovery_message \
                "Retry succeeded."

            ((RECOVERY_SUCCESS_COUNT++))

            RECOVERY_IN_PROGRESS="false"

            return 0
        fi

        # --------------------------------------------------------
        # Capture new failure for next diagnosis
        # --------------------------------------------------------

        RECOVERY_LAST_ERROR_CODE="$retry_result"

        RECOVERY_LAST_COMMAND="${SYSTEM_LAST_COMMAND:-${retry_command[*]}}"

        RECOVERY_LAST_OUTPUT="${SYSTEM_LAST_OUTPUT:-}"

        recovery_classify

        recovery_warning \
            "Retry failed with exit code ${retry_result}."

        if (( attempt < RECOVERY_MAX_ATTEMPTS )); then

            recovery_message \
                "Preparing another controlled recovery attempt..."

            sleep "$RECOVERY_RETRY_DELAY"
        fi

    done

    RECOVERY_IN_PROGRESS="false"

    ((RECOVERY_FAILURE_COUNT++))

    recovery_error \
        "Automatic recovery exhausted after ${RECOVERY_MAX_ATTEMPTS} attempts."

    return 1
}


# ============================================================================
# HIGH-LEVEL RECOVERY RUNNER
# ============================================================================
#
# This is the main interface install.sh can use.
#
# First:
#
#      command/function runs
#
# If successful:
#
#      PASS
#
# If failed:
#
#      capture
#      classify
#      diagnose
#      repair
#      retry
#
# ============================================================================

recovery_run() {

    local stage="$1"

    shift

    local command=( "$@" )

    if (( ${#command[@]} == 0 )); then

        recovery_error \
            "recovery_run requires a stage and command."

        return 2
    fi

    recovery_reset

    recovery_message \
        "Starting protected execution: ${stage}"

    "${command[@]}"

    local result=$?

    # ------------------------------------------------------------
    # Original command passed
    # ------------------------------------------------------------

    if (( result == 0 )); then

        recovery_message \
            "${stage} completed successfully."

        return 0
    fi

    # ------------------------------------------------------------
    # Capture failure
    # ------------------------------------------------------------

    recovery_capture_failure \
        "$stage" \
        "$result" \
        "${SYSTEM_LAST_OUTPUT:-}"

    recovery_error \
        "${stage} failed."

    # ------------------------------------------------------------
    # Attempt controlled recovery
    # ------------------------------------------------------------

    if recovery_retry "$stage" "${command[@]}"; then

        recovery_message \
            "${stage} recovered successfully."

        return 0
    fi

    recovery_error \
        "${stage} could not be recovered automatically."

    return "$result"
}


# ============================================================================
# MANUAL DIAGNOSTICS
# ============================================================================

recovery_report() {

    printf '\n'

    printf '%s\n' \
        "============================================================"

    printf '%s\n' \
        "HAIDER ALI — RECOVERY REPORT"

    printf '%s\n' \
        "============================================================"

    printf '%-28s %s\n' \
        "Stage:" \
        "${RECOVERY_LAST_STAGE:-unknown}"

    printf '%-28s %s\n' \
        "Error code:" \
        "${RECOVERY_LAST_ERROR_CODE:-unknown}"

    printf '%-28s %s\n' \
        "Classification:" \
        "${RECOVERY_CLASSIFICATION:-unknown}"

    printf '%-28s %s\n' \
        "Recovery action:" \
        "${RECOVERY_ACTION:-none}"

    printf '%-28s %s\n' \
        "Attempts:" \
        "${RECOVERY_ATTEMPTS:-0}"

    printf '%-28s %s\n' \
        "Recovered:" \
        "${RECOVERY_SUCCESS_COUNT:-0}"

    printf '%-28s %s\n' \
        "Unrecovered:" \
        "${RECOVERY_FAILURE_COUNT:-0}"

    printf '%s\n' \
        "============================================================"

    if [[ -n "${RECOVERY_LAST_COMMAND:-}" ]]; then

        printf '\n'

        printf 'Last command:\n'

        printf '  %s\n' \
            "$RECOVERY_LAST_COMMAND"

    fi

    return 0
}


# ============================================================================
# FINAL RECOVERY SUMMARY
# ============================================================================

recovery_summary() {

    if (( RECOVERY_SUCCESS_COUNT > 0 )); then

        recovery_message \
            "Recovery operations succeeded: ${RECOVERY_SUCCESS_COUNT}"

    fi

    if (( RECOVERY_FAILURE_COUNT > 0 )); then

        recovery_warning \
            "Recovery operations failed: ${RECOVERY_FAILURE_COUNT}"

    fi

    recovery_log \
        "RECOVERY SUMMARY: success=${RECOVERY_SUCCESS_COUNT} failure=${RECOVERY_FAILURE_COUNT}"

    return 0
}


# ============================================================================
# MODULE READY
# ============================================================================

recovery_log "Haider Ali recovery module loaded."

return 0 2>/dev/null || true
