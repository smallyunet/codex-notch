#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-}"
if [[ -z "$APP_PATH" ]]; then
    echo "usage: $0 /path/to/CodexNotch.app" >&2
    exit 2
fi

EXECUTABLE="$APP_PATH/Contents/MacOS/CodexNotch"
INFO_PLIST="$APP_PATH/Contents/Info.plist"

[[ -d "$APP_PATH" ]] || { echo "error: app not found: $APP_PATH" >&2; exit 1; }
[[ -x "$EXECUTABLE" ]] || { echo "error: executable missing: $EXECUTABLE" >&2; exit 1; }
[[ -f "$INFO_PLIST" ]] || { echo "error: Info.plist missing: $INFO_PLIST" >&2; exit 1; }

plutil -lint "$INFO_PLIST"
codesign --verify --deep --strict "$APP_PATH"
echo "Verified: $APP_PATH"
