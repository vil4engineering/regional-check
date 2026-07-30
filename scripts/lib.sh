#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export RUNTIME_ROOT="${RUNTIME_ROOT:-$ROOT}"

have() { command -v "$1" >/dev/null 2>&1; }

runtime_config_path() {
  if [[ -f "$PWD/runtime.yml" ]]; then
    echo "$PWD/runtime.yml"
  elif [[ -f "$RUNTIME_ROOT/templates/runtime.yml" ]]; then
    echo "$RUNTIME_ROOT/templates/runtime.yml"
  else
    echo ""
  fi
}

cfg_get() {
  local key="$1"
  local default="${2:-}"
  local file
  file="$(runtime_config_path)"
  if [[ -z "$file" ]]; then
    echo "$default"
    return 0
  fi
  if have yq; then
    local v
    v="$(yq -r ".$key // \"\"" "$file" 2>/dev/null || true)"
    if [[ -f "$PWD/runtime.local.yml" ]]; then
      local lv
      lv="$(yq -r ".$key // \"\"" "$PWD/runtime.local.yml" 2>/dev/null || true)"
      if [[ -n "$lv" && "$lv" != "null" ]]; then
        v="$lv"
      fi
    fi
    if [[ -z "$v" || "$v" == "null" ]]; then
      echo "$default"
    else
      echo "$v"
    fi
  else
    echo "$default"
  fi
}

cfg_bool() {
  local key="$1"
  local default="${2:-true}"
  local v
  v="$(cfg_get "$key" "$default")"
  case "$v" in
    true|True|TRUE|yes|1) return 0 ;;
    *) return 1 ;;
  esac
}

project_root() {
  echo "${PROJECT_ROOT:-$PWD}"
}

find_xcodeproj() {
  local root
  root="$(project_root)"
  local explicit
  explicit="$(cfg_get project "")"
  if [[ -n "$explicit" && -e "$root/$explicit" ]]; then
    echo "$root/$explicit"
    return 0
  fi
  local found
  found="$(find "$root" -maxdepth 2 -name '*.xcodeproj' ! -path '*/.*' 2>/dev/null | head -n 1 || true)"
  echo "$found"
}

find_xcworkspace() {
  local root
  root="$(project_root)"
  local explicit
  explicit="$(cfg_get workspace "")"
  if [[ -n "$explicit" && -e "$root/$explicit" ]]; then
    echo "$root/$explicit"
    return 0
  fi
  local found
  found="$(find "$root" -maxdepth 2 -name '*.xcworkspace' ! -path '*/.*' ! -path '*.xcodeproj/*' 2>/dev/null | head -n 1 || true)"
  echo "$found"
}

scheme_name() {
  local s
  s="$(cfg_get scheme "")"
  if [[ -n "$s" ]]; then
    echo "$s"
    return 0
  fi
  local proj
  proj="$(find_xcodeproj)"
  if [[ -n "$proj" ]]; then
    basename "$proj" .xcodeproj
    return 0
  fi
  echo ""
}

sim_name() {
  cfg_get "simulator.name" "iPhone 17"
}

sim_os() {
  cfg_get "simulator.os" ""
}

destination_spec() {
  local name os
  name="$(sim_name)"
  os="$(sim_os)"
  if [[ -n "$os" ]]; then
    echo "platform=iOS Simulator,name=${name},OS=${os}"
  else
    echo "platform=iOS Simulator,name=${name}"
  fi
}

harness_version() {
  if [[ -f "$RUNTIME_ROOT/HARNESS_VERSION" ]]; then
    tr -d '[:space:]' <"$RUNTIME_ROOT/HARNESS_VERSION"
  elif [[ -f "$PWD/.harness-version" ]]; then
    tr -d '[:space:]' <"$PWD/.harness-version"
  else
    echo "0.0.0"
  fi
}
