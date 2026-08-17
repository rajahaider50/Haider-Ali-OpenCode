#!/usr/bin/env bash
#
# ubuntu.sh — Ubuntu container engines for stages 04–06.
#
# run_in_ubuntu executes a shell command inside the Ubuntu container with
# the Android storage bind, without keeping an interactive shell open.

run_in_ubuntu() {
  log_command "RUN_IN_UBUNTU: $*"
  proot-distro login "$UBUNTU_NAME" --bind "$UBUNTU_STORAGE_BIND" -- bash -c "$*"
  return $?
}

cmd_04_ubuntu() {
  local state
  state=$(ubuntu_detect_state)
  ui_info "Ubuntu container state: $state"
  case "$state" in
    HEALTHY)
      ui_success "Ubuntu is already installed and healthy — skipping install."
      return 0
      ;;
    NOT_INSTALLED)
      if ! check_network; then
        ui_error "Network is unavailable — cannot install Ubuntu."
        recovery_set_hint "network"
        return 1
      fi
      ui_info "Installing the Ubuntu container (may take several minutes)..."
      recovery_set_hint "package"
      run_command "proot-distro install ubuntu" proot-distro install ubuntu || return 1
      state=$(ubuntu_detect_state)
      case "$state" in
        HEALTHY)
          ui_success "Ubuntu installed and verified healthy."
          return 0
          ;;
        BUSY)
          ui_warn "Ubuntu installed but the container is currently busy."
          recovery_set_hint "ubuntu_busy"
          return 1
          ;;
        *)
          ui_error "Ubuntu install finished but the container reports state: $state."
          recovery_set_hint "ubuntu_broken"
          return 1
          ;;
      esac
      ;;
    BUSY)
      ui_warn "Ubuntu container is BUSY — NOT attempting a second install."
      recovery_set_hint "ubuntu_busy"
      return 1
      ;;
    BROKEN)
      ui_warn "Ubuntu container is present but reports BROKEN/INCOMPLETE."
      ui_warn "Running a safe health re-check (no destructive recovery is automatic)."
      sleep "$RECOVERY_RETRY_DELAY"
      if [ "$(ubuntu_detect_state)" = "HEALTHY" ]; then
        ui_success "Ubuntu recovered and is healthy."
        return 0
      fi
      ui_error "Ubuntu remains unhealthy after a safe re-check."
      recovery_set_hint "ubuntu_broken"
      return 1
      ;;
    NO_PROOT)
      ui_error "proot-distro is required before Ubuntu can be installed."
      recovery_set_hint "missing_command"
      return 1
      ;;
    *)
      ui_error "Ubuntu state is UNKNOWN — stopping to avoid unsafe actions."
      recovery_set_hint "unknown"
      return 1
      ;;
  esac
}

cmd_05_ubuntu_login() {
  local state
  state=$(ubuntu_detect_state)
  if [ "$state" != "HEALTHY" ]; then
    ui_error "Cannot establish the Ubuntu login — state is $state."
    if [ "$state" = "BUSY" ]; then
      recovery_set_hint "ubuntu_busy"
    else
      recovery_set_hint "unknown"
    fi
    return 1
  fi
  ui_info "Verifying Ubuntu login with storage bind ($UBUNTU_STORAGE_BIND)..."
  if ! run_in_ubuntu 'test -d '"$UBUNTU_STORAGE_DEST"; then
    ui_error "Storage bind target '$UBUNTU_STORAGE_DEST' is not visible inside Ubuntu."
    recovery_set_hint "permission"
    return 1
  fi
  ui_success "Ubuntu login and storage bind verified."
  return 0
}

cmd_06_ubuntu_update() {
  local state
  state=$(ubuntu_detect_state)
  if [ "$state" != "HEALTHY" ]; then
    ui_error "Cannot update Ubuntu — container state is $state."
    if [ "$state" = "BUSY" ]; then
      recovery_set_hint "ubuntu_busy"
    else
      recovery_set_hint "unknown"
    fi
    return 1
  fi
  if ! check_network; then
    ui_error "Network is unavailable — cannot update Ubuntu."
    recovery_set_hint "network"
    return 1
  fi
  ui_info "Updating Ubuntu package indexes..."
  run_command "apt update (ubuntu)" run_in_ubuntu 'export DEBIAN_FRONTEND=noninteractive; apt-get update -y' || return 1
  ui_info "Upgrading Ubuntu packages..."
  run_command "apt upgrade (ubuntu)" run_in_ubuntu 'export DEBIAN_FRONTEND=noninteractive; apt-get upgrade -y' || return 1
  ui_success "Ubuntu packages are up to date."
  return 0
}
