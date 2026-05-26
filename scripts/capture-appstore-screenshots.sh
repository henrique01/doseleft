#!/usr/bin/env bash
#
# capture-appstore-screenshots.sh
#
# Drives App Store screenshot capture against the currently-booted iPhone
# simulator and its paired Apple Watch simulator. Applies a consistent
# 9:41 / full battery / full signal status bar override before each shot.
#
# Usage:
#   ./scripts/capture-appstore-screenshots.sh prep            # apply overrides
#   ./scripts/capture-appstore-screenshots.sh shot <name>     # capture iPhone
#   ./scripts/capture-appstore-screenshots.sh watch-shot <n>  # capture Watch
#   ./scripts/capture-appstore-screenshots.sh status          # print resolved devices
#   ./scripts/capture-appstore-screenshots.sh done            # clear overrides

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IPHONE_OUT="$REPO_ROOT/AppStore/screenshots/iphone-6.9"
WATCH_OUT="$REPO_ROOT/AppStore/screenshots/watch"

mkdir -p "$IPHONE_OUT" "$WATCH_OUT"

# Resolve the booted iPhone simulator UUID.
iphone_uuid() {
  xcrun simctl list devices --json \
    | /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data["devices"].items():
    if "iOS" not in runtime:
        continue
    for d in devices:
        if d.get("state") == "Booted" and "iPhone" in d.get("name", ""):
            print(d["udid"])
            sys.exit(0)
sys.exit(1)
' 2>/dev/null || true
}

# Resolve the booted Apple Watch simulator UUID (any paired watch).
watch_uuid() {
  xcrun simctl list devices --json \
    | /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data["devices"].items():
    if "watchOS" not in runtime:
        continue
    for d in devices:
        if d.get("state") == "Booted":
            print(d["udid"])
            sys.exit(0)
sys.exit(1)
' 2>/dev/null || true
}

require_iphone() {
  local uuid
  uuid="$(iphone_uuid)"
  if [[ -z "$uuid" ]]; then
    echo "error: no booted iPhone simulator found. Boot one from Xcode first." >&2
    exit 1
  fi
  echo "$uuid"
}

require_watch() {
  local uuid
  uuid="$(watch_uuid)"
  if [[ -z "$uuid" ]]; then
    echo "error: no booted Apple Watch simulator found. Boot one from Xcode first." >&2
    exit 1
  fi
  echo "$uuid"
}

cmd_prep() {
  local phone watch
  phone="$(require_iphone)"
  echo "iPhone: $phone"
  xcrun simctl status_bar "$phone" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState discharging \
    --batteryLevel 100 \
    --operatorName ""

  watch="$(watch_uuid || true)"
  if [[ -n "$watch" ]]; then
    echo "Watch:  $watch"
    # simctl status_bar is iOS-only; watchOS rejects it with code 45.
    # Try anyway in case a future Xcode adds support.
    if ! xcrun simctl status_bar "$watch" override --time "9:41" 2>/dev/null; then
      echo "  (watchOS does not support status_bar override — watch shots will show the simulator's real time)"
    fi
  else
    echo "Watch:  (none booted — skipping watch override)"
  fi
  echo "Status bar overrides applied."
}

cmd_status() {
  echo "iPhone: $(iphone_uuid || echo 'none booted')"
  echo "Watch:  $(watch_uuid || echo 'none booted')"
  echo "Output: $IPHONE_OUT"
  echo "        $WATCH_OUT"
}

cmd_shot() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    echo "usage: $0 shot <name>" >&2
    exit 2
  fi
  local phone path
  phone="$(require_iphone)"
  path="$IPHONE_OUT/${name}.png"
  xcrun simctl io "$phone" screenshot "$path"
  echo "saved: $path"
  /usr/bin/sips -g pixelWidth -g pixelHeight "$path" | tail -n 2
}

cmd_watch_shot() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    echo "usage: $0 watch-shot <name>" >&2
    exit 2
  fi
  local watch path
  watch="$(require_watch)"
  path="$WATCH_OUT/${name}.png"
  xcrun simctl io "$watch" screenshot "$path"
  echo "saved: $path"
  /usr/bin/sips -g pixelWidth -g pixelHeight "$path" | tail -n 2
}

cmd_done() {
  local phone watch
  phone="$(iphone_uuid || true)"
  if [[ -n "$phone" ]]; then
    xcrun simctl status_bar "$phone" clear
    echo "cleared iPhone status bar override"
  fi
  watch="$(watch_uuid || true)"
  if [[ -n "$watch" ]]; then
    xcrun simctl status_bar "$watch" clear 2>/dev/null \
      && echo "cleared Watch status bar override" \
      || true
  fi
}

case "${1:-}" in
  prep)        cmd_prep ;;
  status)      cmd_status ;;
  shot)        shift; cmd_shot "$@" ;;
  watch-shot)  shift; cmd_watch_shot "$@" ;;
  done)        cmd_done ;;
  ""|-h|--help)
    sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    ;;
  *)
    echo "unknown command: $1" >&2
    exit 2
    ;;
esac
