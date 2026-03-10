# gdcpp — C++17 Template for Godot 4.5.1

## Overview

gdcpp is a project template for writing Godot games in C++17 with two build modes:

- **Debug**: Compiles game code as a **GDExtension** shared library (.dll/.so/.wasm) loaded by the standard Godot editor/runtime. Enables fast iteration — edit code, rebuild the extension, re-run.
- **Release**: Compiles game code as a **Godot module** linked directly into the engine, producing a **single executable** with GDScript support stripped out and advanced GUI disabled for a smaller binary.

Both modes use the same game source code. A thin abstraction layer (`gdcpp.h`) handles API differences via preprocessor macros.

## Target Platforms (Initial)

| Platform | Debug Output              | Release Output                |
|----------|--------------------------|-------------------------------|
| Windows  | `build-windows/*.dll`    | `build-windows/godot.windows.template_release.x86_64.exe` |
| Linux    | `build-linux/*.so`       | `build-linux/godot.linuxbsd.template_release.x86_64`      |
| Web      | `build-web/*.wasm`       | `build-web/godot.web.template_release.wasm32.nothreads.*`  |

Future: iOS, Android.

## Environment Requirements

| Variable       | Description                        | Required |
|---------------|------------------------------------|----------|
| `GODOT_SOURCE` | Path to Godot 4.5.1 source tree   | Release builds only |
| `GODOT_BIN`    | Path to Godot editor binary        | Debug runs only (falls back to `$GODOT_SOURCE/bin/godot*`) |

### Toolchain

- **SCons** >= 4.0 (build system for both modes)
- **Python** >= 3.8
- **C++17 compiler**: MSVC (Windows), GCC/Clang (Linux), Emscripten 3.1+ (Web)
- **Git** (for submodule management)

## Project Structure

```
gdcpp/
├── .gitmodules                     # godot-cpp submodule reference
├── .gitignore
├── SConstruct                      # GDExtension build (debug mode)
├── custom.py                       # Godot SCons profile for release builds
│
├── gdcpp/                          # Game/library source code
│   ├── include/
│   │   └── gdcpp.h                 # Abstraction macros (GDExtension vs module)
│   ├── register_types.cpp          # Dual-mode class registration
│   ├── register_types.h
│   └── src/
│       ├── spinning_cube.h         # Sample: SpinningCube node
│       └── spinning_cube.cpp
│
├── module/                         # Godot module glue for release builds
│   ├── SCsub                       # Tells Godot SCons what to compile
│   ├── config.py                   # Module detection/config
│   ├── register_types.cpp          # Module entry points
│   └── register_types.h
│
├── godot-cpp/                      # Git submodule (pinned to 4.5 branch)
│
├── project/                        # Sample Godot project
│   ├── project.godot
│   ├── default_bus_layout.tres
│   ├── main.tscn                   # Scene: Camera + Light + SpinningCube
│   ├── icon.svg
│   └── bin/
│       └── gdcpp.gdextension       # GDExtension descriptor (debug mode)
│
├── scripts/
│   ├── build.sh                    # build.sh [debug|release] [windows|linux|web]
│   ├── run.sh                      # run.sh [debug|release]
│   └── clean.sh                    # clean.sh [all|debug|release]
│
├── build-windows/                  # Build outputs (gitignored)
├── build-linux/
└── build-web/
```

## Build Modes in Detail

### Debug Mode (GDExtension)

**What happens:**
1. `scripts/build.sh debug` auto-inits the `godot-cpp` submodule if needed.
2. SCons builds `godot-cpp` bindings library.
3. SCons compiles `gdcpp/` source against godot-cpp headers.
4. Output shared library is placed in `project/bin/` for the editor to pick up.
5. The `.gdextension` file tells Godot where to find the library per-platform.

**Preprocessor state:** `GDCPP_GDEXTENSION` is defined.

**Headers used:** `godot-cpp` headers (`godot_cpp/classes/...`).

### Release Mode (Godot Module)

**What happens:**
1. `scripts/build.sh release` validates `$GODOT_SOURCE` points to Godot 4.5.1.
2. SCons is invoked on the Godot source tree with:
   - `custom_modules=<absolute-path-to-gdcpp/module>` — registers our module
   - `target=template_release` — export template (no editor)
   - `custom.py` — feature stripping profile
3. The module's `SCsub` compiles all files from `gdcpp/src/` and `gdcpp/register_types.cpp`.
4. Output is a single self-contained binary in `build-<platform>/`.

**Preprocessor state:** `GDCPP_MODULE` is defined (automatically, since godot-cpp headers are absent).

**Headers used:** Godot internal headers (`scene/3d/mesh_instance_3d.h`, etc.).

## Feature Stripping (Release)

The `custom.py` profile disables unnecessary features to minimize binary size:

```python
# Build target
target = "template_release"
deprecated = "no"

# Disable GDScript — all logic is C++
module_gdscript_enabled = "no"

# Disable advanced GUI (RichTextLabel, GraphEdit, Tree, etc.)
disable_advanced_gui = "yes"

# Disable unused modules
module_mono_enabled = "no"             # C# support
module_text_server_adv_enabled = "no"  # ICU/HarfBuzz (keep text_server_fb)
module_camera_enabled = "no"           # Camera server
module_csg_enabled = "no"              # CSG geometry
module_gridmap_enabled = "no"          # GridMap
module_noise_enabled = "no"            # FastNoiseLite
module_openxr_enabled = "no"           # VR/XR
module_mobile_vr_enabled = "no"        # Mobile VR
module_multiplayer_enabled = "no"      # High-level multiplayer
module_enet_enabled = "no"             # ENet networking
module_websocket_enabled = "no"        # WebSocket
module_webrtc_enabled = "no"           # WebRTC
module_webxr_enabled = "no"            # WebXR
module_upnp_enabled = "no"            # UPnP
module_jsonrpc_enabled = "no"          # JSON-RPC
module_theora_enabled = "no"           # Theora video
module_vorbis_enabled = "no"           # Vorbis audio
module_ogg_enabled = "no"             # Ogg container
module_svg_enabled = "no"              # SVG rendering
module_interactive_music_enabled = "no" # Interactive music
module_xatlas_unwrap_enabled = "no"    # UV unwrapping
```

This typically reduces the binary by 30–50%.

## Abstraction Layer (`gdcpp.h`)

The abstraction layer handles the differences between GDExtension and module APIs:

### Class Declaration

```cpp
#include "gdcpp.h"

class SpinningCube : public GDCPP_CLASS(MeshInstance3D) {
    GDCLASS(SpinningCube, MeshInstance3D)  // Works in both modes

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void _process(double delta) override;
};
```

### Key Differences Handled

| Concern              | GDExtension (godot-cpp)           | Module (internal)                  |
|---------------------|-----------------------------------|------------------------------------|
| Include path        | `godot_cpp/classes/mesh_instance_3d.hpp` | `scene/3d/mesh_instance_3d.h` |
| Namespace           | `godot::`                         | (global)                           |
| Registration        | `ClassDB::bind_method()`          | `ClassDB::bind_method()`           |
| Entry point         | `GDExtensionBool GDE_EXPORT ...`  | `register_<module>_types()`        |
| String literals     | Same (`String("...")`)            | Same                               |

The macros in `gdcpp.h` primarily handle include paths and namespace differences. The actual class APIs (ClassDB, Variant, etc.) are intentionally very similar between the two modes.

## Build Scripts

### `scripts/build.sh`

```
Usage: build.sh [debug|release] [windows|linux|web]

  debug   — Build GDExtension shared library (default)
  release — Build Godot with game code as embedded module

Platform defaults to current OS if not specified.
```

**Behavior:**
- Validates required tools are in PATH (scons, python, git; emcc for web)
- For debug: runs `git submodule update --init` if godot-cpp is empty
- For release: validates `$GODOT_SOURCE` and checks Godot version matches 4.5.1
- Invokes SCons with appropriate flags
- Copies output to `build-<platform>/`

### `scripts/run.sh`

```
Usage: run.sh [debug|release]

  debug   — Launch project with Godot editor/runtime (uses $GODOT_BIN)
  release — Launch the built standalone binary
```

### `scripts/clean.sh`

```
Usage: clean.sh [all|debug|release]

Removes build artifacts. Does not remove godot-cpp submodule.
```

## Sample Project

The `project/` directory contains a minimal Godot 4.5.1 project demonstrating the template:

**Scene: `main.tscn`**
- `Node3D` (root)
  - `Camera3D` — positioned at (0, 1.5, 3), looking at origin
  - `DirectionalLight3D` — angled to light the cube
  - `WorldEnvironment` — basic sky environment
  - `SpinningCube` — custom C++ node (extends MeshInstance3D)

**SpinningCube behavior:**
- `_ready()`: Creates a `BoxMesh` (1x1x1) and assigns a `StandardMaterial3D` (blue, with lighting)
- `_process(delta)`: Rotates around Y axis at a configurable speed
- Exposes `speed` property to the editor via `_bind_methods()`

## Platform-Specific Notes

### Windows
- Debug: Outputs `.dll` (MSVC or MinGW)
- Release: Outputs `.exe` (MSVC recommended for size)
- Compiler: MSVC 2019+ or MinGW-w64 with C++17 support

### Linux
- Debug: Outputs `.so`
- Release: Outputs ELF binary
- Compiler: GCC 9+ or Clang 10+

### Web (Emscripten)
- Both modes produce `.wasm` + `.js` glue
- Requires Emscripten 3.1+ (C++17 support)
- Release uses `dlink_enabled=no` (static linking)
- No threads variant by default (`threads=no`) for broadest browser compatibility
