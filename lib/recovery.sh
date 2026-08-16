#!/usr/bin/env bash

# ============================================================================
# HAIDER ALI — OPENCODE PROFESSIONAL RECOVERY ENGINE
# ============================================================================
#
# File    : lib/recovery.sh
# Version : 1.1.0
# Purpose : Controlled error detection, diagnosis, recovery and retry engine
#
# Public Interface:
#
#   recovery_init
#   recovery_execute
#   recovery_run
#   recovery_retry
#   recovery_diagnose
#   recovery_reset
#   recovery_report
#   recovery_summary
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

RECOVERY_INITIALIZED="false"

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
# CONFIGURATION
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
# RECOVERY INITIALIZATION
# ============================================================================
#
# This function is required by install.sh.
#
# It prepares the recovery subsystem before the installation pipeline starts.
# ============================================================================

recovery_init() {

    recovery_info \
        "Initializing Haider Ali Recovery Engine..."

    # ------------------------------------------------------------
    # Validate retry configuration
    # ------------------------------------------------------------

    if ! [[ "$RECOVERY_MAX_ATTEMPTS" =~ ^[0-9]+$ ]]; then

        recovery_warning \
            "Invalid recovery attempt limit. Falling back to 3."

        RECOVERY_MAX_ATTEMPTS=3
    fi

    if (( RECOVERY_MAX_ATTEMPTS < 1 )); then

        recovery_warning \
            "Recovery attempt limit must be at least 1."

        RECOVERY_MAX_ATTEMPTS=1
    fi


    # ------------------------------------------------------------
    # Validate retry delay
    # ------------------------------------------------------------

    if ! [[ "$RECOVERY_RETRY_DELAY" =~ ^[0-9]+$ ]]; then

        recovery_warning \
            "Invalid recovery retry delay. Falling back to 2 seconds."

        RECOVERY_RETRY_DELAY=2
    fi


    # ------------------------------------------------------------
    # Validate automatic recovery setting
    # ------------------------------------------------------------

    case "${RECOVERY_ENABLE_AUTO,,}" in

        true|false)
            ;;

        yes)
            RECOVERY_ENABLE_AUTO="true"
            ;;

        no)
            RECOVERY_ENABLE_AUTO="false"
            ;;

        *)
            recovery_warning \
                "Invalid automatic recovery setting. Using true."

            RECOVERY_ENABLE_AUTO="true"
            ;;
    esac


    # ------------------------------------------------------------
    # Reset runtime state
    # ------------------------------------------------------------

    recovery_reset


    # ------------------------------------------------------------
    # Mark initialized
    # ------------------------------------------------------------

    RECOVERY_INITIALIZED="true"


    recovery_message \
        "Recovery engine initialized successfully."

    recovery_info \
        "Automatic recovery: ${RECOVERY_ENABLE_AUTO}"

    recovery_info \
        "Maximum attempts: ${RECOVERY_MAX_ATTEMPTS}"

    recovery_info \
        "Retry delay: ${RECOVERY_RETRY_DELAY}s"

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

    RECOVERY_LAST_OUTPUT="${SYSTEM_LAST_OUTPUT:-$message}"


    recovery_log \
        "FAILURE CAPTURED: stage=${stage} code=${error_code}"

    recovery_log \
        "FAILED COMMAND: ${RECOVERY_LAST_COMMAND}"

    return 0
}


# ============================================================================
# ERROR CLASSIFICATION
# ============================================================================

recovery_classify() {

    local output="${RECOVERY_LAST_OUTPUT}"

    local command="${RECOVERY_LAST_COMMAND}"

    local combined

    combined="${command}
${output}"


    RECOVERY_CLASSIFICATION="unknown"


    # ------------------------------------------------------------
    # Network
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'could not resolve|temporary failure resolving|network is unreachable|connection timed out|connection refused|failed to connect|unable to connect|network unreachable|could not connect'; then

        RECOVERY_CLASSIFICATION="network"

        return 0
    fi


    # ------------------------------------------------------------
    # Repository
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'failed to fetch|unable to fetch|release file|404.*not found|hash sum mismatch|failed to download|repository'; then

        RECOVERY_CLASSIFICATION="repository"

        return 0
    fi


    # ------------------------------------------------------------
    # Package manager
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'could not get lock|unable to acquire.*lock|dpkg was interrupted|dpkg.*error|package manager'; then

        RECOVERY_CLASSIFICATION="package-manager"

        return 0
    fi


    # ------------------------------------------------------------
    # Permission
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'permission denied|operation not permitted|access denied'; then

        RECOVERY_CLASSIFICATION="permission"

        return 0
    fi


    # ------------------------------------------------------------
    # Storage
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'storage.*not found|no such file.*storage|/storage/emulated/0|mobile_storage'; then

        RECOVERY_CLASSIFICATION="storage"

        return 0
    fi


    # ------------------------------------------------------------
    # proot
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'proot|proot-distro|rootfs|cannot.*mount'; then

        RECOVERY_CLASSIFICATION="proot"

        return 0
    fi


    # ------------------------------------------------------------
    # Ubuntu
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'ubuntu.*not installed|ubuntu.*rootfs|distribution.*not found'; then

        RECOVERY_CLASSIFICATION="ubuntu"

        return 0
    fi


    # ------------------------------------------------------------
    # Missing command
    # ------------------------------------------------------------

    if printf '%s\n' "$combined" |
        grep -Eiq \
        'command not found|no such file or directory'; then

        RECOVERY_CLASSIFICATION="command-missing"

        return 0
    fi


    # ------------------------------------------------------------
    # Node.js / npm
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
# DIAGNOSIS
# ============================================================================

recovery_diagnose() {

    local stage="${1:-$RECOVERY_LAST_STAGE}"


    recovery_message \
        "Diagnosing failure: ${stage}"


    recovery_classify


    recovery_info \
        "Classification: ${RECOVERY_CLASSIFICATION}"


    case "$RECOVERY_CLASSIFICATION" in

        network)

            recovery_message \
                "Network connectivity problem detected."

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
# NETWORK RECOVERY
# ============================================================================

recovery_network() {

    recovery_message \
        "Running network recovery check..."

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


    if ! system_ubuntu \
        "Ubuntu package metadata recovery" \
        apt-get \
        update; then

        return 1
    fi


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
        "Checking proot-distro..."


    if command -v proot-distro >/dev/null 2>&1; then

        recovery_message \
            "proot-distro is available."

        return 0
    fi


    recovery_message \
        "Installing missing proot-distro..."


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
        "Checking Android storage access..."


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


    proot-distro install \
        "${HAIDER_UBUNTU_NAME:-ubuntu}"


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
# MISSING COMMAND RECOVERY
# ============================================================================

recovery_missing_command() {

    recovery_message \
        "Checking required base commands..."


    if ! command -v pkg >/dev/null 2>&1; then

        recovery_error \
            "Termux package manager is unavailable."

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
# EXECUTE RECOVERY ACTION
# ============================================================================

recovery_execute_action() {

    local action="$1"


    recovery_message \
        "Executing recovery action: ${action}"


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
}


# ============================================================================
# RETRY FAILED STAGE
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
        "${SYSTEM_LAST_OUTPUT:-${RECOVERY_LAST_ERROR_MESSAGE:-Unknown error}}"


    recovery_classify


    if [[ "$RECOVERY_ENABLE_AUTO" != "true" ]]; then

        recovery_warning \
            "Automatic recovery is disabled."

        return 1
    fi


    if [[ "$RECOVERY_IN_PROGRESS" == "true" ]]; then

        recovery_error \
            "Nested recovery attempt detected."

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

        else

            recovery_message \
                "Recovery attempt ${attempt}/${RECOVERY_MAX_ATTEMPTS}"

        fi


        recovery_diagnose "$stage" || true


        if ! recovery_select_action; then

            recovery_warning \
                "No safe automatic repair is available."

            RECOVERY_IN_PROGRESS="false"

            ((RECOVERY_FAILURE_COUNT++))

            return 1
        fi


        if ! recovery_execute_action "$RECOVERY_ACTION"; then

            recovery_warning \
                "Recovery action failed."

            if (( attempt < RECOVERY_MAX_ATTEMPTS )); then

                sleep "$RECOVERY_RETRY_DELAY"

                continue
            fi

            break
        fi


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


        RECOVERY_LAST_ERROR_CODE="$retry_result"

        RECOVERY_LAST_COMMAND="${SYSTEM_LAST_COMMAND:-${retry_command[*]}}"

        RECOVERY_LAST_OUTPUT="${SYSTEM_LAST_OUTPUT:-}"


        recovery_classify


        recovery_warning \
            "Retry failed with exit code ${retry_result}."


        if (( attempt < RECOVERY_MAX_ATTEMPTS )); then

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


    if (( result == 0 )); then

        recovery_message \
            "${stage} completed successfully."

        return 0
    fi


    recovery_capture_failure \
        "$stage" \
        "$result" \
        "${SYSTEM_LAST_OUTPUT:-Unknown error}"


    recovery_error \
        "${stage} failed."


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
# INSTALLER COMPATIBILITY INTERFACE
# ============================================================================
#
# install.sh calls:
#
#     recovery_execute <stage> <function> [arguments...]
#
# This function is the official bridge between install.sh and the recovery
# engine.
# ============================================================================

recovery_execute() {

    local stage="$1"

    shift


    if [[ -z "$stage" ]]; then

        recovery_error \
            "Recovery stage name is required."

        return 2
    fi


    if (( $# == 0 )); then

        recovery_error \
            "Recovery execution requires a command or function."

        return 2
    fi


    if [[ "$RECOVERY_INITIALIZED" != "true" ]]; then

        recovery_warning \
            "Recovery engine was not initialized. Initializing now..."

        recovery_init || return 1
    fi


    recovery_run \
        "$stage" \
        "$@"

    return $?
}


# ============================================================================
# RECOVERY REPORT
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
# RECOVERY SUMMARY
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

recovery_log \
    "Haider Ali recovery module loaded."


return 0 2>/dev/null || true
