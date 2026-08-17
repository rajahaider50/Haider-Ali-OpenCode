#!/usr/bin/env bash
#
# ui.sh — Professional terminal UI and Haider Ali branding.
#
# Colours are stored as ANSI escape sequences and rendered through
# printf '%b' so the terminal receives real escape bytes — never a literal
# backslash-033 string.
#
# Palette:
#   GREEN  = success      RED    = failure
#   YELLOW = warning      CYAN   = information
#   BLUE   = headers      GRAY   = secondary information

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
GRAY='\033[1;90m'
RESET='\033[0m'

BOX_INNER_WIDTH=58
BOX_SIDES='║'
BOX_TOP_BORDER=''
BOX_BOTTOM_BORDER=''

ui_init() {
  if [ "${ENABLE_COLORS:-true}" != "true" ] || { [ ! -t 1 ] && [ "${FORCE_COLORS:-false}" != "true" ]; }; then
    GREEN=''
    RED=''
    YELLOW=''
    CYAN=''
    BLUE=''
    GRAY=''
    RESET=''
  fi
  BOX_TOP_BORDER=$(printf '╔%*s╗' "$BOX_INNER_WIDTH" "" | tr ' ' '═')
  BOX_BOTTOM_BORDER=$(printf '╚%*s╝' "$BOX_INNER_WIDTH" "" | tr ' ' '═')
}

ui_color() {
  local color="$1"
  shift
  printf '%b%s%b\n' "$color" "$*" "$RESET"
}

ui_info()      { log_info "$*";      ui_color "$CYAN"   "→ $*"; }
ui_success()   { log_info "$*";      ui_color "$GREEN"  "✓ $*"; }
ui_warn()      { log_warn "$*";      ui_color "$YELLOW" "⚠ $*"; }
ui_error()     { log_error "$*";     ui_color "$RED"    "✗ $*" >&2; }
ui_secondary() { ui_color "$GRAY" "$*"; }

ui_header() {
  printf '%b\n' "$BLUE"
  printf '================================================\n'
  printf '%s\n' "$*"
  printf '================================================\n'
  printf '%b\n' "$RESET"
}

ui_border() {
  local color="$1" edge="$2"
  if [ "$edge" = "top" ]; then
    printf '%b%s%b\n' "$color" "$BOX_TOP_BORDER" "$RESET"
  else
    printf '%b%s%b\n' "$color" "$BOX_BOTTOM_BORDER" "$RESET"
  fi
}

ui_box_line() {
  local color="$1"
  shift
  local text="$1"
  local len left right
  len=${#text}
  if [ "$len" -gt "$BOX_INNER_WIDTH" ]; then
    text="${text:0:$((BOX_INNER_WIDTH - 1))}…"
    len=${#text}
  fi
  left=$(( (BOX_INNER_WIDTH - len) / 2 ))
  right=$(( BOX_INNER_WIDTH - len - left ))
  printf '%b%s%*s%s%*s%s%b\n' "$color" "$BOX_SIDES" "$left" "" "$text" "$right" "" "$BOX_SIDES" "$RESET"
}

ui_banner() {
  printf '\n'
  ui_border "$BLUE" top
  ui_box_line "$BLUE" ""
  ui_box_line "$BLUE" "HAIDER ALI • OPENCODE SYSTEM"
  ui_box_line "$BLUE" ""
  ui_box_line "$BLUE" "PROFESSIONAL INSTALLER"
  ui_box_line "$BLUE" ""
  ui_box_line "$BLUE" "Version $APP_VERSION"
  ui_box_line "$BLUE" ""
  ui_border "$BLUE" bottom
  printf '\n'
}

ui_stage_begin() {
  local number="$1" total="$2" name="$3"
  log_step "BEGIN STAGE $number/$total: $name"
  printf '\n'
  printf '%b[%02d/%02d] %s%b\n' "$BLUE" "$number" "$total" "$name" "$RESET"
  printf '%b%s%b\n' "$GRAY" "----------------------------------------" "$RESET"
}

ui_stage_end() {
  local result="$1" name="$2" exit_code="$3" duration="$4"
  if [ "$result" = "pass" ]; then
    ui_success "PASS — $name"
    log_result "PASS: $name (exit=$exit_code, duration=${duration}s)"
  else
    ui_error "FAIL — $name"
    log_result "FAIL: $name (exit=$exit_code, duration=${duration}s)"
  fi
  ui_secondary "Completed in ${duration}s"
  printf '\n'
}

ui_final_success_screen() {
  printf '\n'
  ui_border "$GREEN" top
  ui_box_line "$GREEN" "INSTALLATION COMPLETE"
  ui_box_line "$GREEN" ""
  ui_box_line "$GREEN" "Haider Ali OpenCode System is ready."
  ui_box_line "$GREEN" ""
  ui_box_line "$GREEN" "Node.js and OpenCode AI are installed"
  ui_box_line "$GREEN" "inside the Ubuntu container."
  ui_box_line "$GREEN" ""
  ui_box_line "$GREEN" "Launching OpenCode AI now..."
  ui_border "$GREEN" bottom
  printf '\n'
}

ui_abort_screen() {
  local code="$1"
  printf '\n'
  ui_border "$RED" top
  ui_box_line "$RED" "INSTALLATION STOPPED"
  ui_box_line "$RED" ""
  ui_box_line "$RED" "A stage could not complete safely."
  ui_box_line "$RED" "Last exit code: $code"
  ui_box_line "$RED" "Classification: ${RECOVERY_LAST_CLASS:-unknown}"
  ui_box_line "$RED" ""
  ui_box_line "$RED" "Log file:"
  ui_box_line "$RED" "${LOG_FILE:-logging disabled}"
  ui_border "$RED" bottom
  printf '\n'
}
