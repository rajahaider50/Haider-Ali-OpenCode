#!/usr/bin/env bash
#
# ============================================================================
#  HAIDER ALI — OPENCODE PROFESSIONAL INSTALLER
# ============================================================================
#
#  File    : config.sh
#  Version : 1.0.0
#  Purpose : Central configuration for the complete installer system
#
#  This file contains configuration only.
#  Installation logic belongs to the modules inside /lib.
#
# ============================================================================

# ----------------------------------------------------------------------------
# Prevent accidental execution
# ----------------------------------------------------------------------------
#
# config.sh is designed to be sourced by install.sh and other modules.
# It is not intended to be executed as a standalone installer.
# ----------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    printf '%s\n' \
        "This file is a configuration module."

    printf '%s\n' \
        "Run install.sh instead."

    exit 1
fi


# ============================================================================
# PROJECT INFORMATION
# ============================================================================

export HAIDER_PROJECT_NAME="Haider-Ali-OpenCode"

export HAIDER_INSTALLER_NAME="Haider Ali — OpenCode Professional Installer"

export HAIDER_INSTALLER_VERSION="1.0.0"

export HAIDER_INSTALLER_AUTHOR="Haider Ali"

export HAIDER_INSTALLER_STAGE_PREFIX="Haider Bhai"


# ============================================================================
# BRANDING
# ============================================================================

export HAIDER_BRAND_NAME="HAIDER ALI"

export HAIDER_BRAND_SHORT_NAME="HAIDER BHAI"

export HAIDER_SYSTEM_NAME="HAIDER ALI OPENCODE SYSTEM"

export HAIDER_READY_MESSAGE="HAIDER BHAI'S SYSTEM READY"


# ============================================================================
# TERMINAL UI SETTINGS
# ============================================================================

# Enable colored terminal output.
export HAIDER_ENABLE_COLORS="true"

# Enable Unicode box / progress interface.
export HAIDER_ENABLE_UNICODE="true"

# Enable animated progress indicators where supported.
export HAIDER_ENABLE_ANIMATION="true"

# Minimum terminal width expected by the UI.
export HAIDER_MIN_TERMINAL_WIDTH="60"

# Maximum title width used by the UI.
export HAIDER_UI_WIDTH="64"


# ============================================================================
# COLOR CONFIGURATION
# ============================================================================
#
# These are ANSI color codes.
#
# Green  = successful operations
# Red    = errors
# Yellow = warnings / recovery
# Blue   = information
# Cyan   = active operation
# White  = normal text
# Gray   = secondary information
# ----------------------------------------------------------------------------

export HAIDER_COLOR_RESET='\033[0m'

export HAIDER_COLOR_GREEN='\033[0;32m'

export HAIDER_COLOR_BRIGHT_GREEN='\033[1;32m'

export HAIDER_COLOR_RED='\033[0;31m'

export HAIDER_COLOR_BRIGHT_RED='\033[1;31m'

export HAIDER_COLOR_YELLOW='\033[0;33m'

export HAIDER_COLOR_BRIGHT_YELLOW='\033[1;33m'

export HAIDER_COLOR_BLUE='\033[0;34m'

export HAIDER_COLOR_BRIGHT_BLUE='\033[1;34m'

export HAIDER_COLOR_CYAN='\033[0;36m'

export HAIDER_COLOR_BRIGHT_CYAN='\033[1;36m'

export HAIDER_COLOR_WHITE='\033[0;37m'

export HAIDER_COLOR_BRIGHT_WHITE='\033[1;37m'

export HAIDER_COLOR_GRAY='\033[0;90m'


# ============================================================================
# STATUS SYMBOLS
# ============================================================================

export HAIDER_SYMBOL_PASS="✓"

export HAIDER_SYMBOL_FAIL="✗"

export HAIDER_SYMBOL_WARNING="!"

export HAIDER_SYMBOL_INFO="•"

export HAIDER_SYMBOL_RUNNING="▶"

export HAIDER_SYMBOL_ARROW="→"

export HAIDER_SYMBOL_RETRY="↻"

export HAIDER_SYMBOL_CHECK="✓"


# ============================================================================
# TERMUX CONFIGURATION
# ============================================================================

# Expected Termux prefix.
export HAIDER_TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

# Termux home directory.
export HAIDER_TERMUX_HOME="${HOME:-/data/data/com.termux/files/home}"

# Termux package manager.
export HAIDER_TERMUX_PACKAGE_MANAGER="pkg"

# Termux storage root.
export HAIDER_TERMUX_STORAGE="/storage/emulated/0"

# Android shared storage bind target inside Ubuntu.
export HAIDER_MOBILE_STORAGE="/mobile_storage"


# ============================================================================
# PROOT-DISTRO CONFIGURATION
# ============================================================================

export HAIDER_PROOT_PACKAGE="proot-distro"

export HAIDER_UBUNTU_NAME="ubuntu"

export HAIDER_UBUNTU_LOGIN_COMMAND="proot-distro"

export HAIDER_UBUNTU_BIND_SOURCE="${HAIDER_TERMUX_STORAGE}"

export HAIDER_UBUNTU_BIND_TARGET="${HAIDER_MOBILE_STORAGE}"


# ============================================================================
# UBUNTU CONFIGURATION
# ============================================================================

export HAIDER_UBUNTU_PACKAGE_MANAGER="apt"

export HAIDER_UBUNTU_ROOT_DIRECTORY="/root"

export HAIDER_UBUNTU_HOME="/root"

export HAIDER_UBUNTU_WORKSPACE="${HAIDER_MOBILE_STORAGE}/Haider-Ali-Workspace"


# ============================================================================
# SYSTEM PACKAGES
# ============================================================================
#
# Packages required by the installation system.
#
# Keep this list centralized so system.sh does not contain scattered package
# names throughout the installation logic.
# ----------------------------------------------------------------------------

export HAIDER_TERMUX_REQUIRED_PACKAGES=(
    "proot-distro"
)

export HAIDER_UBUNTU_REQUIRED_PACKAGES=(
    "curl"
    "ca-certificates"
)


# ============================================================================
# NODE.JS CONFIGURATION
# ============================================================================

# Major Node.js version required by the current installer.
export HAIDER_NODE_MAJOR_VERSION="20"

export HAIDER_NODE_VERSION="20.x"

export HAIDER_NODE_SOURCE_URL="https://deb.nodesource.com/setup_${HAIDER_NODE_MAJOR_VERSION}.x"

export HAIDER_NODE_BINARY="node"

export HAIDER_NPM_BINARY="npm"

export HAIDER_NODE_MIN_VERSION_MAJOR="${HAIDER_NODE_MAJOR_VERSION}"


# ============================================================================
# OPENCODE CONFIGURATION
# ============================================================================

export HAIDER_OPENCODE_PACKAGE="opencode-ai"

export HAIDER_OPENCODE_COMMAND="opencode"

export HAIDER_OPENCODE_INSTALL_METHOD="npm-global"

export HAIDER_OPENCODE_NPM_GLOBAL="true"


# ============================================================================
# INSTALLATION BEHAVIOR
# ============================================================================

# If true, already installed components will be reused.
export HAIDER_SKIP_EXISTING="true"

# If true, package managers may update existing package metadata.
export HAIDER_ALLOW_UPDATES="true"

# If true, failed operations are passed to the recovery system.
export HAIDER_ENABLE_RECOVERY="true"

# If true, failed operations can be retried.
export HAIDER_ENABLE_RETRY="true"

# If true, the installer verifies every major component after installation.
export HAIDER_ENABLE_VERIFICATION="true"

# If true, the installer attempts to resume an interrupted setup.
export HAIDER_ENABLE_RESUME="true"


# ============================================================================
# RETRY CONFIGURATION
# ============================================================================

# Maximum number of attempts for a recoverable operation.
export HAIDER_MAX_RETRIES="3"

# Delay between retries in seconds.
export HAIDER_RETRY_DELAY="3"

# Maximum recovery attempts for a single stage.
export HAIDER_MAX_RECOVERY_ATTEMPTS="3"

# Delay before a recovery operation.
export HAIDER_RECOVERY_DELAY="2"


# ============================================================================
# TIMEOUT CONFIGURATION
# ============================================================================
#
# These values prevent an operation from waiting forever where timeout support
# is available.
# ----------------------------------------------------------------------------

export HAIDER_NETWORK_TIMEOUT="30"

export HAIDER_CONNECTION_TIMEOUT="15"

export HAIDER_COMMAND_TIMEOUT="300"

export HAIDER_PACKAGE_TIMEOUT="600"

export HAIDER_OPENCODE_TIMEOUT="300"


# ============================================================================
# LOGGING CONFIGURATION
# ============================================================================

export HAIDER_ENABLE_LOGGING="true"

export HAIDER_LOG_DIRECTORY="${HAIDER_TERMUX_HOME}/.haider-opencode/logs"

export HAIDER_LOG_FILE_PREFIX="install"

export HAIDER_LOG_EXTENSION="log"

export HAIDER_MAX_LOG_FILES="10"


# ============================================================================
# STATE CONFIGURATION
# ============================================================================
#
# State information allows the installer to determine what has already been
# completed and potentially resume an interrupted installation.
# ----------------------------------------------------------------------------

export HAIDER_STATE_DIRECTORY="${HAIDER_TERMUX_HOME}/.haider-opencode/state"

export HAIDER_STATE_FILE="${HAIDER_STATE_DIRECTORY}/installation.state"

export HAIDER_LOCK_DIRECTORY="${HAIDER_TERMUX_HOME}/.haider-opencode"

export HAIDER_LOCK_FILE="${HAIDER_LOCK_DIRECTORY}/installer.lock"


# ============================================================================
# CACHE CONFIGURATION
# ============================================================================

export HAIDER_CACHE_DIRECTORY="${HAIDER_TERMUX_HOME}/.haider-opencode/cache"

export HAIDER_TEMP_DIRECTORY="${HAIDER_TERMUX_HOME}/.haider-opencode/tmp"


# ============================================================================
# WORKSPACE CONFIGURATION
# ============================================================================

export HAIDER_WORKSPACE_NAME="Haider-Ali-Workspace"

export HAIDER_WORKSPACE_PATH="${HAIDER_MOBILE_STORAGE}/${HAIDER_WORKSPACE_NAME}"

export HAIDER_PROJECTS_DIRECTORY="${HAIDER_WORKSPACE_PATH}/Projects"

export HAIDER_CODE_DIRECTORY="${HAIDER_WORKSPACE_PATH}/Code"

export HAIDER_LOGS_DIRECTORY="${HAIDER_WORKSPACE_PATH}/Logs"


# ============================================================================
# LAUNCHER CONFIGURATION
# ============================================================================

export HAIDER_LAUNCHER_NAME="haider"

export HAIDER_LAUNCHER_DESCRIPTION="Launch Haider Ali OpenCode"

export HAIDER_LAUNCHER_DIRECTORY="${HAIDER_TERMUX_HOME}/bin"

export HAIDER_LAUNCHER_PATH="${HAIDER_LAUNCHER_DIRECTORY}/${HAIDER_LAUNCHER_NAME}"


# ============================================================================
# INSTALLATION STAGES
# ============================================================================
#
# These names are used by the UI and logging system.
#
# Keep the order stable because it represents the installation pipeline.
# ----------------------------------------------------------------------------

export HAIDER_TOTAL_STAGES="8"

export HAIDER_STAGE_01="Termux Environment"

export HAIDER_STAGE_02="Storage Access"

export HAIDER_STAGE_03="Proot-Distro"

export HAIDER_STAGE_04="Ubuntu Environment"

export HAIDER_STAGE_05="Node.js Runtime"

export HAIDER_STAGE_06="OpenCode Engine"

export HAIDER_STAGE_07="Mobile Workspace"

export HAIDER_STAGE_08="OpenCode Launcher"


# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

export HAIDER_NETWORK_RETRY_ENABLED="true"

export HAIDER_NETWORK_RETRIES="3"

export HAIDER_NETWORK_RETRY_DELAY="5"

export HAIDER_NODESOURCE_DOMAIN="deb.nodesource.com"

export HAIDER_NPM_REGISTRY="https://registry.npmjs.org/"


# ============================================================================
# SAFETY CONFIGURATION
# ============================================================================

# Never automatically delete the user's personal Android storage.
export HAIDER_PROTECT_MOBILE_STORAGE="true"

# Never remove existing Ubuntu installation automatically.
export HAIDER_PROTECT_EXISTING_UBUNTU="true"

# Never remove existing Node.js automatically.
export HAIDER_PROTECT_EXISTING_NODE="true"

# Never remove existing OpenCode automatically.
export HAIDER_PROTECT_EXISTING_OPENCODE="true"

# Destructive operations require explicit confirmation from a higher-level
# module.
export HAIDER_ALLOW_DESTRUCTIVE_ACTIONS="false"


# ============================================================================
# VERIFICATION CONFIGURATION
# ============================================================================

export HAIDER_VERIFY_TERMUX="true"

export HAIDER_VERIFY_PROOT="true"

export HAIDER_VERIFY_UBUNTU="true"

export HAIDER_VERIFY_STORAGE="true"

export HAIDER_VERIFY_CURL="true"

export HAIDER_VERIFY_NODE="true"

export HAIDER_VERIFY_NPM="true"

export HAIDER_VERIFY_OPENCODE="true"

export HAIDER_VERIFY_WORKSPACE="true"

export HAIDER_VERIFY_LAUNCHER="true"


# ============================================================================
# ERROR REPORTING
# ============================================================================

export HAIDER_ERROR_REPORTING="true"

export HAIDER_SHOW_ERROR_CODE="true"

export HAIDER_SHOW_FAILED_COMMAND="true"

export HAIDER_SHOW_RECOVERY_STEPS="true"

export HAIDER_SHOW_LOG_LOCATION="true"


# ============================================================================
# INSTALLER ENVIRONMENT
# ============================================================================

# Prevent npm from unnecessarily displaying update notifications.
export NPM_CONFIG_UPDATE_NOTIFIER="false"

# Prevent npm from prompting for interactive input where possible.
export NPM_CONFIG_YES="true"

# Disable unnecessary npm funding messages.
export NPM_CONFIG_FUND="false"

# Disable unnecessary npm audit messages during automated installation.
export NPM_CONFIG_AUDIT="false"


# ============================================================================
# FEATURE FLAGS
# ============================================================================
#
# These allow future functionality without redesigning the configuration
# architecture.
# ----------------------------------------------------------------------------

export HAIDER_FEATURE_AUTO_REPAIR="true"

export HAIDER_FEATURE_AUTO_RETRY="true"

export HAIDER_FEATURE_PROGRESS_BAR="true"

export HAIDER_FEATURE_INSTALL_LOG="true"

export HAIDER_FEATURE_STATE_TRACKING="true"

export HAIDER_FEATURE_RESUME="true"

export HAIDER_FEATURE_WORKSPACE="true"

export HAIDER_FEATURE_LAUNCHER="true"

export HAIDER_FEATURE_VERSION_CHECK="true"


# ============================================================================
# CONFIGURATION VALIDATION
# ============================================================================
#
# This function is called by the system module before installation begins.
# It verifies that critical configuration values are not empty or malformed.
# ----------------------------------------------------------------------------

config_validate() {

    local required_variables=(
        "HAIDER_PROJECT_NAME"
        "HAIDER_INSTALLER_VERSION"
        "HAIDER_TERMUX_PREFIX"
        "HAIDER_UBUNTU_NAME"
        "HAIDER_MOBILE_STORAGE"
        "HAIDER_NODE_MAJOR_VERSION"
        "HAIDER_OPENCODE_PACKAGE"
        "HAIDER_OPENCODE_COMMAND"
        "HAIDER_MAX_RETRIES"
        "HAIDER_MAX_RECOVERY_ATTEMPTS"
    )

    local variable
    local value

    for variable in "${required_variables[@]}"; do

        value="${!variable:-}"

        if [[ -z "$value" ]]; then

            printf '%s\n' \
                "[CONFIG ERROR] Required variable is empty: ${variable}"

            return 1
        fi

    done

    # Numeric validation.
    if ! [[ "$HAIDER_MAX_RETRIES" =~ ^[0-9]+$ ]]; then

        printf '%s\n' \
            "[CONFIG ERROR] HAIDER_MAX_RETRIES must be numeric."

        return 1
    fi

    if ! [[ "$HAIDER_MAX_RECOVERY_ATTEMPTS" =~ ^[0-9]+$ ]]; then

        printf '%s\n' \
            "[CONFIG ERROR] HAIDER_MAX_RECOVERY_ATTEMPTS must be numeric."

        return 1
    fi

    if ! [[ "$HAIDER_NODE_MAJOR_VERSION" =~ ^[0-9]+$ ]]; then

        printf '%s\n' \
            "[CONFIG ERROR] HAIDER_NODE_MAJOR_VERSION must be numeric."

        return 1
    fi

    return 0
}


# ============================================================================
# CONFIGURATION SUMMARY
# ============================================================================
#
# Used by the UI/debugging system when configuration diagnostics are needed.
# ----------------------------------------------------------------------------

config_summary() {

    printf '%s\n' "------------------------------------------------------------"
    printf '%s\n' "Haider Ali OpenCode Configuration"
    printf '%s\n' "------------------------------------------------------------"

    printf '%-30s %s\n' \
        "Project:" \
        "$HAIDER_PROJECT_NAME"

    printf '%-30s %s\n' \
        "Installer Version:" \
        "$HAIDER_INSTALLER_VERSION"

    printf '%-30s %s\n' \
        "Ubuntu:" \
        "$HAIDER_UBUNTU_NAME"

    printf '%-30s %s\n' \
        "Node.js:" \
        "$HAIDER_NODE_VERSION"

    printf '%-30s %s\n' \
        "OpenCode Package:" \
        "$HAIDER_OPENCODE_PACKAGE"

    printf '%-30s %s\n' \
        "OpenCode Command:" \
        "$HAIDER_OPENCODE_COMMAND"

    printf '%-30s %s\n' \
        "Max Retries:" \
        "$HAIDER_MAX_RETRIES"

    printf '%-30s %s\n' \
        "Recovery Attempts:" \
        "$HAIDER_MAX_RECOVERY_ATTEMPTS"

    printf '%-30s %s\n' \
        "Logging:" \
        "$HAIDER_ENABLE_LOGGING"

    printf '%-30s %s\n' \
        "Auto Recovery:" \
        "$HAIDER_ENABLE_RECOVERY"

    printf '%-30s %s\n' \
        "Verification:" \
        "$HAIDER_ENABLE_VERIFICATION"

    printf '%s\n' "------------------------------------------------------------"

    return 0
}


# ============================================================================
# CONFIGURATION LOADED
# ============================================================================

export HAIDER_CONFIG_LOADED="true"
