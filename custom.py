# custom.py — Godot SCons build profile for release builds.
# Strips GDScript, advanced GUI, and unused modules for a smaller binary.
# Usage: scons custom_modules=<path> profile=<path-to-this-file> ...
#
# Alternatively, this is auto-loaded when placed in the Godot source root
# or passed via: scons --profile=custom.py

# Build as export template (no editor)
target = "template_release"

# Disable deprecated compatibility code
deprecated = "no"

# Disable GDScript — all logic is C++
module_gdscript_enabled = "no"

# Disable advanced GUI (RichTextLabel, GraphEdit, Tree, CodeEdit, etc.)
disable_advanced_gui = "yes"

# Disable C# support
module_mono_enabled = "no"

# Use fallback text server (no ICU/HarfBuzz — saves ~5MB)
module_text_server_adv_enabled = "no"

# Disable unused modules
module_camera_enabled = "no"
module_csg_enabled = "no"
module_gridmap_enabled = "no"
module_noise_enabled = "no"
module_openxr_enabled = "no"
module_mobile_vr_enabled = "no"
module_multiplayer_enabled = "no"
module_enet_enabled = "no"
module_websocket_enabled = "no"
module_webrtc_enabled = "no"
module_webxr_enabled = "no"
module_upnp_enabled = "no"
module_jsonrpc_enabled = "no"
module_theora_enabled = "no"
module_vorbis_enabled = "no"
module_ogg_enabled = "no"
module_svg_enabled = "no"
module_interactive_music_enabled = "no"
module_xatlas_unwrap_enabled = "no"
