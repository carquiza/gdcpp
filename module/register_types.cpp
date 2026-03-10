#include "register_types.h"
#include "core/object/class_db.h"

// Include game classes — paths relative to Godot source root
// (SCsub adds the gdcpp include path)
#include "spinning_cube.h"
#include "game_main.h"

void initialize_module_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(SpinningCube);
	GDREGISTER_CLASS(GameMain);
}

void uninitialize_module_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}
