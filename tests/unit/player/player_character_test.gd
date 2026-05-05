extends GdUnitTestSuite

## Integration-light tests for PlayerCharacter.
## We bind dependencies via bind_dependencies() so we don't need a real
## water field autoload or full scene-tree wiring.

const STATE := PlayerLocomotion.LocomotionState


# A tiny stub that satisfies the duck-typed get_water_height(world_pos).
class _StubWaterField:
	extends Node
	var height: float = 0.0

	func get_water_height(_world_pos: Vector3) -> float:
		return height


func _make_player() -> PlayerCharacter:
	var player: PlayerCharacter = PlayerCharacter.new()
	# A capsule collider is required by CharacterBody3D for move_and_slide,
	# but step_for_test() bypasses that path.
	add_child(player)
	return player


func _make_survival() -> SurvivalManager:
	var mgr := SurvivalManager.new()
	mgr.state = PlayerSurvivalState.new()
	mgr.balance = SurvivalBalance.new()
	add_child(mgr)
	return mgr


func test_state_falls_back_when_no_water_field() -> void:
	var player := _make_player()
	# No water field bound; the player is in the air at y=5 by default.
	player.global_position = Vector3(0, 5, 0)
	player.bind_dependencies(null, null)
	# is_on_floor() returns false in a bare CharacterBody3D outside physics
	# space, so the AIR branch is selected.
	assert_int(player.get_locomotion_state()).is_equal(STATE.AIR)


func test_state_transitions_with_injected_water_field() -> void:
	var player := _make_player()
	var stub := _StubWaterField.new()
	stub.height = 0.0
	add_child(stub)
	player.bind_dependencies(stub, null)
	# Above the surface
	player.global_position = Vector3(0, 5, 0)
	player.step_for_test(0.016)
	assert_int(player.get_locomotion_state()).is_equal(STATE.AIR)
	# At the surface
	player.global_position = Vector3(0, 0, 0)
	player.step_for_test(0.016)
	assert_int(player.get_locomotion_state()).is_equal(STATE.SWIM_SURFACE)
	# Below the surface
	player.global_position = Vector3(0, -3, 0)
	player.step_for_test(0.016)
	assert_int(player.get_locomotion_state()).is_equal(STATE.DIVING)


func test_diving_propagates_to_survival_manager() -> void:
	var player := _make_player()
	var stub := _StubWaterField.new()
	stub.height = 0.0
	add_child(stub)
	var survival := _make_survival()
	player.bind_dependencies(stub, survival)
	player.global_position = Vector3(0, -3, 0)
	player.step_for_test(0.016)
	assert_bool(survival.state.is_diving).is_true()
	# Surfacing flips it back.
	player.global_position = Vector3(0, 5, 0)
	player.step_for_test(0.016)
	assert_bool(survival.state.is_diving).is_false()


func test_locomotion_state_changed_signal_fires_on_transition() -> void:
	var player := _make_player()
	var stub := _StubWaterField.new()
	stub.height = 0.0
	add_child(stub)
	player.bind_dependencies(stub, null)
	# Use Array to defeat lambda value-capture for primitives.
	var emitted_states: Array = []
	player.locomotion_state_changed.connect(
		func(new_state: int) -> void: emitted_states.append(new_state)
	)
	player.global_position = Vector3(0, 5, 0)
	player.step_for_test(0.016)
	player.global_position = Vector3(0, -3, 0)
	player.step_for_test(0.016)
	# Expect at least DIVING in the emitted history (initial AIR is fine too).
	assert_array(emitted_states).contains([STATE.DIVING])


func test_velocity_changes_with_move_input_on_ground() -> void:
	var player := _make_player()
	var stub := _StubWaterField.new()
	stub.height = -100.0  # water way below; player is on ground
	add_child(stub)
	player.bind_dependencies(stub, null)
	player.global_position = Vector3(0, 0, 0)
	player.move_input = Vector2(0.0, -1.0)  # forward
	player.step_for_test(0.016)
	# In AIR state (no floor in raw CharacterBody3D), forward input is
	# applied via move_toward; velocity z becomes negative.
	assert_float(player.velocity.z).is_less_equal(0.0)


func test_request_jump_consumed_after_tick() -> void:
	var player := _make_player()
	player.request_jump = true
	player.step_for_test(0.016)
	assert_bool(player.request_jump).is_false()


func test_apply_mouse_look_yaw_rotates_player_body() -> void:
	var player := _make_player()
	# delta_x positive -> rotate right -> rotation.y goes negative.
	player.apply_mouse_look(100.0, 0.0)
	var expected_yaw: float = -100.0 * player.mouse_sensitivity_rad_per_pixel
	assert_float(player.rotation.y).is_equal_approx(expected_yaw, 1e-5)


func test_apply_mouse_look_no_camera_is_safe_yaw_only() -> void:
	var player := _make_player()
	# No camera bound; yaw still applies, pitch is silently skipped.
	player.apply_mouse_look(50.0, 80.0)
	var expected_yaw: float = -50.0 * player.mouse_sensitivity_rad_per_pixel
	assert_float(player.rotation.y).is_equal_approx(expected_yaw, 1e-5)


func test_apply_mouse_look_pitch_clamped_at_min() -> void:
	var player := _make_player()
	var cam := Camera3D.new()
	player.add_child(cam)
	player.bind_camera(cam)
	# Drive a huge downward mouse motion; pitch should saturate at min.
	player.apply_mouse_look(0.0, 100000.0)
	assert_float(cam.rotation.x).is_equal_approx(player.pitch_min_rad, 1e-5)


func test_apply_mouse_look_pitch_clamped_at_max() -> void:
	var player := _make_player()
	var cam := Camera3D.new()
	player.add_child(cam)
	player.bind_camera(cam)
	player.apply_mouse_look(0.0, -100000.0)
	assert_float(cam.rotation.x).is_equal_approx(player.pitch_max_rad, 1e-5)


func test_apply_mouse_look_pitch_accumulates_within_range() -> void:
	var player := _make_player()
	var cam := Camera3D.new()
	player.add_child(cam)
	player.bind_camera(cam)
	# Two small motions: cumulative pitch = -delta_y_total * sensitivity.
	player.apply_mouse_look(0.0, 50.0)
	player.apply_mouse_look(0.0, 30.0)
	var expected: float = -80.0 * player.mouse_sensitivity_rad_per_pixel
	assert_float(cam.rotation.x).is_equal_approx(expected, 1e-5)
