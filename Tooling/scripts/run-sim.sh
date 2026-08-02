#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: run-sim.sh [--] [launch-arg ...]

Build for the configured simulator, install, and launch the app with optional
process launch arguments (passed through to the app).

Examples:
  just run-sim
  just run-sim -- -ShowPaywall
  just run-sim -- -ScreenshotPhase allClear
EOF
}

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --) shift; ARGS+=("$@"); break ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

SCHEME="$(scheme_name)"
[[ -n "$SCHEME" ]] || { echo "scheme missing — set Tooling/runtime.yml scheme" >&2; exit 1; }

PROJ="$(find_xcodeproj)"
WS="$(find_xcworkspace)"
DEST="$(destination_spec)"
SIM="$(sim_name)"

BUNDLE_ID="$(bundle_id_for_scheme)" || {
  echo "could not resolve PRODUCT_BUNDLE_IDENTIFIER for scheme $SCHEME" >&2
  exit 1
}

DERIVED="$(mktemp -d "${TMPDIR:-/tmp}/harness-run-sim.XXXXXX")"
cleanup() { rm -rf "$DERIVED"; }
trap cleanup EXIT

XB_ARGS=(-scheme "$SCHEME" -destination "$DEST" -configuration Debug -derivedDataPath "$DERIVED" build)
if [[ -n "$WS" ]]; then
  XB_ARGS=(-workspace "$WS" "${XB_ARGS[@]}")
elif [[ -n "$PROJ" ]]; then
  XB_ARGS=(-project "$PROJ" "${XB_ARGS[@]}")
else
  echo "no .xcodeproj / .xcworkspace found" >&2
  exit 1
fi

echo "run-sim: build $SCHEME → $SIM"
if have xcbeautify; then
  xcodebuild "${XB_ARGS[@]}" | xcbeautify
else
  xcodebuild "${XB_ARGS[@]}"
fi

APP_PATH="$(find "$DERIVED/Build/Products" -name "*.app" -type d | head -n 1 || true)"
[[ -n "$APP_PATH" ]] || { echo "no .app produced under $DERIVED" >&2; exit 1; }

UDID="$(
  xcrun simctl list devices available -j 2>/dev/null \
    | /usr/bin/python3 -c "
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)
for devices in data.get('devices', {}).values():
    for d in devices:
        if d.get('name') == name and d.get('isAvailable', True):
            print(d['udid'])
            raise SystemExit(0)
" "$SIM" 2>/dev/null || true
)"

echo "run-sim: boot simulator $SIM"
if [[ -n "$UDID" ]]; then
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b
else
  xcrun simctl boot "$SIM" 2>/dev/null || true
fi
open -a Simulator 2>/dev/null || true

TARGET="${UDID:-booted}"
echo "run-sim: install $APP_PATH"
xcrun simctl install "$TARGET" "$APP_PATH"

echo "run-sim: launch $BUNDLE_ID ${ARGS[*]:-}"
if [[ ${#ARGS[@]} -gt 0 ]]; then
  xcrun simctl launch "$TARGET" "$BUNDLE_ID" "${ARGS[@]}"
else
  xcrun simctl launch "$TARGET" "$BUNDLE_ID"
fi

echo "run-sim OK"
