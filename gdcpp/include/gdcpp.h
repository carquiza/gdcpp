#pragma once

/*
 * gdcpp.h — Abstraction layer for dual-mode builds.
 *
 * When GDCPP_GDEXTENSION is defined (debug builds via godot-cpp):
 *   - Uses godot-cpp headers and godot:: namespace
 *
 * When GDCPP_MODULE is defined (release builds as Godot module):
 *   - Uses Godot internal headers, no namespace prefix
 *
 * Detection is automatic based on whether godot_cpp headers are available.
 * The SConstruct / SCsub files define the appropriate macro.
 */

#ifdef GDCPP_GDEXTENSION

// ── GDExtension mode (godot-cpp) ──────────────────────────────────────

#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/vector3.hpp>

using namespace godot;

#elif defined(GDCPP_MODULE)

// ── Module mode (Godot internal) ──────────────────────────────────────

#include "core/object/class_db.h"
#include "core/math/color.h"
#include "core/math/vector3.h"
#include "scene/3d/mesh_instance_3d.h"
#include "scene/resources/3d/primitive_meshes.h"
#include "scene/resources/material.h"

#else
#error "Define GDCPP_GDEXTENSION or GDCPP_MODULE before including gdcpp.h"
#endif
