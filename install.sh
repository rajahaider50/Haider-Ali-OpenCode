#!/usr/bin/env bash
#
# ============================================================================
#  HAIDER ALI — OPENCODE PROFESSIONAL INSTALLER
# ============================================================================
#
#  File    : install.sh
#  Version : 1.0.0
#  Purpose : Master controller for the Haider-Ali-OpenCode installation system
#
#  Architecture:
#
#      install.sh
#          │
#          ├── config.sh
#          │
#          ├── lib/ui.sh
#          ├── lib/system.sh
#          ├── lib/recovery.sh
#          └── lib/opencode.sh
#
#  Flow:
#
#      Preflight
#          ↓
#      Load Configuration
#          ↓
#      Initialize UI / Logging
#          ↓
#      Validate Modules
#          ↓
#      Execute Installation Pipeline
#          ↓
#      Verify Installation
#          ↓
#      Launch OpenCode
#
# ============================================================================

set -o pipefail

# ----------------------------------------------------------------------------
# Strictness
# ----------------------------------------------------------------------------
#
# We intentionally do NOT use `set -e`.
#
# Why?
# The installer contains a recovery system. A failed command must be captured
# and passed to the recovery layer instead of immediately terminating the
# entire installer.
#
# Individual modules are responsible for checking command failures.
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Global paths
# ----------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="${SCRIPT_DIR}/config.sh"
LIB_DIR="${SCRIPT_DIR}/lib"

UI_FILE="${LIB_DIR}/ui.sh"
SYSTEM_FILE="${LIB_DIR}/system.sh"
RECOVERY_FILE="${LIB_DIR}/recovery.sh"
OPENCODE_FILE="${LIB_DIR}/opencode.sh"

# ----------------------------------------------------------------------------
# Runtime information
# ----------------------------------------------------------------------------

INSTALLER_NAME="Haider Ali — OpenCode Professional Installer"
INSTALLER_VERSION="1.0.0"

START_TIME="$(date +%s)"

INSTALLER_EXIT_CODE=0
CURRENT_STAGE="Initialization"

# ----------------------------------------------------------------------------
# Basic terminal helpers
# ----------------------------------------------------------------------------

print_fatal() {
    printf '\n'
    printf '%s\n' "============================================================"
    printf '%s\n' "FATAL INSTALLER ERROR"
    printf '%s\n' "============================================================"
    printf '%s\n' "$1"
    printf '%s\n' "============================================================"
    printf '\n'
}

print_info() {
    printf '[INFO] %s\n' "$1"
}

print_error() {
    printf '[ERROR] %s\n' "$1" >&2
}

# ----------------------------------------------------------------------------
# Detect Termux
# ----------------------------------------------------------------------------
#
# This project is specifically designed for Android + Termux.
#
# We therefore refuse to continue if the script is executed in an unrelated
# Linux environment.
# ----------------------------------------------------------------------------

detect_termux() {

    CURRENT_STAGE="Termux Environment"

    if [[ -n "${TERMUX_VERSION:-}" ]]; then
        return 0
    fi

    if [[ -d "/data/data/com.termux" ]]; then
        return 0
    fi

    if [[ "${PREFIX:-}" == *"/com.termux/"* ]]; then
        return 0
    fi

    print_fatal \
        "This installer must be executed inside Termux on Android.

Please open Termux and run the installer again."

    return 1
}

# ----------------------------------------------------------------------------
# Check Bash version
# ----------------------------------------------------------------------------

check_bash_version() {

    CURRENT_STAGE="Bash Compatibility"

    local major_version="${BASH_VERSINFO[0]:-0}"

    if (( major_version < 4 )); then
        print_fatal \
            "Bash 4 or newer is required.

Detected Bash version:
${BASH_VERSION}"

        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------------
# Check required local files
# ----------------------------------------------------------------------------
#
# install.sh depends on the project's modular architecture.
#
# This function deliberately validates every module before execution.
# ----------------------------------------------------------------------------

validate_project_structure() {

    CURRENT_STAGE="Project Structure Validation"

    local required_files=(
        "$CONFIG_FILE"
        "$UI_FILE"
        "$SYSTEM_FILE"
        "$RECOVERY_FILE"
        "$OPENCODE_FILE"
    )

    local missing_files=()
    local file

    for file in "${required_files[@]}"; do

        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi

    done

    if (( ${#missing_files[@]} > 0 )); then

        print_fatal "One or more required installer modules are missing."

        printf '%s\n' "Missing files:"
        printf '  - %s\n' "${missing_files[@]}"

        printf '\n'
        printf '%s\n' \
            "The installer architecture is incomplete."

        printf '%s\n' \
            "Create the missing modules before running install.sh."

        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------------
# Validate module readability
# ----------------------------------------------------------------------------

validate_module_permissions() {

    CURRENT_STAGE="Module Permission Validation"

    local modules=(
        "$CONFIG_FILE"
        "$UI_FILE"
        "$SYSTEM_FILE"
        "$RECOVERY_FILE"
        "$OPENCODE_FILE"
    )

    local file

    for file in "${modules[@]}"; do

        if [[ ! -r "$file" ]]; then

            print_fatal \
                "Installer module is not readable:

$file"

            return 1
        fi

    done

    return 0
}

# ----------------------------------------------------------------------------
# Load configuration
# ----------------------------------------------------------------------------

load_configuration() {

    CURRENT_STAGE="Configuration Loading"

    # shellcheck source=/dev/null
    if ! source "$CONFIG_FILE"; then

        print_fatal \
            "Failed to load configuration:

$CONFIG_FILE"

        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------------
# Load UI module
# ----------------------------------------------------------------------------

load_ui_module() {

    CURRENT_STAGE="UI Module Loading"

    # shellcheck source=/dev/null
    if ! source "$UI_FILE"; then

        print_fatal \
            "Failed to load UI module:

$UI_FILE"

        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------------
# Load system module
# ----------------------------------------------------------------------------

load_system_module() {

    CURRENT_STAGE="System Module Loading"

    # shellcheck source=/dev/null
    if ! source "$SYSTEM_FILE"; then

        print_fatal \
            "Failed to load system module:

$SYSTEM_FILE"

        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------------
# Load recovery module
# ----------------------------------------------------------------------------

load_recovery_module() {

    CURRENT_STAGE="Recovery Module Loading"

    # shellcheck source=/dev/null
    if ! source "$RECOVERY_FILE"; then

        print_fatal \
            "Failed to load recovery module:

$RECOVERY_FILE"

        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------------
# Load OpenCode module
# ----------------------------------------------------------------------------

load_opencode_module() {

    CURRENT_STAGE="OpenCode Module Loading"

    # shellcheck source=/dev/null
    if ! source "$OPENCODE_FILE"; then

        print_fatal \
            "Failed to load OpenCode module:

$OPENCODE_FILE"

        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------------
# Verify required functions
# ----------------------------------------------------------------------------
#
# The modules are intentionally treated as components with an interface.
#
# This protects the master installer from silently continuing when a module
# exists but does not provide the functions required by the architecture.
# ----------------------------------------------------------------------------

require_function() {

    local function_name="$1"

    if ! declare -F "$function_name" >/dev/null 2>&1; then

        print_fatal \
            "Required installer function is missing:

${function_name}

The corresponding module may be incomplete or incompatible."

        return 1
    fi

    return 0
}

validate_module_interfaces() {

    CURRENT_STAGE="Module Interface Validation"

    # UI interface
    require_function "ui_init" || return 1
    require_function "ui_banner" || return 1
    require_function "ui_stage_start" || return 1
    require_function "ui_stage_pass" || return 1
    require_function "ui_stage_fail" || return 1
    require_function "ui_info" || return 1
    require_function "ui_error" || return 1

    # System interface
    require_function "system_preflight" || return 1
    require_function "system_install" || return 1
    require_function "system_verify" || return 1

    # Recovery interface
    require_function "recovery_init" || return 1
    require_function "recovery_execute" || return 1

    # OpenCode interface
    require_function "opencode_install" || return 1
    require_function "opencode_verify" || return 1
    require_function "opencode_launch" || return 1

    return 0
}

# ----------------------------------------------------------------------------
# Safe stage executor
# ----------------------------------------------------------------------------
#
# This is the central execution wrapper.
#
# Every major operation passes through this layer.
#
# Normal flow:
#
#     START
#       ↓
#     Execute
#       ↓
#     PASS ───────────────→ Continue
#
# Failure:
#
#     START
#       ↓
#     Execute
#       ↓
#     FAIL
#       ↓
#     Recovery
#       ↓
#     Retry
#       ↓
#     PASS / FINAL FAIL
#
# The actual recovery intelligence lives in recovery.sh.
# ----------------------------------------------------------------------------

run_stage() {

    local stage_name="$1"
    local stage_function="$2"
    shift 2

    CURRENT_STAGE="$stage_name"

    ui_stage_start "$stage_name"

    if "$stage_function" "$@"; then

        ui_stage_pass "$stage_name"

        return 0
    fi

    ui_stage_fail "$stage_name"

    ui_error "Stage failed: $stage_name"

    ui_info "Starting recovery procedure..."

    if recovery_execute "$stage_name" "$stage_function" "$@"; then

        ui_stage_pass "$stage_name"

        return 0
    fi

    ui_error "Recovery failed for: $stage_name"

    return 1
}

# ----------------------------------------------------------------------------
# Main installation pipeline
# ----------------------------------------------------------------------------

run_installation_pipeline() {

    CURRENT_STAGE="Installation Pipeline"

    # ------------------------------------------------------------
    # Stage 01 — System Preflight
    # ------------------------------------------------------------

    if ! run_stage \
        "System Preflight" \
        system_preflight; then

        return 1
    fi

    # ------------------------------------------------------------
    # Stage 02 — Main System Installation
    # ------------------------------------------------------------

    if ! run_stage \
        "Termux / Ubuntu Environment" \
        system_install; then

        return 1
    fi

    # ------------------------------------------------------------
    # Stage 03 — System Verification
    # ------------------------------------------------------------

    if ! run_stage \
        "System Verification" \
        system_verify; then

        return 1
    fi

    # ------------------------------------------------------------
    # Stage 04 — OpenCode Installation
    # ------------------------------------------------------------

    if ! run_stage \
        "OpenCode Installation" \
        opencode_install; then

        return 1
    fi

    # ------------------------------------------------------------
    # Stage 05 — OpenCode Verification
    # ------------------------------------------------------------

    if ! run_stage \
        "OpenCode Verification" \
        opencode_verify; then

        return 1
    fi

    # ------------------------------------------------------------
    # Stage 06 — OpenCode Launch
    # ------------------------------------------------------------

    if ! run_stage \
        "OpenCode Launch" \
        opencode_launch; then

        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------------
# Final success screen
# ----------------------------------------------------------------------------

installation_success() {

    local end_time
    local elapsed

    end_time="$(date +%s)"
    elapsed=$(( end_time - START_TIME ))

    printf '\n'

    if declare -F ui_success >/dev/null 2>&1; then

        ui_success \
            "HAIDER ALI OPENCODE SYSTEM READY"

        ui_info "Installation completed successfully."
        ui_info "Total installation time: ${elapsed}s"

    else

        printf '%s\n' \
            "HAIDER ALI OPENCODE SYSTEM READY"

        printf '%s\n' \
            "Installation completed successfully."

        printf '%s\n' \
            "Total installation time: ${elapsed}s"
    fi

    printf '\n'

    return 0
}

# ----------------------------------------------------------------------------
# Final failure screen
# ----------------------------------------------------------------------------

installation_failure() {

    local end_time
    local elapsed

    end_time="$(date +%s)"
    elapsed=$(( end_time - START_TIME ))

    printf '\n'

    if declare -F ui_error >/dev/null 2>&1; then

        ui_error "INSTALLATION FAILED"

        ui_info "Failed stage: ${CURRENT_STAGE}"
        ui_info "Elapsed time: ${elapsed}s"

    else

        print_error "INSTALLATION FAILED"
        print_error "Failed stage: ${CURRENT_STAGE}"
        print_error "Elapsed time: ${elapsed}s"

    fi

    printf '\n'

    return 1
}

# ----------------------------------------------------------------------------
# Cleanup handler
# ----------------------------------------------------------------------------

cleanup() {

    local exit_code="$?"

    if (( exit_code != 0 )); then
        INSTALLER_EXIT_CODE="$exit_code"
    fi
}

trap cleanup EXIT

# ----------------------------------------------------------------------------
# Interrupt handler
# ----------------------------------------------------------------------------

handle_interrupt() {

    printf '\n\n'

    if declare -F ui_error >/dev/null 2>&1; then
        ui_error "Installation interrupted by user."
    else
        print_error "Installation interrupted by user."
    fi

    CURRENT_STAGE="Interrupted"

    exit 130
}

trap handle_interrupt INT TERM

# ----------------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------------

main() {

    # ------------------------------------------------------------
    # Bootstrap checks
    # ------------------------------------------------------------

    if ! check_bash_version; then
        return 1
    fi

    if ! detect_termux; then
        return 1
    fi

    # ------------------------------------------------------------
    # Project structure
    # ------------------------------------------------------------

    if ! validate_project_structure; then
        return 1
    fi

    if ! validate_module_permissions; then
        return 1
    fi

    # ------------------------------------------------------------
    # Configuration
    # ------------------------------------------------------------

    if ! load_configuration; then
        return 1
    fi

    # ------------------------------------------------------------
    # UI
    # ------------------------------------------------------------

    if ! load_ui_module; then
        return 1
    fi

    if ! ui_init; then
        return 1
    fi

    ui_banner \
        "$INSTALLER_NAME" \
        "$INSTALLER_VERSION"

    # ------------------------------------------------------------
    # Remaining modules
    # ------------------------------------------------------------

    if ! load_system_module; then
        ui_error "System module could not be loaded."
        return 1
    fi

    if ! load_recovery_module; then
        ui_error "Recovery module could not be loaded."
        return 1
    fi

    if ! load_opencode_module; then
        ui_error "OpenCode module could not be loaded."
        return 1
    fi

    # ------------------------------------------------------------
    # Interface validation
    # ------------------------------------------------------------

    if ! validate_module_interfaces; then
        return 1
    fi

    # ------------------------------------------------------------
    # Initialize subsystems
    # ------------------------------------------------------------

    if ! recovery_init; then
        ui_error "Recovery system initialization failed."
        return 1
    fi

    # ------------------------------------------------------------
    # Execute installation
    # ------------------------------------------------------------

    if ! run_installation_pipeline; then

        installation_failure

        return 1
    fi

    # ------------------------------------------------------------
    # Success
    # ------------------------------------------------------------

    installation_success

    return 0
}

# ----------------------------------------------------------------------------
# Start
# ----------------------------------------------------------------------------

main "$@"
