#pragma once

#ifdef GDCPP_MODULE
#include "modules/register_module_types.h"
#elif defined(GDCPP_GDEXTENSION)
#include <godot_cpp/godot.hpp>
using namespace godot;
#endif

void initialize_gdcpp_module(ModuleInitializationLevel p_level);
void uninitialize_gdcpp_module(ModuleInitializationLevel p_level);
