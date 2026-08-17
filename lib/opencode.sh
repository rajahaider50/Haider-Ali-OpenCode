#!/usr/bin/env bash
#
# opencode.sh — Node.js and OpenCode engines for stages 07–11.
#
# curl, the NodeSource repository, Node.js and OpenCode AI are installed
# and verified inside the Ubuntu container.

cmd_07_curl() {
  if run_in_ubuntu 'command -v curl >/dev/null 2>&1'; then
    ui_success "curl is already installed inside Ubuntu."
    return 0
  fi
  ui_info "Installing curl inside Ubuntu..."
  recovery_set_hint "package"
  run_command "apt install curl (ubuntu)" run_in_ubuntu 'export DEBIAN_FRONTEND=noninteractive; apt-get install -y curl' || return 1
  if ! run_in_ubuntu 'curl --version >/dev/null 2>&1'; then
    ui_error "curl installation could not be verified."
    return 1
  fi
  ui_success "curl installed and verified inside Ubuntu."
  return 0
}

cmd_08_node_repository() {
  local major v
  if run_in_ubuntu 'command -v node >/dev/null 2>&1'; then
    v=$(run_in_ubuntu 'node --version' 2>/dev/null)
    major=$(node_major_from_version "$v")
    if [ "$major" = "$NODE_MAJOR_VERSION" ]; then
      ui_success "Node.js v$NODE_MAJOR_VERSION is already present — skipping repository setup."
      return 0
    fi
  fi
  ui_info "Verifying the Ubuntu platform and architecture before adding the NodeSource repository..."
  run_in_ubuntu 'cat /etc/os-release 2>/dev/null | grep -E "^(ID|VERSION_ID)=" ; uname -m' || true
  if ! run_in_ubuntu 'command -v curl >/dev/null 2>&1'; then
    ui_error "curl is required to download the NodeSource setup script."
    recovery_set_hint "missing_command"
    return 1
  fi
  ui_info "Downloading the official NodeSource setup script over HTTPS..."
  if ! run_in_ubuntu "curl -fsSL $NODESOURCE_SETUP_URL -o $NODESOURCE_SETUP_TMP"; then
    ui_error "Failed to download the NodeSource setup script."
    recovery_set_hint "network"
    return 1
  fi
  if ! run_in_ubuntu "test -s $NODESOURCE_SETUP_TMP" || ! run_in_ubuntu "grep -q nodesource $NODESOURCE_SETUP_TMP"; then
    ui_error "Downloaded NodeSource script failed validation."
    return 1
  fi
  ui_warn "Executing the official NodeSource setup script for Node.js $NODE_MAJOR_VERSION."
  ui_warn "This is the vendor's own installer — the full script is saved at $NODESOURCE_SETUP_TMP inside Ubuntu for review."
  recovery_set_hint "package"
  run_command "NodeSource setup" run_in_ubuntu "bash $NODESOURCE_SETUP_TMP" || return 1
  ui_success "NodeSource repository configured."
  return 0
}

cmd_09_nodejs() {
  local major v
  if run_in_ubuntu 'command -v node >/dev/null 2>&1'; then
    v=$(run_in_ubuntu 'node --version' 2>/dev/null)
    major=$(node_major_from_version "$v")
    ui_secondary "Existing Node.js major version: ${major:-unknown}"
    if [ "$major" = "$NODE_MAJOR_VERSION" ]; then
      ui_success "Node.js v$NODE_MAJOR_VERSION is already installed — skipping."
      run_in_ubuntu 'npm --version >/dev/null 2>&1' || { ui_error "npm is not available."; return 1; }
      return 0
    fi
    ui_warn "Installed Node ($major) does not match required major ($NODE_MAJOR_VERSION) — installing v$NODE_MAJOR_VERSION."
  fi
  ui_info "Installing Node.js v$NODE_MAJOR_VERSION inside Ubuntu..."
  recovery_set_hint "package"
  run_command "apt install nodejs (ubuntu)" run_in_ubuntu 'export DEBIAN_FRONTEND=noninteractive; apt-get install -y nodejs' || return 1
  v=$(run_in_ubuntu 'node --version' 2>/dev/null)
  major=$(node_major_from_version "$v")
  if [ "$major" != "$NODE_MAJOR_VERSION" ]; then
    ui_error "Node.js major version mismatch — expected $NODE_MAJOR_VERSION, got ${major:-unknown}."
    return 1
  fi
  ui_success "Node.js v$NODE_MAJOR_VERSION installed and verified."
  if ! run_in_ubuntu 'npm --version >/dev/null 2>&1'; then
    ui_error "npm is not available after Node.js installation."
    return 1
  fi
  ui_success "npm is available inside Ubuntu."
  return 0
}

cmd_10_opencode() {
  if ! run_in_ubuntu 'command -v npm >/dev/null 2>&1'; then
    ui_error "npm is required but is not available inside Ubuntu."
    return 1
  fi
  if run_in_ubuntu 'command -v opencode >/dev/null 2>&1'; then
    ui_success "OpenCode AI is already installed — verifying version."
    if ! run_in_ubuntu 'opencode --version >/dev/null 2>&1'; then
      ui_error "opencode binary exists but --version failed."
      return 1
    fi
    run_in_ubuntu 'opencode --version' 2>/dev/null || true
    return 0
  fi
  if ! check_network; then
    ui_error "Network is unavailable — cannot install OpenCode."
    recovery_set_hint "network"
    return 1
  fi
  ui_info "Installing $OPENCODE_PACKAGE globally via npm..."
  recovery_set_hint "package"
  run_command "npm install opencode-ai" run_in_ubuntu "npm install -g $OPENCODE_PACKAGE" || return 1
  if ! run_in_ubuntu 'command -v opencode >/dev/null 2>&1'; then
    ui_error "opencode binary was not found after installation."
    return 1
  fi
  if ! run_in_ubuntu 'opencode --version >/dev/null 2>&1'; then
    ui_error "opencode --version failed after installation."
    return 1
  fi
  ui_success "OpenCode AI installed and verified inside Ubuntu."
  return 0
}

cmd_11_launch() {
  local state
  state=$(ubuntu_detect_state)
  if [ "$state" != "HEALTHY" ]; then
    ui_error "Ubuntu is not healthy (state: $state) — refusing to launch OpenCode."
    return 1
  fi
  if ! run_in_ubuntu 'command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && command -v opencode >/dev/null 2>&1'; then
    ui_error "node, npm or opencode is missing inside Ubuntu — refusing to launch."
    return 1
  fi
  ui_success "Final environment verification passed."
  ui_final_success_screen
  log_result "LAUNCHING opencode inside $UBUNTU_NAME"
  ui_info "Launching OpenCode AI (exit opencode to return to Termux)..."
  printf '\n'
  # shellcheck disable=SC2016 # TERM expands inside the Ubuntu login shell on purpose
  proot-distro login "$UBUNTU_NAME" --bind "$UBUNTU_STORAGE_BIND" -- bash -c 'export TERM="${TERM:-xterm-256color}"; exec opencode'
  return $?
}
