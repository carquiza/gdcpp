#include "game_main.h"
#include "spinning_cube.h"

void GameMain::_bind_methods() {
}

#ifdef GDCPP_MODULE
void GameMain::_notification(int p_what) {
	if (p_what == NOTIFICATION_READY) {
		_ready();
	}
}
#endif

void GameMain::_ready() {
	// Camera — positioned at (0, 1.5, 3), looking at origin
	Camera3D *camera = memnew(Camera3D);
	camera->look_at_from_position(Vector3(0, 1.5, 3), Vector3(0, 0, 0));
	add_child(camera);

	// Directional light — angled down toward origin
	DirectionalLight3D *light = memnew(DirectionalLight3D);
	light->look_at_from_position(Vector3(2, 4, 2), Vector3(0, 0, 0));
	light->set_shadow(true);
	add_child(light);

	// Environment
	Ref<Environment> env;
	env.instantiate();
	env->set_background(Environment::BG_COLOR);
	env->set_bg_color(Color(0.15, 0.15, 0.2));
	env->set_ambient_source(Environment::AMBIENT_SOURCE_COLOR);
	env->set_ambient_light_color(Color(0.3, 0.3, 0.35));
	env->set_ambient_light_energy(0.5);

	WorldEnvironment *world_env = memnew(WorldEnvironment);
	world_env->set_environment(env);
	add_child(world_env);

	// Spinning cube
	SpinningCube *cube = memnew(SpinningCube);
	cube->set_speed(1.5);
	add_child(cube);
}
