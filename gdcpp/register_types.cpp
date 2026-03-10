#include "register_types.h"

#ifdef GDCPP_GDEXTENSION
#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
using namespace godot;
#elif defined(GDCPP_MODULE)
#include "core/object/class_db.h"
#endif

#include "src/spinning_cube.h"
#include "src/game_main.h"

void initialize_gdcpp_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(SpinningCube);
	GDREGISTER_CLASS(GameMain);
}

void uninitialize_gdcpp_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

#ifdef GDCPP_GDEXTENSION
extern "C" {
GDExtensionBool GDE_EXPORT gdcpp_library_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_gdcpp_module);
	init_obj.register_terminator(uninitialize_gdcpp_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}
}
#endif
