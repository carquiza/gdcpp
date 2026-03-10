#!/usr/bin/env bash
set -euo pipefail

# ─── gdcpp build script ──────────────────────────────────────────────
# Usage: build.sh [debug|release] [windows|linux|web]
#
# Debug:   Builds GDExtension shared library via godot-cpp
# Release: Builds single executable via Godot module system
# ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:-debug}"
PLATFORM="${2:-}"

# ─── Auto-detect platform ────────────────────────────────────────────
if [ -z "$PLATFORM" ]; then
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*|*_NT*) PLATFORM="windows" ;;
        Linux*)                      PLATFORM="linux" ;;
        Darwin*)                     PLATFORM="macos" ;;
        *)
            echo "ERROR: Cannot detect platform. Specify: windows, linux, or web"
            exit 1
            ;;
    esac
fi

# Map platform names to Godot/SCons platform identifiers
case "$PLATFORM" in
    windows) SCONS_PLATFORM="windows" ;;
    linux)   SCONS_PLATFORM="linux" ;;
    web)     SCONS_PLATFORM="web" ;;
    *)
        echo "ERROR: Unknown platform '$PLATFORM'. Use: windows, linux, or web"
        exit 1
        ;;
esac

# ─── Validate tools ──────────────────────────────────────────────────
command -v scons >/dev/null 2>&1 || { echo "ERROR: scons not found in PATH"; exit 1; }
command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1 || { echo "ERROR: python not found in PATH"; exit 1; }

if [ "$PLATFORM" = "web" ]; then
    command -v emcc >/dev/null 2>&1 || { echo "ERROR: emcc (Emscripten) not found in PATH"; exit 1; }
fi

# ─── Determine job count ─────────────────────────────────────────────
if command -v nproc >/dev/null 2>&1; then
    JOBS=$(nproc)
elif command -v sysctl >/dev/null 2>&1; then
    JOBS=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
else
    JOBS=$(( $(wmic cpu get NumberOfCores 2>/dev/null | grep -o '[0-9]*' | head -1) )) 2>/dev/null || JOBS=4
fi

echo "=== gdcpp build: mode=$MODE platform=$PLATFORM jobs=$JOBS ==="

BUILD_DIR="$PROJECT_ROOT/build-$PLATFORM"
mkdir -p "$BUILD_DIR"

# ─── Debug build (GDExtension) ───────────────────────────────────────
if [ "$MODE" = "debug" ]; then

    # Auto-init godot-cpp submodule if needed
    if [ ! -f "$PROJECT_ROOT/godot-cpp/SConstruct" ]; then
        echo "--- Initializing godot-cpp submodule..."
        cd "$PROJECT_ROOT"
        git submodule update --init --recursive godot-cpp
    fi

    echo "--- Building GDExtension (debug)..."
    cd "$PROJECT_ROOT"
    scons platform="$SCONS_PLATFORM" target=template_debug -j"$JOBS"

    echo "--- Build complete. Output in project/bin/"

# ─── Release build (Godot module) ────────────────────────────────────
elif [ "$MODE" = "release" ]; then

    # Validate GODOT_SOURCE
    if [ -z "${GODOT_SOURCE:-}" ]; then
        echo "ERROR: GODOT_SOURCE environment variable not set"
        echo "  Set it to the path of your Godot 4.5.1 source tree"
        exit 1
    fi
    if [ ! -f "$GODOT_SOURCE/SConstruct" ]; then
        echo "ERROR: GODOT_SOURCE ($GODOT_SOURCE) does not contain a Godot source tree"
        exit 1
    fi

    # Verify Godot version
    GODOT_MAJOR=$(python -c "exec(open('$GODOT_SOURCE/version.py').read()); print(major)" 2>/dev/null || echo "?")
    GODOT_MINOR=$(python -c "exec(open('$GODOT_SOURCE/version.py').read()); print(minor)" 2>/dev/null || echo "?")
    GODOT_PATCH=$(python -c "exec(open('$GODOT_SOURCE/version.py').read()); print(patch)" 2>/dev/null || echo "?")
    echo "--- Godot source version: $GODOT_MAJOR.$GODOT_MINOR.$GODOT_PATCH"

    MODULE_PATH="$PROJECT_ROOT/module"

    echo "--- Building Godot with gdcpp module (release)..."
    cd "$GODOT_SOURCE"
    scons \
        platform="$SCONS_PLATFORM" \
        profile="$PROJECT_ROOT/custom.py" \
        custom_modules="$MODULE_PATH" \
        -j"$JOBS"

    # Copy output binary to build directory
    echo "--- Copying output to $BUILD_DIR/"
    case "$PLATFORM" in
        windows)
            cp -f "$GODOT_SOURCE"/bin/godot.windows.template_release*.exe "$BUILD_DIR/" 2>/dev/null || true
            ;;
        linux)
            cp -f "$GODOT_SOURCE"/bin/godot.linuxbsd.template_release* "$BUILD_DIR/" 2>/dev/null || true
            ;;
        web)
            cp -f "$GODOT_SOURCE"/bin/godot.web.template_release* "$BUILD_DIR/" 2>/dev/null || true
            ;;
    esac

    echo "--- Release build complete. Output in $BUILD_DIR/"

else
    echo "ERROR: Unknown mode '$MODE'. Use: debug or release"
    exit 1
fi
