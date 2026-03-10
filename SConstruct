#!/usr/bin/env python
"""
GDExtension build (debug mode).
Builds the gdcpp library as a shared library that Godot loads at runtime.
"""

import os

env = SConscript("godot-cpp/SConstruct")

# Add our include paths
env.Append(CPPPATH=["gdcpp/include/", "gdcpp/"])
env.Append(CPPDEFINES=["GDCPP_GDEXTENSION"])

# Gather sources
sources = Glob("gdcpp/src/*.cpp") + Glob("gdcpp/register_types.cpp")

# Build shared library
if env["platform"] == "macos":
    library = env.SharedLibrary(
        "project/bin/libgdcpp.{}.{}.framework/libgdcpp.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )
elif env["platform"] == "ios":
    library = env.StaticLibrary(
        "project/bin/libgdcpp.{}.{}.a".format(env["platform"], env["target"]),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "project/bin/libgdcpp{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

env.NoCache(library)
Default(library)
