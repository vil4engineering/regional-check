#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
# shellcheck source=capabilities.sh
source "$SCRIPT_DIR/capabilities.sh"

if ! cfg_bool tests true; then
  echo "tests skipped (runtime.yml tests: false)"
  exit 0
fi

BACKEND="$(select_build_backend)"
echo "test backend: $BACKEND"

case "$BACKEND" in
  xcode_tools)
    exec "$RUNTIME_ROOT/backend/build/xcode_tools/test.sh"
    ;;
  xcodebuild_mcp)
    exec "$RUNTIME_ROOT/backend/build/mcp/test.sh"
    ;;
  swiftpm)
    exec "$RUNTIME_ROOT/backend/build/swiftpm/test.sh"
    ;;
  xcodebuild|*)
    exec "$RUNTIME_ROOT/backend/build/xcodebuild/test.sh"
    ;;
esac
