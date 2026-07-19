#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${1:-${DIST_DIR:-$ROOT_DIR/dist}}"
VERSION="${VERSION:-$(plutil -extract CFBundleShortVersionString raw -o - "$ROOT_DIR/Resources/Info.plist")}"
ARCHIVE_ARCH="${ARCHIVE_ARCH:-$(uname -m)}"
APP_PATH="$DIST_DIR/CodexNotch.app"
ARCHIVE_PATH="$DIST_DIR/CodexNotch-$VERSION-macOS-$ARCHIVE_ARCH.zip"

if [[ -n "${GITHUB_REF_NAME:-}" && "$GITHUB_REF_NAME" != "v$VERSION" ]]; then
    echo "error: tag $GITHUB_REF_NAME does not match app version v$VERSION" >&2
    exit 1
fi

RUN_TESTS="${RUN_TESTS:-1}" \
    "$ROOT_DIR/scripts/build_app.sh" "$DIST_DIR"
"$ROOT_DIR/scripts/verify_app.sh" "$APP_PATH"

rm -f "$ARCHIVE_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"
shasum -a 256 "$ARCHIVE_PATH" | tee "$ARCHIVE_PATH.sha256"
echo "Release archive: $ARCHIVE_PATH"
