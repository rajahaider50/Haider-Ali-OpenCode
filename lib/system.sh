#!/usr/bin/env bash
#
# system.sh — Termux engines for stages 01–03.
#
# These functions wrap the original Termux commands (pkg, termux-setup-
# storage) behind check → install-if-needed → verify logic.

cmd_01_termux_update() {
  if ! check_pkg; then
    ui_error "pkg is not available — the Termux package engine cannot run."
    recovery_set_hint "missing_command"
    return 1
  fi
  if ! check_network; then
    ui_error "Network is unavailable — cannot update Termux packages."
    recovery_set_hint "network"
    return 1
  fi
  ui_info "Updating Termux package indexes..."
  run_command "pkg update" pkg update -y || return 1
  ui_info "Upgrading Termux packages..."
  run_command "pkg upgrade" pkg upgrade -y || return 1
  ui_success "Termux packages are up to date."
  return 0
}

cmd_02_proot() {
  if check_proot_distro; then
    ui_success "proot-distro is already installed."
    local v
    v=$(proot-distro --version 2>&1) || v="unknown"
    ui_secondary "proot-distro version: $v"
    return 0
  fi
  if ! check_network; then
    ui_error "Network is unavailable — cannot install proot-distro."
    recovery_set_hint "network"
    return 1
  fi
  ui_info "Installing proot-distro..."
  recovery_set_hint "package"
  run_command "pkg install proot-distro" pkg install proot-distro -y || return 1
  if ! check_proot_distro; then
    ui_error "proot-distro installation could not be verified."
    return 1
  fi
  ui_success "proot-distro installed and verified."
  return 0
}

cmd_03_storage() {
  if check_storage; then
    ui_success "Android shared storage is already accessible."
    return 0
  fi
  if ! command -v termux-setup-storage >/dev/null 2>&1; then
    ui_error "termux-setup-storage is not available."
    recovery_set_hint "missing_command"
    return 1
  fi
  ui_warn "Requesting Android storage access — accept the system permission prompt."
  run_command "termux-setup-storage" termux-setup-storage || return 1
  sleep 2
  if ! check_storage; then
    ui_error "Shared storage is still not accessible after setup."
    recovery_set_hint "permission"
    return 1
  fi
  ui_success "Android shared storage is accessible."
  return 0
}
