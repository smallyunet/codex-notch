#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${1:-${DIST_DIR:-$ROOT_DIR/dist}}"

cd "$ROOT_DIR"

"$ROOT_DIR/scripts/check_contracts.sh"
swift test
RUN_TESTS=0 "$ROOT_DIR/scripts/build_app.sh" "$DIST_DIR"
"$ROOT_DIR/scripts/verify_app.sh" "$DIST_DIR/CodexNotch.app"

echo "Full verification passed: $DIST_DIR/CodexNotch.app"
