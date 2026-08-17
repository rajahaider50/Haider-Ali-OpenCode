#!/usr/bin/env bash
#
# ============================================================================
#  HAIDER ALI — OPENCODE PROFESSIONAL INSTALLER
# ============================================================================
#
#  File    : lib/ui.sh
#  Version : 1.0.0
#  Purpose : Professional terminal user-interface engine
#
#  Responsibilities:
#
#      • Professional Haider Ali branding
#      • ANSI color management
#      • Stage status display
#      • PASS / FAIL / WARNING / RUNNING states
#      • Progress bars
#      • Spinners
#      • Terminal width detection
#      • Timestamped messages
#      • Installation summary
#      • Log integration
#
#  Required by install.sh:
#
#      ui_init
#      ui_banner
#      ui_stage_start
#      ui_stage_pass
#      ui_stage_fail
#      ui_info
#      ui_error
#      ui_success
#
# ============================================================================


# ============================================================================
# MODULE GUARD
# ============================================================================

if [[ "${HAIDER_UI_MODULE_LOADED:-false}" == "true" ]]; then
    return 0 2>/dev/null || exit 0
fi

export HAIDER_UI_MODULE_LOADED="true"


# ============================================================================
# INTERNAL RUNTIME STATE
# ============================================================================

UI_INITIALIZED="false"

UI_TERMINAL_WIDTH=80

UI_CURRENT_STAGE=""

UI_CURRENT_STAGE_NUMBER=0

UI_TOTAL_STAGES="${HAIDER_TOTAL_STAGES:-8}"

UI_STAGE_START_TIME=0

UI_SUCCESS_COUNT=0

UI_FAILURE_COUNT=0

UI_WARNING_COUNT=0

UI_SKIPPED_COUNT=0

UI_RUNNING_COUNT=0

UI_LOG_FILE=""

UI_SPINNER_PID=""

UI_SPINNER_ACTIVE="false"


# ============================================================================
# FALLBACK COLORS
# ============================================================================
#
# These fallbacks make the module usable even if config.sh was not loaded
# correctly. The main installer should always load config.sh first.
# ============================================================================

UI_RESET="${HAIDER_COLOR_RESET:-$'\033[0m'}"

UI_GREEN="${HAIDER_COLOR_GREEN:-$'\033[0;32m'}"

UI_BRIGHT_GREEN="${HAIDER_COLOR_BRIGHT_GREEN:-$'\033[1;32m'}"

UI_RED="${HAIDER_COLOR_RED:-$'\033[0;31m'}"

UI_BRIGHT_RED="${HAIDER_COLOR_BRIGHT_RED:-$'\033[1;31m'}"

UI_YELLOW="${HAIDER_COLOR_YELLOW:-$'\033[0;33m'}"

UI_BRIGHT_YELLOW="${HAIDER_COLOR_BRIGHT_YELLOW:-$'\033[1;33m'}"

UI_BLUE="${HAIDER_COLOR_BLUE:-$'\033[0;34m'}"

UI_BRIGHT_BLUE="${HAIDER_COLOR_BRIGHT_BLUE:-$'\033[1;34m'}"

UI_CYAN="${HAIDER_COLOR_CYAN:-$'\033[0;36m'}"

UI_BRIGHT_CYAN="${HAIDER_COLOR_BRIGHT_CYAN:-$'\033[1;36m'}"

UI_WHITE="${HAIDER_COLOR_WHITE:-$'\033[0;37m'}"

UI_BRIGHT_WHITE="${HAIDER_COLOR_BRIGHT_WHITE:-$'\033[1;37m'}"

UI_GRAY="${HAIDER_COLOR_GRAY:-$'\033[0;90m'}"


# ============================================================================
# SYMBOLS
# ============================================================================

UI_PASS="${HAIDER_SYMBOL_PASS:-✓}"

UI_FAIL="${HAIDER_SYMBOL_FAIL:-✗}"

UI_WARNING="${HAIDER_SYMBOL_WARNING:-!}"

UI_INFO_SYMBOL="${HAIDER_SYMBOL_INFO:-•}"

UI_RUNNING="${HAIDER_SYMBOL_RUNNING:-▶}"

UI_ARROW="${HAIDER_SYMBOL_ARROW:-→}"

UI_RETRY="${HAIDER_SYMBOL_RETRY:-↻}"

UI_CHECK="${HAIDER_SYMBOL_CHECK:-✓}"


# ============================================================================
# BASIC TERMINAL FUNCTIONS
# ============================================================================

ui_is_tty() {

    [[ -t 1 ]]
}


ui_detect_terminal_width() {

    local detected_width

    detected_width="$(tput cols 2>/dev/null || true)"

    if [[ "$detected_width" =~ ^[0-9]+$ ]] &&
       (( detected_width >= 40 )); then

        UI_TERMINAL_WIDTH="$detected_width"

    elif [[ -n "${COLUMNS:-}" ]] &&
         [[ "$COLUMNS" =~ ^[0-9]+$ ]] &&
         (( COLUMNS >= 40 )); then

        UI_TERMINAL_WIDTH="$COLUMNS"

    else

        UI_TERMINAL_WIDTH="${HAIDER_UI_WIDTH:-64}"

    fi

    return 0
}


# ============================================================================
# COLOR CONTROL
# ============================================================================

ui_enable_colors() {

    if [[ "${HAIDER_ENABLE_COLORS:-true}" != "true" ]]; then

        UI_RESET=""
        UI_GREEN=""
        UI_BRIGHT_GREEN=""
        UI_RED=""
        UI_BRIGHT_RED=""
        UI_YELLOW=""
        UI_BRIGHT_YELLOW=""
        UI_BLUE=""
        UI_BRIGHT_BLUE=""
        UI_CYAN=""
        UI_BRIGHT_CYAN=""
        UI_WHITE=""
        UI_BRIGHT_WHITE=""
        UI_GRAY=""

        return 0
    fi

    # Respect NO_COLOR convention.
    if [[ -n "${NO_COLOR:-}" ]]; then

        UI_RESET=""
        UI_GREEN=""
        UI_BRIGHT_GREEN=""
        UI_RED=""
        UI_BRIGHT_RED=""
        UI_YELLOW=""
        UI_BRIGHT_YELLOW=""
        UI_BLUE=""
        UI_BRIGHT_BLUE=""
        UI_CYAN=""
        UI_BRIGHT_CYAN=""
        UI_WHITE=""
        UI_BRIGHT_WHITE=""
        UI_GRAY=""

        return 0
    fi

    return 0
}


# ============================================================================
# LOG FILE
# ============================================================================

ui_set_log_file() {

    local requested_file="${1:-}"

    if [[ -n "$requested_file" ]]; then

        UI_LOG_FILE="$requested_file"

        return 0
    fi

    if [[ "${HAIDER_ENABLE_LOGGING:-true}" != "true" ]]; then
        return 0
    fi

    local log_directory
    local timestamp

    log_directory="${HAIDER_LOG_DIRECTORY:-${HOME}/.haider-opencode/logs}"

    timestamp="$(date '+%Y%m%d-%H%M%S')"

    mkdir -p "$log_directory" 2>/dev/null || return 0

    UI_LOG_FILE="${log_directory}/${HAIDER_LOG_FILE_PREFIX:-install}-${timestamp}.${HAIDER_LOG_EXTENSION:-log}"

    touch "$UI_LOG_FILE" 2>/dev/null || UI_LOG_FILE=""

    return 0
}


# ============================================================================
# LOGGING ENGINE
# ============================================================================

ui_log() {

    local message="$*"

    [[ -z "$UI_LOG_FILE" ]] && return 0

    printf '[%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$message" >> "$UI_LOG_FILE" 2>/dev/null || true

    return 0
}


# ============================================================================
# TEXT HELPERS
# ============================================================================

ui_timestamp() {

    date '+%H:%M:%S'
}


ui_repeat() {

    local character="$1"
    local count="$2"

    printf '%*s' "$count" '' | tr ' ' "$character"
}


ui_center_text() {

    local text="$1"
    local width="${2:-$UI_TERMINAL_WIDTH}"

    local text_length="${#text}"

    if (( text_length >= width )); then

        printf '%s' "$text"

        return 0
    fi

    local padding=$(( (width - text_length) / 2 ))

    printf '%*s%s' "$padding" '' "$text"
}


# ============================================================================
# INITIALIZATION
# ============================================================================

ui_init() {

    ui_detect_terminal_width

    ui_enable_colors

    ui_set_log_file

    UI_INITIALIZED="true"

    ui_log "UI engine initialized."

    ui_log "Terminal width: ${UI_TERMINAL_WIDTH}"

    return 0
}


# ============================================================================
# CLEAR LINE
# ============================================================================

ui_clear_line() {

    if ui_is_tty; then

        printf '\r\033[2K'

    else

        printf '\r'
    fi

    return 0
}


# ============================================================================
# BANNER
# ============================================================================

ui_banner() {

    local installer_name="${1:-${HAIDER_INSTALLER_NAME:-Haider Ali — OpenCode Professional Installer}}"

    local version="${2:-${HAIDER_INSTALLER_VERSION:-1.0.0}}"

    local width=64

    local line

    line="$(ui_repeat '═' "$width")"

    printf '\n'

    printf '%s%s%s\n' \
        "$UI_BRIGHT_GREEN" \
        "╔${line}╗" \
        "$UI_RESET"

    printf '%s║%s%s%s║%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET" \
        "$(ui_center_text "HAIDER ALI • OPENCODE SYSTEM" "$width")" \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET"

    printf '%s║%s%s%s║%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET" \
        "$(ui_center_text "PROFESSIONAL INSTALLER" "$width")" \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET"

    printf '%s║%s%s%s║%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET" \
        "$(ui_center_text "Version ${version}" "$width")" \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET"

    printf '%s╚%s╝%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$line" \
        "$UI_RESET"

    printf '\n'

    ui_log "============================================================"
    ui_log "$installer_name"
    ui_log "Version: $version"
    ui_log "============================================================"

    return 0
}


# ============================================================================
# SECTION HEADER
# ============================================================================

ui_section() {

    local title="$1"

    printf '\n'

    printf '%s%s%s\n' \
        "$UI_BRIGHT_CYAN" \
        "── ${title} ──" \
        "$UI_RESET"

    ui_log "SECTION: $title"

    return 0
}


# ============================================================================
# GENERIC MESSAGE FUNCTIONS
# ============================================================================

ui_info() {

    local message="$*"

    printf '%s[%s]%s %s%s%s\n' \
        "$UI_CYAN" \
        "$(ui_timestamp)" \
        "$UI_RESET" \
        "$UI_WHITE" \
        "$message" \
        "$UI_RESET"

    ui_log "INFO: $message"

    return 0
}


ui_success() {

    local message="$*"

    printf '%s%s %s%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$UI_PASS" \
        "$message" \
        "$UI_RESET"

    ui_log "SUCCESS: $message"

    return 0
}


ui_warning() {

    local message="$*"

    ((UI_WARNING_COUNT++))

    printf '%s%s %s%s\n' \
        "$UI_BRIGHT_YELLOW" \
        "$UI_WARNING" \
        "$message" \
        "$UI_RESET"

    ui_log "WARNING: $message"

    return 0
}


ui_error() {

    local message="$*"

    printf '%s%s %s%s\n' \
        "$UI_BRIGHT_RED" \
        "$UI_FAIL" \
        "$message" \
        "$UI_RESET" \
        >&2

    ui_log "ERROR: $message"

    return 0
}


# ============================================================================
# STAGE START
# ============================================================================

ui_stage_start() {

    local stage_name="$1"

    ((UI_CURRENT_STAGE_NUMBER++))

    ((UI_RUNNING_COUNT++))

    UI_CURRENT_STAGE="$stage_name"

    UI_STAGE_START_TIME="$(date +%s)"

    printf '\n'

    printf '%s[%02d/%02d]%s %s%s%s %s\n' \
        "$UI_BRIGHT_CYAN" \
        "$UI_CURRENT_STAGE_NUMBER" \
        "$UI_TOTAL_STAGES" \
        "$UI_RESET" \
        "$UI_BRIGHT_CYAN" \
        "$UI_RUNNING" \
        "$UI_RESET" \
        "$stage_name"

    printf '      %s%s RUNNING%s\n' \
        "$UI_CYAN" \
        "$UI_ARROW" \
        "$UI_RESET"

    ui_log "STAGE START: [$UI_CURRENT_STAGE_NUMBER/$UI_TOTAL_STAGES] $stage_name"

    return 0
}


# ============================================================================
# STAGE PASS
# ============================================================================

ui_stage_pass() {

    local stage_name="$1"

    local end_time
    local elapsed

    end_time="$(date +%s)"

    elapsed=$(( end_time - UI_STAGE_START_TIME ))

    ((UI_SUCCESS_COUNT++))

    if (( UI_RUNNING_COUNT > 0 )); then
        ((UI_RUNNING_COUNT--))
    fi

    printf '      %s%s PASS%s  %s%s%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$UI_PASS" \
        "$UI_RESET" \
        "$UI_GREEN" \
        "$stage_name" \
        "$UI_RESET"

    printf '      %sCompleted in %ss%s\n' \
        "$UI_GRAY" \
        "$elapsed" \
        "$UI_RESET"

    ui_log "STAGE PASS: $stage_name (${elapsed}s)"

    return 0
}


# ============================================================================
# STAGE FAIL
# ============================================================================

ui_stage_fail() {

    local stage_name="$1"

    local end_time
    local elapsed

    end_time="$(date +%s)"

    elapsed=$(( end_time - UI_STAGE_START_TIME ))

    ((UI_FAILURE_COUNT++))

    if (( UI_RUNNING_COUNT > 0 )); then
        ((UI_RUNNING_COUNT--))
    fi

    printf '      %s%s FAIL%s  %s%s%s\n' \
        "$UI_BRIGHT_RED" \
        "$UI_FAIL" \
        "$UI_RESET" \
        "$UI_RED" \
        "$stage_name" \
        "$UI_RESET"

    printf '      %sFailed after %ss%s\n' \
        "$UI_GRAY" \
        "$elapsed" \
        "$UI_RESET"

    ui_log "STAGE FAIL: $stage_name (${elapsed}s)"

    return 0
}


# ============================================================================
# RETRY MESSAGE
# ============================================================================

ui_retry() {

    local attempt="$1"
    local maximum="$2"
    local reason="${3:-Recoverable failure}"

    printf '      %s%s RETRY %s/%s%s\n' \
        "$UI_BRIGHT_YELLOW" \
        "$UI_RETRY" \
        "$attempt" \
        "$maximum" \
        "$UI_RESET"

    printf '      %s%s%s\n' \
        "$UI_YELLOW" \
        "$reason" \
        "$UI_RESET"

    ui_log "RETRY: ${attempt}/${maximum} — ${reason}"

    return 0
}


# ============================================================================
# RECOVERY MESSAGE
# ============================================================================

ui_recovery() {

    local message="$*"

    printf '      %s%s RECOVERY%s %s\n' \
        "$UI_BRIGHT_YELLOW" \
        "$UI_RETRY" \
        "$UI_RESET" \
        "$message"

    ui_log "RECOVERY: $message"

    return 0
}


# ============================================================================
# PROGRESS BAR
# ============================================================================

ui_progress() {

    local current="$1"
    local total="$2"
    local label="${3:-Processing}"

    if ! [[ "$current" =~ ^[0-9]+$ ]] ||
       ! [[ "$total" =~ ^[0-9]+$ ]]; then

        return 1
    fi

    if (( total <= 0 )); then
        return 1
    fi

    if (( current < 0 )); then
        current=0
    fi

    if (( current > total )); then
        current="$total"
    fi

    local percentage

    percentage=$(( current * 100 / total ))

    local bar_width=30

    local filled

    filled=$(( percentage * bar_width / 100 ))

    local empty=$(( bar_width - filled ))

    local bar

    bar="$(ui_repeat '█' "$filled")$(ui_repeat '░' "$empty")"

    if ui_is_tty; then

        printf '\r\033[2K'

    fi

    printf '%s%s%s [%s%s%s] %3d%% %s' \
        "$UI_BRIGHT_GREEN" \
        "$bar" \
        "$UI_RESET" \
        "$UI_GREEN" \
        "$bar" \
        "$UI_RESET" \
        "$percentage" \
        "$label"

    if (( current >= total )); then
        printf '\n'
    fi

    return 0
}


# ============================================================================
# SPINNER
# ============================================================================

ui_spinner_start() {

    local message="${1:-Working}"

    [[ "$UI_SPINNER_ACTIVE" == "true" ]] && return 0

    if ! ui_is_tty; then
        return 0
    fi

    UI_SPINNER_ACTIVE="true"

    (
        local spinner_frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

        local index=0

        while [[ "$UI_SPINNER_ACTIVE" == "true" ]]; do

            printf '\r\033[2K%s%s%s %s' \
                "$UI_CYAN" \
                "${spinner_frames[$index]}" \
                "$UI_RESET" \
                "$message"

            index=$(( (index + 1) % ${#spinner_frames[@]} ))

            sleep 0.1
        done

    ) &

    UI_SPINNER_PID="$!"

    return 0
}


ui_spinner_stop() {

    UI_SPINNER_ACTIVE="false"

    if [[ -n "$UI_SPINNER_PID" ]]; then

        kill "$UI_SPINNER_PID" 2>/dev/null || true

        wait "$UI_SPINNER_PID" 2>/dev/null || true

        UI_SPINNER_PID=""

    fi

    if ui_is_tty; then
        printf '\r\033[2K'
    fi

    return 0
}


# ============================================================================
# COMMAND DISPLAY
# ============================================================================

ui_command() {

    local command_text="$*"

    printf '      %s$ %s%s\n' \
        "$UI_GRAY" \
        "$command_text" \
        "$UI_RESET"

    ui_log "COMMAND: $command_text"

    return 0
}


# ============================================================================
# ERROR DETAIL DISPLAY
# ============================================================================

ui_error_detail() {

    local error_code="${1:-unknown}"
    local command="${2:-unknown command}"
    local message="${3:-Unknown error}"

    printf '\n'

    printf '%s%s ERROR DETAILS%s\n' \
        "$UI_BRIGHT_RED" \
        "$UI_FAIL" \
        "$UI_RESET"

    printf '      %sError Code :%s %s\n' \
        "$UI_YELLOW" \
        "$UI_RESET" \
        "$error_code"

    printf '      %sCommand    :%s %s\n' \
        "$UI_YELLOW" \
        "$UI_RESET" \
        "$command"

    printf '      %sMessage    :%s %s\n' \
        "$UI_YELLOW" \
        "$UI_RESET" \
        "$message"

    if [[ -n "$UI_LOG_FILE" ]]; then

        printf '      %sLog File   :%s %s\n' \
            "$UI_YELLOW" \
            "$UI_RESET" \
            "$UI_LOG_FILE"

    fi

    printf '\n'

    ui_log "ERROR DETAIL: code=$error_code command=$command message=$message"

    return 0
}


# ============================================================================
# STAGE SUMMARY
# ============================================================================

ui_summary() {

    local total="$UI_CURRENT_STAGE_NUMBER"

    printf '\n'

    printf '%s%s%s\n' \
        "$UI_BRIGHT_CYAN" \
        "════════ INSTALLATION SUMMARY ════════" \
        "$UI_RESET"

    printf '\n'

    printf '  %sPASS%s      : %s\n' \
        "$UI_GREEN" \
        "$UI_RESET" \
        "$UI_SUCCESS_COUNT"

    printf '  %sFAIL%s      : %s\n' \
        "$UI_RED" \
        "$UI_RESET" \
        "$UI_FAILURE_COUNT"

    printf '  %sWARNING%s   : %s\n' \
        "$UI_YELLOW" \
        "$UI_RESET" \
        "$UI_WARNING_COUNT"

    printf '  %sSTAGES%s    : %s\n' \
        "$UI_CYAN" \
        "$UI_RESET" \
        "$total"

    if [[ -n "$UI_LOG_FILE" ]]; then

        printf '\n'

        printf '  %sLog:%s %s\n' \
            "$UI_GRAY" \
            "$UI_RESET" \
            "$UI_LOG_FILE"

    fi

    printf '\n'

    ui_log "SUMMARY: stages=$total pass=$UI_SUCCESS_COUNT fail=$UI_FAILURE_COUNT warning=$UI_WARNING_COUNT"

    return 0
}


# ============================================================================
# FINAL SUCCESS SCREEN
# ============================================================================

ui_final_success() {

    local width=64

    local line

    line="$(ui_repeat '═' "$width")"

    printf '\n'

    printf '%s╔%s╗%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$line" \
        "$UI_RESET"

    printf '%s║%s%s%s║%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET" \
        "$(ui_center_text "HAIDER BHAI'S SYSTEM READY" "$width")" \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET"

    printf '%s║%s%s%s║%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET" \
        "$(ui_center_text "OPENCODE IS READY TO RUN" "$width")" \
        "$UI_BRIGHT_GREEN" \
        "$UI_RESET"

    printf '%s╚%s╝%s\n' \
        "$UI_BRIGHT_GREEN" \
        "$line" \
        "$UI_RESET"

    printf '\n'

    ui_summary

    return 0
}


# ============================================================================
# FINAL FAILURE SCREEN
# ============================================================================

ui_final_failure() {

    local width=64

    local line

    line="$(ui_repeat '═' "$width")"

    printf '\n'

    printf '%s╔%s╗%s\n' \
        "$UI_BRIGHT_RED" \
        "$line" \
        "$UI_RESET"

    printf '%s║%s%s%s║%s\n' \
        "$UI_BRIGHT_RED" \
        "$UI_RESET" \
        "$(ui_center_text "INSTALLATION FAILED" "$width")" \
        "$UI_BRIGHT_RED" \
        "$UI_RESET"

    printf '%s║%s%s%s║%s\n' \
        "$UI_BRIGHT_RED" \
        "$UI_RESET" \
        "$(ui_center_text "RECOVERY WAS UNABLE TO COMPLETE" "$width")" \
        "$UI_BRIGHT_RED" \
        "$UI_RESET"

    printf '%s╚%s╝%s\n' \
        "$UI_BRIGHT_RED" \
        "$line" \
        "$UI_RESET"

    printf '\n'

    ui_summary

    return 0
}


# ============================================================================
# DEBUG MODE
# ============================================================================

ui_debug() {

    local message="$*"

    if [[ "${HAIDER_DEBUG:-false}" != "true" ]]; then
        return 0
    fi

    printf '%s[DEBUG]%s %s\n' \
        "$UI_GRAY" \
        "$UI_RESET" \
        "$message"

    ui_log "DEBUG: $message"

    return 0
}


# ============================================================================
# CLEANUP
# ============================================================================

ui_cleanup() {

    ui_spinner_stop

    ui_log "UI engine cleanup completed."

    return 0
}


# ============================================================================
# MODULE READY
# ============================================================================

ui_log "Haider Ali UI module loaded."

return 0 2>/dev/null || true
