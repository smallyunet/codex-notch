#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_NAME="CodexNotch"
CONFIGURATION="${CONFIGURATION:-release}"
DIST_DIR="${1:-${DIST_DIR:-$ROOT_DIR/dist}}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
RUN_TESTS="${RUN_TESTS:-1}"
ARCHITECTURES="${ARCHITECTURES:-}"

cd "$ROOT_DIR"

if [[ "$RUN_TESTS" == "1" ]]; then
    swift test
fi

BUILD_ARGS=(-c "$CONFIGURATION" --product "$PRODUCT_NAME")
if [[ -n "$ARCHITECTURES" ]]; then
    read -r -a ARCHITECTURE_LIST <<< "$ARCHITECTURES"
    for ARCHITECTURE in "${ARCHITECTURE_LIST[@]}"; do
        BUILD_ARGS+=(--arch "$ARCHITECTURE")
    done
fi

swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
BIN_PATH="$BIN_DIR/$PRODUCT_NAME"
APP_PATH="$DIST_DIR/$PRODUCT_NAME.app"

if [[ ! -x "$BIN_PATH" ]]; then
    echo "error: built executable not found at $BIN_PATH" >&2
    exit 1
fi

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp "$BIN_PATH" "$APP_PATH/Contents/MacOS/$PRODUCT_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
"$ROOT_DIR/scripts/build_icon.sh" "$APP_PATH/Contents/Resources/CodexNotch.icns"

if [[ "$SIGN_IDENTITY" != "none" ]]; then
    if [[ "$SIGN_IDENTITY" == "-" ]]; then
        codesign --force --options runtime --timestamp=none --sign "$SIGN_IDENTITY" "$APP_PATH"
    else
        codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_PATH"
    fi
fi

echo "Built: $APP_PATH"
