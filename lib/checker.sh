#!/usr/bin/env bash
#
# checker.sh — System detection and state checks.
#
# A component is only reported as healthy when its binary exists AND a basic
# runtime probe succeeds. State detection uses the real tools, never guesses.

check_termux() {
  [ -n "${PREFIX:-}" ] || return 1
  [ -d "$PREFIX" ] || return 1
  command -v pkg >/dev/null 2>&1 || return 1
  return 0
}

check_android() {
  command -v getprop >/dev/null 2>&1 || return 1
  return 0
}

check_architecture() {
  uname -m 2>/dev/null
}

check_network() {
  if command -v curl >/dev/null 2>&1; then
    if curl -fsS --connect-timeout 8 --max-time 12 -o /dev/null https://deb.nodesource.com 2>/dev/null; then
      return 0
    fi
    if curl -fsS --connect-timeout 8 --max-time 12 -o /dev/null https://github.com 2>/dev/null; then
      return 0
    fi
  fi
  if command -v ping >/dev/null 2>&1; then
    if ping -c 1 -W 6 8.8.8.8 >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

check_storage() {
  [ -d "/storage/emulated/0" ] || return 1
  [ -r "/storage/emulated/0" ] || return 1
  return 0
}

check_pkg() {
  command -v pkg >/dev/null 2>&1 || return 1
  return 0
}

check_proot_distro() {
  command -v proot-distro >/dev/null 2>&1 || return 1
  return 0
}

check_curl() {
  command -v curl >/dev/null 2>&1 || return 1
  return 0
}

check_node() {
  command -v node >/dev/null 2>&1 || return 1
  node --version >/dev/null 2>&1 || return 1
  return 0
}

check_npm() {
  command -v npm >/dev/null 2>&1 || return 1
  npm --version >/dev/null 2>&1 || return 1
  return 0
}

check_opencode() {
  command -v opencode >/dev/null 2>&1 || return 1
  opencode --version >/dev/null 2>&1 || return 1
  return 0
}

node_major_from_version() {
  printf '%s\n' "${1#v}" | cut -d. -f1
}

# ubuntu_detect_state prints one of:
#   NO_PROOT | NOT_INSTALLED | INSTALLED | HEALTHY | BUSY | BROKEN | UNKNOWN
# The container is never considered healthy just because it is listed;
# a login probe with a real command must succeed.
ubuntu_detect_state() {
  if ! command -v proot-distro >/dev/null 2>&1; then
    printf '%s\n' "NO_PROOT"
    return 0
  fi

  local list_out rc out
  list_out=$(proot-distro list 2>/dev/null)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    printf '%s\n' "UNKNOWN"
    return 0
  fi

  if ! printf '%s\n' "$list_out" | grep -Eq '(^|[[:space:]])'"$UBUNTU_NAME"'([[:space:]]|$)'; then
    printf '%s\n' "NOT_INSTALLED"
    return 0
  fi

  if command -v timeout >/dev/null 2>&1; then
    out=$(timeout "${UBUNTU_HEALTH_TIMEOUT}" proot-distro login "$UBUNTU_NAME" -- /bin/true 2>&1)
  else
    out=$(proot-distro login "$UBUNTU_NAME" -- /bin/true 2>&1)
  fi
  rc=$?

  # A busy container is a distinct state, not a generic proot failure.
  if printf '%s' "$out" | grep -qi "is busy"; then
    printf '%s\n' "BUSY"
    return 0
  fi

  if [ "$rc" -eq 0 ]; then
    printf '%s\n' "HEALTHY"
  else
    printf '%s\n' "BROKEN"
  fi
}
