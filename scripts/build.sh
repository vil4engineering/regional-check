#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
# shellcheck source=capabilities.sh
source "$SCRIPT_DIR/capabilities.sh"

BACKEND="$(select_build_backend)"
echo "build backend: $BACKEND"

case "$BACKEND" in
  xcode_tools)
    exec "$RUNTIME_ROOT/backend/build/xcode_tools/build.sh"
    ;;
  xcodebuild_mcp)
    exec "$RUNTIME_ROOT/backend/build/mcp/build.sh"
    ;;
  swiftpm)
    exec "$RUNTIME_ROOT/backend/build/swiftpm/build.sh"
    ;;
  xcodebuild|*)
    exec "$RUNTIME_ROOT/backend/build/xcodebuild/build.sh"
    ;;
esac
