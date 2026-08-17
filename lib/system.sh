#!/usr/bin/env bash
#
# ============================================================================
#  HAIDER ALI — OPENCODE PROFESSIONAL INSTALLER
# ============================================================================
#
#  File    : lib/system.sh
#  Version : 1.0.0
#  Purpose : Termux / Ubuntu system installation and verification engine
#
#  Responsibilities:
#
#      • Validate the Termux environment
#      • Update Termux packages
#      • Install proot-distro
#      • Request Android storage access
#      • Install Ubuntu
#      • Verify Ubuntu
#      • Verify / prepare mobile storage binding
#      • Update Ubuntu
#      • Install Ubuntu base dependencies
#      • Install Node.js prerequisites
#      • Provide safe command execution helpers
#      • Verify installed system components
#
#  Required by install.sh:
#
#      system_preflight
#      system_install
#      system_verify
#
# ============================================================================


# ============================================================================
# MODULE GUARD
# ============================================================================

if [[ "${HAIDER_SYSTEM_MODULE_LOADED:-false}" == "true" ]]; then
    return 0 2>/dev/null || exit 0
fi

export HAIDER_SYSTEM_MODULE_LOADED="true"


# ============================================================================
# RUNTIME STATE
# ============================================================================

SYSTEM_LAST_COMMAND=""

SYSTEM_LAST_EXIT_CODE=0

SYSTEM_LAST_OUTPUT=""

SYSTEM_UBUNTU_READY="false"

SYSTEM_STORAGE_READY="false"

SYSTEM_PROOT_READY="false"

SYSTEM_NODE_READY="false"

SYSTEM_CURL_READY="false"


# ============================================================================
# INTERNAL HELPERS
# ============================================================================

system_log() {

    if declare -F ui_log >/dev/null 2>&1; then
        ui_log "$*"
    fi

    return 0
}


system_info() {

    if declare -F ui_info >/dev/null 2>&1; then
        ui_info "$*"
    else
        printf '[INFO] %s\n' "$*"
    fi

    return 0
}


system_error() {

    if declare -F ui_error >/dev/null 2>&1; then
        ui_error "$*"
    else
        printf '[ERROR] %s\n' "$*" >&2
    fi

    return 0
}


system_warning() {

    if declare -F ui_warning >/dev/null 2>&1; then
        ui_warning "$*"
    else
        printf '[WARNING] %s\n' "$*" >&2
    fi

    return 0
}


system_command_display() {

    if declare -F ui_command >/dev/null 2>&1; then
        ui_command "$*"
    fi

    return 0
}


# ============================================================================
# COMMAND EXECUTION ENGINE
# ============================================================================
#
# Commands are executed through this function so that:
#
#      • exit codes are captured
#      • failures are not hidden
#      • the failed command is available to recovery.sh
#      • logs can record the operation
#
# We intentionally do NOT use `eval`.
#
# Arguments are treated as individual shell arguments.
# ============================================================================

system_run() {

    local description="$1"

    shift

    local command_args=( "$@" )

    SYSTEM_LAST_COMMAND="${command_args[*]}"

    SYSTEM_LAST_EXIT_CODE=0

    SYSTEM_LAST_OUTPUT=""

    system_log "COMMAND START: ${description}"

    system_log "COMMAND: ${SYSTEM_LAST_COMMAND}"

    system_command_display "${SYSTEM_LAST_COMMAND}"

    local output
    local exit_code

    output="$("${command_args[@]}" 2>&1)"

    exit_code=$?

    SYSTEM_LAST_OUTPUT="$output"

    SYSTEM_LAST_EXIT_CODE="$exit_code"

    if [[ -n "$output" ]]; then
        system_log "COMMAND OUTPUT:"
        system_log "$output"
    fi

    system_log \
        "COMMAND END: ${description} — exit=${exit_code}"

    if (( exit_code != 0 )); then

        system_error \
            "${description} failed with exit code ${exit_code}."

        if declare -F ui_error_detail >/dev/null 2>&1; then

            ui_error_detail \
                "$exit_code" \
                "$SYSTEM_LAST_COMMAND" \
                "${output:-No command output was returned.}"

        fi

        return "$exit_code"
    fi

    return 0
}


# ============================================================================
# COMMAND EXECUTION WITH LIVE OUTPUT
# ============================================================================
#
# Used for long-running package installations where hiding all output would
# make debugging unnecessarily difficult.
# ============================================================================

system_run_live() {

    local description="$1"

    shift

    local command_args=( "$@" )

    SYSTEM_LAST_COMMAND="${command_args[*]}"

    SYSTEM_LAST_EXIT_CODE=0

    system_log "LIVE COMMAND START: ${description}"

    system_log "COMMAND: ${SYSTEM_LAST_COMMAND}"

    system_command_display "${SYSTEM_LAST_COMMAND}"

    "${command_args[@]}"

    local exit_code=$?

    SYSTEM_LAST_EXIT_CODE="$exit_code"

    system_log \
        "LIVE COMMAND END: ${description} — exit=${exit_code}"

    if (( exit_code != 0 )); then

        system_error \
            "${description} failed with exit code ${exit_code}."

        return "$exit_code"
    fi

    return 0
}


# ============================================================================
# TERMUX COMMAND HELPER
# ============================================================================

system_termux() {

    local description="$1"

    shift

    system_run \
        "$description" \
        "$@"

    return $?
}


# ============================================================================
# UBUNTU COMMAND HELPER
# ============================================================================
#
# All Ubuntu commands are executed inside the installed Ubuntu environment.
#
# The Android shared storage is bound to:
#
#      /mobile_storage
#
# ============================================================================

system_ubuntu() {

    local description="$1"

    shift

    if ! command -v proot-distro >/dev/null 2>&1; then

        system_error \
            "proot-distro is not installed."

        return 127
    fi

    if ! proot-distro list 2>/dev/null |
        grep -Eq "^[[:space:]]*${HAIDER_UBUNTU_NAME:-ubuntu}[[:space:]]"; then

        # The exact output format of proot-distro list can vary, so we also
        # perform the more reliable rootfs check below.
        if [[ ! -d \
            "${PREFIX}/var/lib/proot-distro/installed-rootfs/${HAIDER_UBUNTU_NAME:-ubuntu}" ]]; then

            system_error \
                "Ubuntu environment is not installed."

            return 127
        fi
    fi

    local ubuntu_name="${HAIDER_UBUNTU_NAME:-ubuntu}"

    local bind_source="${HAIDER_UBUNTU_BIND_SOURCE:-/storage/emulated/0}"

    local bind_target="${HAIDER_UBUNTU_BIND_TARGET:-/mobile_storage}"

    local command_args=( "$@" )

    SYSTEM_LAST_COMMAND="proot-distro login ${ubuntu_name} --bind ${bind_source}:${bind_target} -- ${command_args[*]}"

    system_log "UBUNTU COMMAND START: ${description}"

    system_log "COMMAND: ${SYSTEM_LAST_COMMAND}"

    system_command_display "${SYSTEM_LAST_COMMAND}"

    local output
    local exit_code

    output="$(
        proot-distro login "$ubuntu_name" \
            --bind "${bind_source}:${bind_target}" \
            -- "${command_args[@]}" 2>&1
    )"

    exit_code=$?

    SYSTEM_LAST_OUTPUT="$output"

    SYSTEM_LAST_EXIT_CODE="$exit_code"

    if [[ -n "$output" ]]; then
        system_log "UBUNTU OUTPUT:"
        system_log "$output"
    fi

    system_log \
        "UBUNTU COMMAND END: ${description} — exit=${exit_code}"


    # Handle "container is busy" with a retry
    if (( exit_code != 0 )) &&
        printf '%s\n' "$output" |
        grep -Eiq 'container.*is busy|is already running'; then

        system_warning \
            "Ubuntu container is busy. Waiting 3 seconds before retry..."

        sleep 3

        output="$(
            proot-distro login "$ubuntu_name" \
                --bind "${bind_source}:${bind_target}" \
                -- "${command_args[@]}" 2>&1
        )"

        exit_code=$?

        SYSTEM_LAST_OUTPUT="$output"

        SYSTEM_LAST_EXIT_CODE="$exit_code"

        if (( exit_code == 0 )); then
            system_info "Retry succeeded after container was busy."
            return 0
        fi
    fi


    if (( exit_code != 0 )); then

        system_error \
            "${description} failed inside Ubuntu with exit code ${exit_code}."

        if declare -F ui_error_detail >/dev/null 2>&1; then

            ui_error_detail \
                "$exit_code" \
                "$SYSTEM_LAST_COMMAND" \
                "${output:-No command output was returned.}"

        fi

        return "$exit_code"
    fi

    return 0
}


# ============================================================================
# TERMUX ENVIRONMENT CHECK
# ============================================================================

system_check_termux() {

    system_info "Checking Termux environment..."

    if [[ -z "${PREFIX:-}" ]]; then

        system_error \
            "The PREFIX environment variable is missing."

        return 1
    fi

    if [[ ! -d "$PREFIX" ]]; then

        system_error \
            "Termux PREFIX directory does not exist: $PREFIX"

        return 1
    fi

    if ! command -v pkg >/dev/null 2>&1; then

        system_error \
            "Termux package manager 'pkg' was not found."

        return 1
    fi

    system_log "Termux environment verified."

    return 0
}


# ============================================================================
# INTERNET CONNECTIVITY CHECK
# ============================================================================

system_check_network() {

    system_info "Checking network connectivity..."

    if command -v curl >/dev/null 2>&1; then

        if curl \
            --silent \
            --show-error \
            --location \
            --connect-timeout "${HAIDER_CONNECTION_TIMEOUT:-15}" \
            --max-time "${HAIDER_NETWORK_TIMEOUT:-30}" \
            --output /dev/null \
            "https://deb.debian.org"; then

            system_log "Network connectivity verified."

            return 0
        fi
    fi

    # Fallback to a basic DNS/network test.
    if command -v getent >/dev/null 2>&1; then

        if getent hosts deb.debian.org >/dev/null 2>&1; then

            system_log "Network DNS resolution verified."

            return 0
        fi
    fi

    system_error \
        "Internet connectivity could not be verified."

    return 1
}


# ============================================================================
# PROOT-DISTRO CHECK
# ============================================================================

system_check_proot() {

    system_info "Checking proot-distro..."

    if command -v proot-distro >/dev/null 2>&1; then

        SYSTEM_PROOT_READY="true"

        system_log "proot-distro is available."

        return 0
    fi

    system_warning \
        "proot-distro is not installed yet."

    return 1
}


# ============================================================================
# STORAGE ACCESS
# ============================================================================

system_check_storage() {

    system_info "Checking Android shared storage..."

    local storage_path="${HAIDER_TERMUX_STORAGE:-/storage/emulated/0}"

    if [[ ! -d "$storage_path" ]]; then

        system_error \
            "Android shared storage directory was not found:

${storage_path}"

        return 1
    fi

    if [[ ! -r "$storage_path" ]]; then

        system_error \
            "Android shared storage is not readable."

        return 1
    fi

    SYSTEM_STORAGE_READY="true"

    system_log \
        "Android shared storage verified: ${storage_path}"

    return 0
}


# ============================================================================
# REQUEST STORAGE PERMISSION
# ============================================================================
#
# Android/Termux may require the user to approve storage access.
#
# This operation cannot honestly be described as fully automatic because
# Android may display a permission prompt that requires user interaction.
# ============================================================================

system_request_storage_access() {

    system_info "Requesting Termux storage access..."

    if command -v termux-setup-storage >/dev/null 2>&1; then

        system_run_live \
            "Android storage permission setup" \
            termux-setup-storage

        local result=$?

        if (( result != 0 )); then
            return "$result"
        fi

    else

        system_error \
            "termux-setup-storage command is unavailable."

        return 1
    fi

    # Give Android/Termux a moment to create the storage links.
    sleep 1

    system_check_storage

    return $?
}


# ============================================================================
# UPDATE TERMUX
# ============================================================================

system_update_termux() {

    system_info "Updating Termux package metadata..."

    system_termux \
        "Termux package update" \
        pkg update -y

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    system_info "Upgrading installed Termux packages..."

    system_termux \
        "Termux package upgrade" \
        pkg upgrade -y

    return $?
}


# ============================================================================
# INSTALL PROOT-DISTRO
# ============================================================================

system_install_proot() {

    if command -v proot-distro >/dev/null 2>&1; then

        SYSTEM_PROOT_READY="true"

        system_info \
            "proot-distro is already installed. Skipping installation."

        return 0
    fi

    system_info "Installing proot-distro..."

    system_termux \
        "proot-distro installation" \
        pkg install proot-distro -y

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    if ! command -v proot-distro >/dev/null 2>&1; then

        system_error \
            "proot-distro installation reported success but the command is unavailable."

        return 1
    fi

    SYSTEM_PROOT_READY="true"

    return 0
}


# ============================================================================
# CHECK UBUNTU INSTALLATION
# ============================================================================

system_is_ubuntu_installed() {

    local ubuntu_name="${HAIDER_UBUNTU_NAME:-ubuntu}"

    local rootfs_path="${PREFIX}/var/lib/proot-distro/installed-rootfs/${ubuntu_name}"

    [[ -d "$rootfs_path" ]]
}


# ============================================================================
# INSTALL UBUNTU
# ============================================================================

system_install_ubuntu() {

    if system_is_ubuntu_installed; then

        SYSTEM_UBUNTU_READY="true"

        system_info \
            "Ubuntu is already installed. Reusing existing installation."

        return 0
    fi

    system_info "Installing Ubuntu through proot-distro..."

    system_run_live \
        "Ubuntu installation" \
        proot-distro install "${HAIDER_UBUNTU_NAME:-ubuntu}"

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    if ! system_is_ubuntu_installed; then

        system_error \
            "Ubuntu installation completed but its root filesystem was not detected."

        return 1
    fi

    SYSTEM_UBUNTU_READY="true"

    return 0
}


# ============================================================================
# VERIFY UBUNTU
# ============================================================================

system_verify_ubuntu() {

    system_info "Verifying Ubuntu environment..."

    if ! system_is_ubuntu_installed; then

        system_error \
            "Ubuntu root filesystem was not found."

        return 1
    fi

    if ! system_ubuntu \
        "Ubuntu identity check" \
        /usr/bin/env \
        bash \
        -c \
        'test -f /etc/os-release && . /etc/os-release && printf "%s\n" "$ID"'; then

        return 1
    fi

    SYSTEM_UBUNTU_READY="true"

    system_log "Ubuntu environment verified."

    return 0
}


# ============================================================================
# UPDATE UBUNTU
# ============================================================================

system_update_ubuntu() {

    system_info "Updating Ubuntu package metadata..."

    system_ubuntu \
        "Ubuntu package update" \
        apt-get \
        update

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    system_info "Upgrading Ubuntu packages..."

    system_ubuntu \
        "Ubuntu package upgrade" \
        env \
        DEBIAN_FRONTEND=noninteractive \
        apt-get \
        upgrade \
        -y

    return $?
}


# ============================================================================
# INSTALL UBUNTU BASE DEPENDENCIES
# ============================================================================

system_install_ubuntu_dependencies() {

    system_info "Installing Ubuntu base dependencies..."

    local packages=(
        "curl"
        "ca-certificates"
        "gnupg"
        "build-essential"
    )

    system_ubuntu \
        "Ubuntu base dependency installation" \
        env \
        DEBIAN_FRONTEND=noninteractive \
        apt-get \
        install \
        -y \
        "${packages[@]}"

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    return 0
}


# ============================================================================
# VERIFY CURL
# ============================================================================

system_verify_curl() {

    system_info "Verifying curl inside Ubuntu..."

    if ! system_ubuntu \
        "curl verification" \
        curl \
        --version; then

        SYSTEM_CURL_READY="false"

        return 1
    fi

    SYSTEM_CURL_READY="true"

    return 0
}


# ============================================================================
# VERIFY APT
# ============================================================================

system_verify_apt() {

    system_info "Verifying Ubuntu package manager..."

    system_ubuntu \
        "APT verification" \
        apt-get \
        --version

    return $?
}


# ============================================================================
# PREPARE NODE.JS INSTALLATION
# ============================================================================
#
# Node.js itself is installed by the OpenCode/system integration stage later.
# Here we only prepare and verify the Ubuntu environment needed by Node.js.
# ============================================================================

system_prepare_node() {

    system_info \
        "Preparing Ubuntu environment for Node.js ${HAIDER_NODE_VERSION:-20.x}..."

    if ! system_verify_curl; then
        return 1
    fi

    system_ubuntu \
        "Node.js repository prerequisites" \
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
# STORAGE BIND VERIFICATION
# ============================================================================

system_verify_storage_bind() {

    system_info \
        "Verifying Android storage binding inside Ubuntu..."

    local bind_source="${HAIDER_UBUNTU_BIND_SOURCE:-/storage/emulated/0}"

    local bind_target="${HAIDER_UBUNTU_BIND_TARGET:-/mobile_storage}"

    if [[ ! -d "$bind_source" ]]; then

        system_error \
            "Bind source does not exist: ${bind_source}"

        return 1
    fi

    if ! system_ubuntu \
        "Mobile storage bind verification" \
        bash \
        -c \
        "test -d '${bind_target}'"; then

        system_error \
            "Mobile storage is not accessible inside Ubuntu at ${bind_target}."

        return 1
    fi

    system_log \
        "Storage bind verified: ${bind_source} → ${bind_target}"

    return 0
}


# ============================================================================
# PRE-FLIGHT
# ============================================================================
#
# This function is intentionally conservative.
#
# It checks the environment before making major changes.
# ============================================================================

system_preflight() {

    if [[ "${HAIDER_CONFIG_LOADED:-false}" != "true" ]]; then

        system_error \
            "Configuration has not been loaded."

        return 1
    fi

    if declare -F config_validate >/dev/null 2>&1; then

        if ! config_validate; then

            system_error \
                "Configuration validation failed."

            return 1
        fi
    fi

    # ------------------------------------------------------------
    # Termux
    # ------------------------------------------------------------

    if ! system_check_termux; then
        return 1
    fi

    # ------------------------------------------------------------
    # Network
    # ------------------------------------------------------------

    if ! system_check_network; then

        system_warning \
            "Network connectivity check failed."

        return 1
    fi

    # ------------------------------------------------------------
    # Storage
    # ------------------------------------------------------------

    #
    # Storage may not yet be configured. We don't fail here solely because
    # the Android storage permission has not been granted; system_install()
    # will request it.
    #

    if ! system_check_storage; then

        system_warning \
            "Android storage access is not ready yet."

    fi

    # ------------------------------------------------------------
    # proot-distro
    # ------------------------------------------------------------

    if ! system_check_proot; then

        system_info \
            "proot-distro will be installed during the installation stage."

    fi

    system_log "System preflight completed."

    return 0
}


# ============================================================================
# MAIN SYSTEM INSTALLATION
# ============================================================================
#
# Complete order:
#
#   1. Termux update
#   2. Termux upgrade
#   3. Storage permission
#   4. proot-distro
#   5. Ubuntu
#   6. Ubuntu verification
#   7. Ubuntu update
#   8. Ubuntu dependencies
#   9. Node.js prerequisites
#   10. Storage bind verification
#
# Node.js installation and OpenCode installation are handled by their
# appropriate higher-level module so responsibilities remain clean.
# ============================================================================

system_install() {

    # ------------------------------------------------------------
    # 1. Termux package update
    # ------------------------------------------------------------

    if ! system_update_termux; then
        return 1
    fi

    # ------------------------------------------------------------
    # 2. Android storage permission
    # ------------------------------------------------------------

    if ! system_check_storage; then

        if ! system_request_storage_access; then

            system_error \
                "Android storage access could not be established."

            return 1
        fi
    else

        system_info \
            "Android storage access is already available."

        SYSTEM_STORAGE_READY="true"
    fi

    # ------------------------------------------------------------
    # 3. proot-distro
    # ------------------------------------------------------------

    if ! system_install_proot; then
        return 1
    fi

    # ------------------------------------------------------------
    # 4. Ubuntu
    # ------------------------------------------------------------

    if ! system_install_ubuntu; then
        return 1
    fi

    # ------------------------------------------------------------
    # 5. Ubuntu verification
    # ------------------------------------------------------------

    if ! system_verify_ubuntu; then
        return 1
    fi

    # ------------------------------------------------------------
    # 6. Ubuntu update
    # ------------------------------------------------------------

    if ! system_update_ubuntu; then
        return 1
    fi

    # ------------------------------------------------------------
    # 7. Ubuntu dependencies
    # ------------------------------------------------------------

    if ! system_install_ubuntu_dependencies; then
        return 1
    fi

    # ------------------------------------------------------------
    # 8. curl verification
    # ------------------------------------------------------------

    if ! system_verify_curl; then
        return 1
    fi

    # ------------------------------------------------------------
    # 9. Node.js preparation
    # ------------------------------------------------------------

    if ! system_prepare_node; then
        return 1
    fi

    # ------------------------------------------------------------
    # 10. Storage bind verification
    # ------------------------------------------------------------

    if ! system_verify_storage_bind; then
        return 1
    fi

    system_log "Main system installation completed."

    return 0
}


# ============================================================================
# SYSTEM VERIFICATION
# ============================================================================
#
# This function performs a second-pass verification after installation.
#
# It does NOT install anything.
#
# Verification should be read-only wherever possible.
# ============================================================================

system_verify() {

    system_info "Running complete system verification..."

    # ------------------------------------------------------------
    # Termux
    # ------------------------------------------------------------

    if ! system_check_termux; then
        return 1
    fi

    # ------------------------------------------------------------
    # Storage
    # ------------------------------------------------------------

    if ! system_check_storage; then
        return 1
    fi

    # ------------------------------------------------------------
    # proot-distro
    # ------------------------------------------------------------

    if ! command -v proot-distro >/dev/null 2>&1; then

        system_error \
            "proot-distro verification failed."

        return 1
    fi

    SYSTEM_PROOT_READY="true"

    # ------------------------------------------------------------
    # Ubuntu
    # ------------------------------------------------------------

    if ! system_verify_ubuntu; then
        return 1
    fi

    # ------------------------------------------------------------
    # APT
    # ------------------------------------------------------------

    if ! system_verify_apt; then
        return 1
    fi

    # ------------------------------------------------------------
    # curl
    # ------------------------------------------------------------

    if ! system_verify_curl; then
        return 1
    fi

    # ------------------------------------------------------------
    # Storage bind
    # ------------------------------------------------------------

    if ! system_verify_storage_bind; then
        return 1
    fi

    system_log "Complete system verification passed."

    return 0
}


# ============================================================================
# SYSTEM DIAGNOSTICS
# ============================================================================
#
# Used by recovery.sh when diagnosing a failed system stage.
# ============================================================================

system_diagnostics() {

    printf '\n'

    printf '%s\n' \
        "============================================================"

    printf '%s\n' \
        "HAIDER ALI SYSTEM DIAGNOSTICS"

    printf '%s\n' \
        "============================================================"

    printf '%-28s %s\n' \
        "Termux PREFIX:" \
        "${PREFIX:-not-set}"

    printf '%-28s %s\n' \
        "Termux HOME:" \
        "${HOME:-not-set}"

    printf '%-28s %s\n' \
        "proot-distro:" \
        "$(command -v proot-distro 2>/dev/null || printf 'not-installed')"

    printf '%-28s %s\n' \
        "Ubuntu installed:" \
        "$(system_is_ubuntu_installed && printf 'yes' || printf 'no')"

    printf '%-28s %s\n' \
        "Storage:" \
        "$(system_check_storage >/dev/null 2>&1 && printf 'available' || printf 'unavailable')"

    printf '%-28s %s\n' \
        "Last exit code:" \
        "${SYSTEM_LAST_EXIT_CODE}"

    printf '%-28s %s\n' \
        "Last command:" \
        "${SYSTEM_LAST_COMMAND:-none}"

    printf '%s\n' \
        "============================================================"

    system_log "System diagnostics generated."

    return 0
}


# ============================================================================
# SYSTEM STATE
# ============================================================================

system_state() {

    printf '%s\n' \
        "System State"

    printf '  Termux:          %s\n' \
        "ready"

    printf '  Storage:         %s\n' \
        "${SYSTEM_STORAGE_READY}"

    printf '  proot-distro:    %s\n' \
        "${SYSTEM_PROOT_READY}"

    printf '  Ubuntu:          %s\n' \
        "${SYSTEM_UBUNTU_READY}"

    printf '  curl:            %s\n' \
        "${SYSTEM_CURL_READY}"

    printf '  Node.js:         %s\n' \
        "${SYSTEM_NODE_READY}"

    return 0
}


# ============================================================================
# MODULE READY
# ============================================================================

system_log "Haider Ali system module loaded."

return 0 2>/dev/null || true
