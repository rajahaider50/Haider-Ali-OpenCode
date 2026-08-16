#!/usr/bin/env bash
#
# ============================================================================
#  HAIDER ALI — OPENCODE PROFESSIONAL INSTALLER
# ============================================================================
#
#  File    : lib/opencode.sh
#  Version : 1.0.0
#  Purpose : Node.js + OpenCode installation and verification engine
#
#  Responsibilities:
#
#      • Install Node.js 20.x inside Ubuntu
#      • Verify Node.js
#      • Verify npm
#      • Install OpenCode CLI
#      • Verify OpenCode CLI
#      • Create a stable OpenCode launcher
#      • Configure OpenCode working directory
#      • Provide version diagnostics
#      • Provide clean launch functionality
#
#  Required modules:
#
#      config.sh
#      lib/ui.sh
#      lib/system.sh
#
#  Public functions:
#
#      opencode_install
#      opencode_verify
#      opencode_launch
#      opencode_diagnostics
#
# ============================================================================


# ============================================================================
# MODULE GUARD
# ============================================================================

if [[ "${HAIDER_OPENCODE_MODULE_LOADED:-false}" == "true" ]]; then
    return 0 2>/dev/null || exit 0
fi

export HAIDER_OPENCODE_MODULE_LOADED="true"


# ============================================================================
# RUNTIME STATE
# ============================================================================

OPENCODE_NODE_READY="false"

OPENCODE_NPM_READY="false"

OPENCODE_PACKAGE_READY="false"

OPENCODE_COMMAND_READY="false"

OPENCODE_VERSION=""

OPENCODE_NODE_VERSION=""

OPENCODE_NPM_VERSION=""

OPENCODE_INSTALL_PATH=""

OPENCODE_LAUNCHER_PATH=""


# ============================================================================
# CONFIGURATION FALLBACKS
# ============================================================================

OPENCODE_NODE_MAJOR="${HAIDER_NODE_MAJOR_VERSION:-20}"

OPENCODE_NODE_SETUP_URL="${HAIDER_NODE_SETUP_URL:-https://deb.nodesource.com/setup_20.x}"

OPENCODE_PACKAGE="${HAIDER_OPENCODE_PACKAGE:-opencode-ai}"

OPENCODE_WORKDIR="${HAIDER_OPENCODE_WORKDIR:-/mobile_storage/OpenCode}"

OPENCODE_LAUNCHER="${HAIDER_OPENCODE_LAUNCHER:-opencode-haider}"

OPENCODE_AUTO_UPDATE="${HAIDER_OPENCODE_AUTO_UPDATE:-false}"


# ============================================================================
# LOGGING / UI HELPERS
# ============================================================================

opencode_log() {

    if declare -F ui_log >/dev/null 2>&1; then
        ui_log "$*"
    fi

    return 0
}


opencode_info() {

    if declare -F ui_info >/dev/null 2>&1; then
        ui_info "$*"
    else
        printf '[INFO] %s\n' "$*"
    fi

    return 0
}


opencode_success() {

    if declare -F ui_success >/dev/null 2>&1; then
        ui_success "$*"
    else
        printf '[PASS] %s\n' "$*"
    fi

    return 0
}


opencode_warning() {

    if declare -F ui_warning >/dev/null 2>&1; then
        ui_warning "$*"
    else
        printf '[WARNING] %s\n' "$*" >&2
    fi

    return 0
}


opencode_error() {

    if declare -F ui_error >/dev/null 2>&1; then
        ui_error "$*"
    else
        printf '[ERROR] %s\n' "$*" >&2
    fi

    return 0
}


# ============================================================================
# UBUNTU COMMAND EXECUTION
# ============================================================================
#
# All Node.js/OpenCode commands run inside Ubuntu.
# ============================================================================

opencode_ubuntu() {

    local description="$1"

    shift

    if ! declare -F system_ubuntu >/dev/null 2>&1; then

        opencode_error \
            "system_ubuntu() is unavailable."

        return 127
    fi

    system_ubuntu \
        "$description" \
        "$@"

    return $?
}


# ============================================================================
# CHECK UBUNTU
# ============================================================================

opencode_check_ubuntu() {

    if ! declare -F system_is_ubuntu_installed >/dev/null 2>&1; then

        opencode_error \
            "System module is not loaded correctly."

        return 1
    fi

    if ! system_is_ubuntu_installed; then

        opencode_error \
            "Ubuntu is not installed."

        return 1
    fi

    return 0
}


# ============================================================================
# CHECK CURL
# ============================================================================

opencode_check_curl() {

    opencode_info \
        "Checking curl inside Ubuntu..."

    opencode_ubuntu \
        "curl availability check" \
        bash \
        -c \
        'command -v curl >/dev/null 2>&1'

    return $?
}


# ============================================================================
# NODE.JS VERSION
# ============================================================================

opencode_get_node_version() {

    local version

    version="$(
        opencode_ubuntu \
            "Node.js version detection" \
            node \
            --version
    )"

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    OPENCODE_NODE_VERSION="$(printf '%s' "$version" | tail -n 1)"

    printf '%s\n' "$OPENCODE_NODE_VERSION"

    return 0
}


# ============================================================================
# NODE.JS MAJOR VERSION
# ============================================================================

opencode_get_node_major() {

    local version="${OPENCODE_NODE_VERSION:-}"

    version="${version#v}"

    if [[ "$version" != *.* ]]; then
        return 1
    fi

    printf '%s\n' "${version%%.*}"

    return 0
}


# ============================================================================
# VERIFY NODE.JS
# ============================================================================

opencode_verify_node() {

    opencode_info \
        "Verifying Node.js ${OPENCODE_NODE_MAJOR}.x..."

    if ! opencode_ubuntu \
        "Node.js availability check" \
        bash \
        -c \
        'command -v node >/dev/null 2>&1'; then

        OPENCODE_NODE_READY="false"

        return 1
    fi

    local version

    version="$(
        opencode_ubuntu \
            "Node.js version check" \
            node \
            --version
    )"

    local result=$?

    if (( result != 0 )); then

        OPENCODE_NODE_READY="false"

        return "$result"
    fi

    version="$(printf '%s' "$version" | tail -n 1)"

    OPENCODE_NODE_VERSION="$version"

    local major

    major="${version#v}"

    major="${major%%.*}"

    if [[ "$major" != "$OPENCODE_NODE_MAJOR" ]]; then

        opencode_warning \
            "Detected Node.js ${version}; expected major version ${OPENCODE_NODE_MAJOR}."

        OPENCODE_NODE_READY="false"

        return 1
    fi

    OPENCODE_NODE_READY="true"

    opencode_success \
        "Node.js ${version} is ready."

    return 0
}


# ============================================================================
# VERIFY NPM
# ============================================================================

opencode_verify_npm() {

    opencode_info \
        "Verifying npm..."

    if ! opencode_ubuntu \
        "npm availability check" \
        bash \
        -c \
        'command -v npm >/dev/null 2>&1'; then

        OPENCODE_NPM_READY="false"

        return 1
    fi

    local version

    version="$(
        opencode_ubuntu \
            "npm version check" \
            npm \
            --version
    )"

    local result=$?

    if (( result != 0 )); then

        OPENCODE_NPM_READY="false"

        return "$result"
    fi

    OPENCODE_NPM_VERSION="$(printf '%s' "$version" | tail -n 1)"

    OPENCODE_NPM_READY="true"

    opencode_success \
        "npm ${OPENCODE_NPM_VERSION} is ready."

    return 0
}


# ============================================================================
# INSTALL NODE.JS
# ============================================================================
#
# NodeSource setup is used for the requested Node.js 20.x line.
#
# The script is executed only after curl has been verified.
# ============================================================================

opencode_install_node() {

    if opencode_verify_node; then

        opencode_info \
            "Compatible Node.js installation already exists."

        return 0
    fi

    if ! opencode_check_curl; then

        opencode_error \
            "curl is required before Node.js installation."

        return 1
    fi

    opencode_info \
        "Installing Node.js ${OPENCODE_NODE_MAJOR}.x..."

    # ------------------------------------------------------------
    # Download NodeSource setup script
    # ------------------------------------------------------------

    opencode_ubuntu \
        "NodeSource setup" \
        bash \
        -c \
        "curl -fsSL '${OPENCODE_NODE_SETUP_URL}' | bash -"

    local result=$?

    if (( result != 0 )); then

        opencode_error \
            "NodeSource repository setup failed."

        return "$result"
    fi

    # ------------------------------------------------------------
    # Install Node.js
    # ------------------------------------------------------------

    opencode_ubuntu \
        "Node.js installation" \
        env \
        DEBIAN_FRONTEND=noninteractive \
        apt-get \
        install \
        -y \
        nodejs

    result=$?

    if (( result != 0 )); then

        opencode_error \
            "Node.js package installation failed."

        return "$result"
    fi

    # ------------------------------------------------------------
    # Verify
    # ------------------------------------------------------------

    if ! opencode_verify_node; then

        opencode_error \
            "Node.js was installed but verification failed."

        return 1
    fi

    if ! opencode_verify_npm; then

        opencode_error \
            "npm verification failed."

        return 1
    fi

    return 0
}


# ============================================================================
# NPM GLOBAL PREFIX
# ============================================================================
#
# A user-owned npm prefix avoids requiring npm global installs to modify
# system directories directly.
#
# This is especially useful in a proot Ubuntu environment.
# ============================================================================

opencode_configure_npm_prefix() {

    opencode_info \
        "Configuring user-level npm global installation path..."

    local prefix_path="${HAIDER_NPM_PREFIX:-/root/.local}"

    opencode_ubuntu \
        "Create npm user prefix" \
        bash \
        -c \
        "mkdir -p '${prefix_path}'"

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    opencode_ubuntu \
        "Configure npm global prefix" \
        npm \
        config \
        set \
        prefix \
        "$prefix_path"

    result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    OPENCODE_INSTALL_PATH="${prefix_path}/lib/node_modules/${OPENCODE_PACKAGE}"

    return 0
}


# ============================================================================
# INSTALL OPENCODE PACKAGE
# ============================================================================

opencode_install_package() {

    opencode_info \
        "Checking OpenCode package: ${OPENCODE_PACKAGE}"

    if opencode_verify_package; then

        opencode_info \
            "OpenCode package is already installed."

        return 0
    fi

    opencode_info \
        "Installing ${OPENCODE_PACKAGE} globally through npm..."

    opencode_ubuntu \
        "OpenCode npm package installation" \
        npm \
        install \
        --global \
        "$OPENCODE_PACKAGE"

    local result=$?

    if (( result != 0 )); then

        opencode_error \
            "OpenCode npm package installation failed."

        return "$result"
    fi

    if ! opencode_verify_package; then

        opencode_error \
            "OpenCode package installation completed but verification failed."

        return 1
    fi

    return 0
}


# ============================================================================
# VERIFY OPEN CODE PACKAGE
# ============================================================================

opencode_verify_package() {

    opencode_info \
        "Verifying ${OPENCODE_PACKAGE} package..."

    opencode_ubuntu \
        "OpenCode npm package verification" \
        npm \
        list \
        --global \
        --depth=0 \
        "$OPENCODE_PACKAGE"

    local result=$?

    if (( result != 0 )); then

        OPENCODE_PACKAGE_READY="false"

        return 1
    fi

    OPENCODE_PACKAGE_READY="true"

    return 0
}


# ============================================================================
# FIND OPENCODE COMMAND
# ============================================================================

opencode_find_command() {

    local command_path

    command_path="$(
        opencode_ubuntu \
            "OpenCode command detection" \
            bash \
            -c \
            'command -v opencode'
    )"

    local result=$?

    if (( result != 0 )); then

        OPENCODE_COMMAND_READY="false"

        return "$result"
    fi

    command_path="$(printf '%s' "$command_path" | tail -n 1)"

    if [[ -z "$command_path" ]]; then

        OPENCODE_COMMAND_READY="false"

        return 1
    fi

    OPENCODE_COMMAND_READY="true"

    printf '%s\n' "$command_path"

    return 0
}


# ============================================================================
# VERIFY OPEN CODE COMMAND
# ============================================================================

opencode_verify_command() {

    opencode_info \
        "Verifying OpenCode executable..."

    local command_path

    command_path="$(opencode_find_command)"

    local result=$?

    if (( result != 0 )); then

        OPENCODE_COMMAND_READY="false"

        opencode_error \
            "OpenCode command was not found."

        return "$result"
    fi

    opencode_success \
        "OpenCode executable found: ${command_path}"

    return 0
}


# ============================================================================
# GET OPEN CODE VERSION
# ============================================================================

opencode_get_version() {

    local version

    version="$(
        opencode_ubuntu \
            "OpenCode version detection" \
            opencode \
            --version
    )"

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    OPENCODE_VERSION="$(printf '%s' "$version" | tail -n 1)"

    printf '%s\n' "$OPENCODE_VERSION"

    return 0
}


# ============================================================================
# VERIFY OPEN CODE
# ============================================================================

opencode_verify() {

    opencode_info \
        "Running complete OpenCode verification..."

    # ------------------------------------------------------------
    # Ubuntu
    # ------------------------------------------------------------

    if ! opencode_check_ubuntu; then
        return 1
    fi

    # ------------------------------------------------------------
    # Node.js
    # ------------------------------------------------------------

    if ! opencode_verify_node; then
        return 1
    fi

    # ------------------------------------------------------------
    # npm
    # ------------------------------------------------------------

    if ! opencode_verify_npm; then
        return 1
    fi

    # ------------------------------------------------------------
    # OpenCode package
    # ------------------------------------------------------------

    if ! opencode_verify_package; then
        return 1
    fi

    # ------------------------------------------------------------
    # OpenCode command
    # ------------------------------------------------------------

    if ! opencode_verify_command; then
        return 1
    fi

    # ------------------------------------------------------------
    # Version
    # ------------------------------------------------------------

    local version

    version="$(opencode_get_version)"

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    OPENCODE_VERSION="$version"

    opencode_success \
        "OpenCode ${OPENCODE_VERSION} is ready."

    return 0
}


# ============================================================================
# CREATE OPENCODE WORKING DIRECTORY
# ============================================================================

opencode_create_workdir() {

    opencode_info \
        "Preparing OpenCode workspace..."

    local workdir="$OPENCODE_WORKDIR"

    if [[ -z "$workdir" ]]; then

        opencode_error \
            "OpenCode workspace path is empty."

        return 1
    fi

    # Only create the configured workspace.
    # No recursive deletion or destructive operation is performed.
    opencode_ubuntu \
        "OpenCode workspace creation" \
        mkdir \
        -p \
        "$workdir"

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    opencode_success \
        "Workspace ready: ${workdir}"

    return 0
}


# ============================================================================
# CREATE LAUNCHER
# ============================================================================
#
# Creates a small wrapper inside Ubuntu.
#
# The wrapper:
#
#      • switches to the configured workspace
#      • launches OpenCode
#
# It does not bypass permissions or modify unrelated system files.
# ============================================================================

opencode_create_launcher() {

    opencode_info \
        "Creating professional OpenCode launcher..."

    local launcher_directory="${HAIDER_LAUNCHER_DIRECTORY:-/usr/local/bin}"

    local launcher_name="$OPENCODE_LAUNCHER"

    local launcher_path="${launcher_directory}/${launcher_name}"

    local workdir="$OPENCODE_WORKDIR"

    opencode_ubuntu \
        "Launcher directory preparation" \
        mkdir \
        -p \
        "$launcher_directory"

    local result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    local launcher_content

    launcher_content="$(cat <<EOF
#!/usr/bin/env bash

set -e

OPENCODE_WORKDIR="${workdir}"

if [[ ! -d "\$OPENCODE_WORKDIR" ]]; then
    mkdir -p "\$OPENCODE_WORKDIR"
fi

cd "\$OPENCODE_WORKDIR"

exec opencode "\$@"
EOF
)"

    opencode_ubuntu \
        "OpenCode launcher creation" \
        bash \
        -c \
        "printf '%s\n' '${launcher_content//$'\n'/\\n}' > '${launcher_path}'"

    result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    opencode_ubuntu \
        "OpenCode launcher permissions" \
        chmod \
        755 \
        "$launcher_path"

    result=$?

    if (( result != 0 )); then
        return "$result"
    fi

    OPENCODE_LAUNCHER_PATH="$launcher_path"

    opencode_success \
        "Launcher created: ${launcher_path}"

    return 0
}


# ============================================================================
# VERIFY LAUNCHER
# ============================================================================

opencode_verify_launcher() {

    if [[ -z "$OPENCODE_LAUNCHER_PATH" ]]; then

        OPENCODE_LAUNCHER_PATH="${HAIDER_LAUNCHER_DIRECTORY:-/usr/local/bin}/${OPENCODE_LAUNCHER}"
    fi

    opencode_info \
        "Verifying OpenCode launcher..."

    opencode_ubuntu \
        "Launcher verification" \
        test \
        -x \
        "$OPENCODE_LAUNCHER_PATH"

    local result=$?

    if (( result != 0 )); then

        opencode_error \
            "OpenCode launcher verification failed."

        return "$result"
    fi

    opencode_success \
        "OpenCode launcher is executable."

    return 0
}


# ============================================================================
# COMPLETE INSTALLATION
# ============================================================================
#
# Order:
#
#      1. Ubuntu check
#      2. curl check
#      3. Node.js
#      4. npm
#      5. npm prefix
#      6. OpenCode package
#      7. OpenCode executable
#      8. Workspace
#      9. Launcher
#      10. Final verification
#
# ============================================================================

opencode_install() {

    # ------------------------------------------------------------
    # Ubuntu
    # ------------------------------------------------------------

    if ! opencode_check_ubuntu; then
        return 1
    fi

    # ------------------------------------------------------------
    # curl
    # ------------------------------------------------------------

    if ! opencode_check_curl; then

        opencode_error \
            "curl is required for Node.js installation."

        return 1
    fi

    # ------------------------------------------------------------
    # Node.js
    # ------------------------------------------------------------

    if ! opencode_install_node; then
        return 1
    fi

    # ------------------------------------------------------------
    # npm
    # ------------------------------------------------------------

    if ! opencode_verify_npm; then

        opencode_error \
            "npm is not available after Node.js installation."

        return 1
    fi

    # ------------------------------------------------------------
    # npm prefix
    # ------------------------------------------------------------

    if ! opencode_configure_npm_prefix; then
        return 1
    fi

    # ------------------------------------------------------------
    # OpenCode package
    # ------------------------------------------------------------

    if ! opencode_install_package; then
        return 1
    fi

    # ------------------------------------------------------------
    # OpenCode executable
    # ------------------------------------------------------------

    if ! opencode_verify_command; then
        return 1
    fi

    # ------------------------------------------------------------
    # Workspace
    # ------------------------------------------------------------

    if ! opencode_create_workdir; then
        return 1
    fi

    # ------------------------------------------------------------
    # Launcher
    # ------------------------------------------------------------

    if ! opencode_create_launcher; then
        return 1
    fi

    # ------------------------------------------------------------
    # Final verification
    # ------------------------------------------------------------

    if ! opencode_verify; then
        return 1
    fi

    if ! opencode_verify_launcher; then
        return 1
    fi

    opencode_log \
        "OpenCode installation completed successfully."

    return 0
}


# ============================================================================
# LAUNCH OPENCODE
# ============================================================================
#
# This function launches OpenCode inside Ubuntu.
#
# IMPORTANT:
#
# `opencode` is interactive, so it must NOT be executed through a command
# capture mechanism such as $(...) because that would interfere with its
# terminal interaction.
# ============================================================================

opencode_launch() {

    opencode_info \
        "Launching OpenCode..."

    if ! opencode_verify; then

        opencode_error \
            "OpenCode verification failed. Launch aborted."

        return 1
    fi

    local workdir="$OPENCODE_WORKDIR"

    if ! opencode_ubuntu \
        "OpenCode workspace verification" \
        test \
        -d \
        "$workdir"; then

        if ! opencode_create_workdir; then
            return 1
        fi
    fi

    opencode_success \
        "Haider Bhai's OpenCode environment is ready."

    opencode_info \
        "Workspace: ${workdir}"

    opencode_info \
        "Starting OpenCode..."

    # ------------------------------------------------------------
    # Interactive launch
    # ------------------------------------------------------------

    if ! command -v proot-distro >/dev/null 2>&1; then

        opencode_error \
            "proot-distro is unavailable."

        return 127
    fi

    proot-distro login \
        "${HAIDER_UBUNTU_NAME:-ubuntu}" \
        --bind \
        "${HAIDER_UBUNTU_BIND_SOURCE:-/storage/emulated/0}:${HAIDER_UBUNTU_BIND_TARGET:-/mobile_storage}" \
        -- \
        bash \
        -lc \
        "cd '${workdir}' && exec opencode"

    local result=$?

    opencode_log \
        "OpenCode process exited with code ${result}."

    return "$result"
}


# ============================================================================
# DIAGNOSTICS
# ============================================================================

opencode_diagnostics() {

    printf '\n'

    printf '%s\n' \
        "============================================================"

    printf '%s\n' \
        "HAIDER ALI — OPENCODE DIAGNOSTICS"

    printf '%s\n' \
        "============================================================"

    printf '%-30s %s\n' \
        "Node.js:" \
        "${OPENCODE_NODE_VERSION:-unknown}"

    printf '%-30s %s\n' \
        "npm:" \
        "${OPENCODE_NPM_VERSION:-unknown}"

    printf '%-30s %s\n' \
        "OpenCode package:" \
        "${OPENCODE_PACKAGE}"

    printf '%-30s %s\n' \
        "OpenCode version:" \
        "${OPENCODE_VERSION:-unknown}"

    printf '%-30s %s\n' \
        "Node ready:" \
        "${OPENCODE_NODE_READY}"

    printf '%-30s %s\n' \
        "npm ready:" \
        "${OPENCODE_NPM_READY}"

    printf '%-30s %s\n' \
        "Package ready:" \
        "${OPENCODE_PACKAGE_READY}"

    printf '%-30s %s\n' \
        "Command ready:" \
        "${OPENCODE_COMMAND_READY}"

    printf '%-30s %s\n' \
        "Workspace:" \
        "${OPENCODE_WORKDIR}"

    printf '%-30s %s\n' \
        "Launcher:" \
        "${OPENCODE_LAUNCHER_PATH:-not-created}"

    printf '%s\n' \
        "============================================================"

    opencode_log \
        "OpenCode diagnostics generated."

    return 0
}


# ============================================================================
# FINAL STATUS
# ============================================================================

opencode_status() {

    if [[ "$OPENCODE_NODE_READY" == "true" &&
          "$OPENCODE_NPM_READY" == "true" &&
          "$OPENCODE_PACKAGE_READY" == "true" &&
          "$OPENCODE_COMMAND_READY" == "true" ]]; then

        opencode_success \
            "OpenCode system status: READY"

        return 0
    fi

    opencode_warning \
        "OpenCode system status: NOT READY"

    return 1
}


# ============================================================================
# MODULE READY
# ============================================================================

opencode_log "Haider Ali OpenCode module loaded."

return 0 2>/dev/null || true
