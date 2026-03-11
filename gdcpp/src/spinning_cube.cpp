#include "spinning_cube.h"

void SpinningCube::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_speed", "speed"), &SpinningCube::set_speed);
	ClassDB::bind_method(D_METHOD("get_speed"), &SpinningCube::get_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "speed"), "set_speed", "get_speed");
}

#ifdef GDCPP_MODULE
void SpinningCube::_notification(int p_what) {
	MeshInstance3D::_notification(p_what);

	switch (p_what) {
		case NOTIFICATION_READY:
			_ready();
			break;
		case NOTIFICATION_PROCESS:
			_process(get_process_delta_time());
			break;
	}
}
#endif

void SpinningCube::set_speed(double p_speed) {
	speed = p_speed;
}

double SpinningCube::get_speed() const {
	return speed;
}

void SpinningCube::_ready() {
	Ref<BoxMesh> box;
	box.instantiate();
	box->set_size(Vector3(1.0, 1.0, 1.0));

	Ref<StandardMaterial3D> mat;
	mat.instantiate();
	mat->set_albedo(Color(0.2, 0.4, 0.9));

	box->set_material(mat);
	set_mesh(box);
	set_process(true);
}

void SpinningCube::_process(double p_delta) {
	rotate_y(speed * p_delta);
}
