#!/usr/bin/env bash
#
# config.sh — Central configuration for the Haider Ali OpenCode System.
#
# All tunable settings live in this file. Stage scripts and libraries read
# from here so that no other part of the project hard-codes behaviour.

# shellcheck disable=SC2034 # variables here are consumed by other sourced modules
APP_NAME="Haider Ali OpenCode System"
APP_OWNER="Haider Ali"
APP_VERSION="1.0.0"

UBUNTU_NAME="ubuntu"
UBUNTU_STORAGE_BIND="/storage/emulated/0:/mobile_storage"
UBUNTU_STORAGE_DEST="/mobile_storage"
UBUNTU_HEALTH_TIMEOUT="30"

NODE_MAJOR_VERSION="20"
NODESOURCE_SETUP_URL="https://deb.nodesource.com/setup_${NODE_MAJOR_VERSION}.x"
NODESOURCE_SETUP_TMP="/tmp/nodesource_setup.sh"

OPENCODE_PACKAGE="opencode-ai"

MAX_RECOVERY_ATTEMPTS="3"
RECOVERY_RETRY_DELAY="2"
AUTO_RECOVERY="true"

ENABLE_COLORS="true"
ENABLE_LOGGING="true"

LOG_DIRECTORY="${HOME}/.haider-ali-opencode/logs"
LOG_FILENAME_PREFIX="haider-opencode"

# Stage metadata used by install.sh to drive the numbered stage display.
STAGE_TOTAL=11
STAGE_NAMES=(
  "Termux Package Engine"
  "proot-distro Install"
  "Android Storage Access"
  "Ubuntu Container"
  "Ubuntu Login / Storage Bind"
  "Ubuntu Package Engine"
  "curl Install"
  "Node.js Repository"
  "Node.js Runtime"
  "OpenCode AI"
  "Launch OpenCode"
)
