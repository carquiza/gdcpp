#pragma once

#include "gdcpp.h"

#ifdef GDCPP_GDEXTENSION
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/directional_light3d.hpp>
#include <godot_cpp/classes/world_environment.hpp>
#include <godot_cpp/classes/environment.hpp>
#elif defined(GDCPP_MODULE)
#include "scene/3d/node_3d.h"
#include "scene/3d/camera_3d.h"
#include "scene/3d/light_3d.h"
#include "scene/3d/world_environment.h"
#include "scene/resources/environment.h"
#endif

class GameMain : public Node3D {
	GDCLASS(GameMain, Node3D);

protected:
	static void _bind_methods();

#ifdef GDCPP_MODULE
	void _notification(int p_what);
#endif

public:
#ifdef GDCPP_GDEXTENSION
	void _ready() override;
#else
	void _ready();
#endif
};
