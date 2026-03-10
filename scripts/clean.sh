#!/usr/bin/env bash
set -euo pipefail

# ─── gdcpp clean script ──────────────────────────────────────────────
# Usage: clean.sh [all|debug|release]
# ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET="${1:-all}"

clean_debug() {
    echo "--- Cleaning debug build artifacts..."
    rm -f "$PROJECT_ROOT"/project/bin/libgdcpp*
    rm -f "$PROJECT_ROOT"/.sconsign.dblite
    rm -rf "$PROJECT_ROOT"/gdcpp/src/*.o
    rm -rf "$PROJECT_ROOT"/gdcpp/*.o
    echo "  Done."
}

clean_release() {
    echo "--- Cleaning release build artifacts..."
    rm -rf "$PROJECT_ROOT"/build-windows/*
    rm -rf "$PROJECT_ROOT"/build-linux/*
    rm -rf "$PROJECT_ROOT"/build-web/*
    echo "  Done."
}

case "$TARGET" in
    debug)   clean_debug ;;
    release) clean_release ;;
    all)     clean_debug; clean_release ;;
    *)
        echo "ERROR: Unknown target '$TARGET'. Use: all, debug, or release"
        exit 1
        ;;
esac
