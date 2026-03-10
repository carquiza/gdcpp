#pragma once

#include "gdcpp.h"

class SpinningCube : public MeshInstance3D {
	GDCLASS(SpinningCube, MeshInstance3D);

	double speed = 1.0;

protected:
	static void _bind_methods();

#ifdef GDCPP_MODULE
	void _notification(int p_what);
#endif

public:
	void set_speed(double p_speed);
	double get_speed() const;

#ifdef GDCPP_GDEXTENSION
	void _ready() override;
	void _process(double p_delta) override;
#else
	void _ready();
	void _process(double p_delta);
#endif
};
