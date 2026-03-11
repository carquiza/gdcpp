#!/usr/bin/env bash
set -euo pipefail

# ─── gdcpp run script ────────────────────────────────────────────────
# Usage: run.sh [debug|release] [windows|linux|web]
#
# Debug:   Launches the project with the Godot editor/runtime
# Release: Launches the standalone built binary (or HTTP server for web)
# ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:-debug}"
PLATFORM="${2:-}"

# Auto-detect platform if not specified
if [ -z "$PLATFORM" ]; then
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*|*_NT*) PLATFORM="windows" ;;
        Linux*)                      PLATFORM="linux" ;;
        Darwin*)                     PLATFORM="macos" ;;
        *)                           PLATFORM="unknown" ;;
    esac
fi

if [ "$MODE" = "debug" ]; then

    # Find Godot binary
    GODOT=""
    if [ -n "${GODOT_BIN:-}" ] && [ -x "$GODOT_BIN" ]; then
        GODOT="$GODOT_BIN"
    elif [ -n "${GODOT_SOURCE:-}" ]; then
        # Try to find an editor build in the Godot source bin/
        for candidate in "$GODOT_SOURCE"/bin/godot*editor*; do
            if [ -x "$candidate" ]; then
                GODOT="$candidate"
                break
            fi
        done
    fi

    if [ -z "$GODOT" ]; then
        echo "ERROR: Cannot find Godot binary."
        echo "  Set GODOT_BIN to the path of the Godot editor binary,"
        echo "  or set GODOT_SOURCE (with editor build in bin/)."
        exit 1
    fi

    echo "=== Running debug with: $GODOT ==="
    "$GODOT" --path "$PROJECT_ROOT/project"

elif [ "$MODE" = "release" ]; then

    # Web builds are served via HTTP
    if [ "$PLATFORM" = "web" ]; then
        WEB_DIR="$PROJECT_ROOT/build-web/release"
        if [ ! -f "$WEB_DIR/index.html" ]; then
            echo "ERROR: No web release build found in $WEB_DIR/"
            echo "  Run 'scripts/build.sh release web' first."
            exit 1
        fi
        echo "=== Serving web release on http://localhost:8060 ==="
        echo "Press Ctrl+C to stop the server."
        python -m http.server 8060 --directory "$WEB_DIR"
        exit 0
    fi

    BUILD_DIR="$PROJECT_ROOT/build-$PLATFORM"

    case "$PLATFORM" in
        windows)
            BIN=$(ls "$BUILD_DIR"/release/godot.windows.template_release*.exe 2>/dev/null | head -1)
            ;;
        linux)
            BIN=$(ls "$BUILD_DIR"/release/godot.linuxbsd.template_release* 2>/dev/null | head -1)
            ;;
        *)
            echo "ERROR: Release run not supported on $PLATFORM"
            exit 1
            ;;
    esac

    if [ -z "${BIN:-}" ] || [ ! -f "$BIN" ]; then
        echo "ERROR: No release binary found in $BUILD_DIR/release/"
        echo "  Run 'scripts/build.sh release' first."
        exit 1
    fi

    echo "=== Running release: $BIN ==="
    "$BIN" --path "$PROJECT_ROOT/project" --main-pack "$PROJECT_ROOT/project"

else
    echo "ERROR: Unknown mode '$MODE'. Use: debug or release"
    exit 1
fi
