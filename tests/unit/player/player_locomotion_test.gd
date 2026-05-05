extends GdUnitTestSuite

## Pure-function tests for PlayerLocomotion.

const STATE := PlayerLocomotion.LocomotionState


func test_state_above_water_with_floor_is_ground() -> void:
	var s: int = PlayerLocomotion.compute_state(2.0, 0.0, true)
	assert_int(s).is_equal(STATE.GROUND)


func test_state_above_water_no_floor_is_air() -> void:
	var s: int = PlayerLocomotion.compute_state(2.0, 0.0, false)
	assert_int(s).is_equal(STATE.AIR)


func test_state_no_water_field_falls_back_to_ground_air() -> void:
	assert_int(PlayerLocomotion.compute_state(0.0, null, true)).is_equal(STATE.GROUND)
	assert_int(PlayerLocomotion.compute_state(0.0, null, false)).is_equal(STATE.AIR)


func test_state_at_surface_is_swim_surface() -> void:
	# Player at exactly the water surface (within band).
	var s: int = PlayerLocomotion.compute_state(0.0, 0.0, false)
	assert_int(s).is_equal(STATE.SWIM_SURFACE)


func test_state_just_below_surface_is_swim_surface() -> void:
	var s: int = PlayerLocomotion.compute_state(-0.3, 0.0, false)
	assert_int(s).is_equal(STATE.SWIM_SURFACE)


func test_state_well_below_surface_is_diving() -> void:
	var s: int = PlayerLocomotion.compute_state(-2.0, 0.0, false)
	assert_int(s).is_equal(STATE.DIVING)


func test_is_diving_only_for_diving_state() -> void:
	assert_bool(PlayerLocomotion.is_diving(STATE.DIVING)).is_true()
	assert_bool(PlayerLocomotion.is_diving(STATE.SWIM_SURFACE)).is_false()
	assert_bool(PlayerLocomotion.is_diving(STATE.GROUND)).is_false()
	assert_bool(PlayerLocomotion.is_diving(STATE.AIR)).is_false()


func test_ground_velocity_uses_walk_speed() -> void:
	var v: Vector3 = (
		PlayerLocomotion
		. compute_velocity(
			STATE.GROUND,
			Vector3.ZERO,
			Basis.IDENTITY,
			Vector2(0.0, -1.0),  # forward in Godot = -Z
			false,
			false,
			false,
			0.016,
			1.0,
		)
	)
	assert_float(v.z).is_equal_approx(-PlayerLocomotion.WALK_SPEED_MPS, 1e-5)
	assert_float(v.y).is_equal(0.0)


func test_ground_jump_sets_vertical_velocity() -> void:
	var v: Vector3 = PlayerLocomotion.compute_velocity(
		STATE.GROUND, Vector3.ZERO, Basis.IDENTITY, Vector2.ZERO, true, false, false, 0.016, 1.0
	)
	assert_float(v.y).is_equal_approx(PlayerLocomotion.JUMP_VELOCITY_MPS, 1e-5)


func test_air_applies_gravity() -> void:
	var v: Vector3 = PlayerLocomotion.compute_velocity(
		STATE.AIR, Vector3(0, 0, 0), Basis.IDENTITY, Vector2.ZERO, false, false, false, 0.1, 1.0
	)
	assert_float(v.y).is_less(0.0)


func test_swim_surface_dive_down_pushes_down() -> void:
	var v: Vector3 = (
		PlayerLocomotion
		. compute_velocity(
			STATE.SWIM_SURFACE,
			Vector3.ZERO,
			Basis.IDENTITY,
			Vector2.ZERO,
			false,
			true,  # dive down
			false,
			0.016,
			1.0,
		)
	)
	assert_float(v.y).is_less(0.0)


func test_diving_dive_up_pushes_up() -> void:
	var v: Vector3 = (
		PlayerLocomotion
		. compute_velocity(
			STATE.DIVING,
			Vector3.ZERO,
			Basis.IDENTITY,
			Vector2.ZERO,
			false,
			false,
			true,  # surface up
			0.016,
			1.0,
		)
	)
	assert_float(v.y).is_greater(0.0)


func test_speed_scale_reduces_horizontal_velocity() -> void:
	var v_full: Vector3 = (
		PlayerLocomotion
		. compute_velocity(
			STATE.GROUND,
			Vector3.ZERO,
			Basis.IDENTITY,
			Vector2(0.0, -1.0),
			false,
			false,
			false,
			0.016,
			1.0,
		)
	)
	var v_half: Vector3 = (
		PlayerLocomotion
		. compute_velocity(
			STATE.GROUND,
			Vector3.ZERO,
			Basis.IDENTITY,
			Vector2(0.0, -1.0),
			false,
			false,
			false,
			0.016,
			0.5,
		)
	)
	assert_float(v_half.length()).is_less(v_full.length())
