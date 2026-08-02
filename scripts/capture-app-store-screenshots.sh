#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BUNDLE_ID="vil4max.RegionalCheck"
SCHEME="RegionalCheck"
OUT_DIR="$ROOT/release/screenshots/asc"
mkdir -p "$OUT_DIR"

SIM="${SCREENSHOT_SIM:-iPhone 17}"
# ASC «iPhone 6.5" Display» accepted portrait size
HEIGHT=2778
WIDTH=1284

# Status phases render HomeView above TabView (no tab bar).
# "regions" boots MainTabView for the Regions tab shell.
phases=(
  "launch:00-launch"
  "allClear:01-all-clear-kyiv"
  "alertActive:02-alert-active-kharkiv"
  "unavailable:04-unavailable-kyiv"
  "onboarding:05-onboarding-get-started"
  "regions:06-regions-tab"
)

udid="$(xcrun simctl list devices available -j | python3 -c "
import json,sys
name=sys.argv[1]
data=json.load(sys.stdin)
for devices in data.get('devices',{}).values():
  for d in devices:
    if d.get('name')==name and d.get('isAvailable', True):
      print(d['udid']); raise SystemExit
raise SystemExit('missing simulator: '+name)
" "$SIM")"
xcrun simctl boot "$udid" 2>/dev/null || true
echo "Using $SIM ($udid) → ${WIDTH}x${HEIGHT} → $OUT_DIR"

DERIVED="/tmp/regional-check-screenshot-derived"
rm -rf "$DERIVED"

xcodebuild \
  -project RegionalCheck.xcodeproj \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$udid" \
  -derivedDataPath "$DERIVED" \
  -configuration Debug \
  build \
  >/tmp/regional-check-screenshot-build.log

APP="$(find "$DERIVED" -name 'RegionalCheck.app' -type d | head -1)"
if [[ -z "$APP" ]]; then
  echo "Built app not found" >&2
  exit 1
fi

xcrun simctl uninstall "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$udid" "$APP"
xcrun simctl privacy "$udid" grant location "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl privacy "$udid" grant location-always "$BUNDLE_ID" >/dev/null 2>&1 || true

for entry in "${phases[@]}"; do
  phase="${entry%%:*}"
  stem="${entry##*:}"
  raw="/tmp/${stem}-asc-raw.png"
  out="$OUT_DIR/${stem}.png"

  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$udid" "$BUNDLE_ID" -ScreenshotPhase "$phase" >/dev/null
  sleep 2.5
  xcrun simctl io "$udid" screenshot --type=png "$raw"
  sips -z "$HEIGHT" "$WIDTH" "$raw" --out "$out" >/dev/null
  echo "Wrote $out ($(sips -g pixelWidth -g pixelHeight "$out" 2>/dev/null | awk '/pixel/{print $2}' | paste -sd x -))"
done

rm -rf "$DERIVED"
echo "Upload ALL files from $OUT_DIR into ASC «iPhone 6.5\" Display»"
