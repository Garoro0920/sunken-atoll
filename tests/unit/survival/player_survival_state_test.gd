extends GdUnitTestSuite

## Tests for the PlayerSurvivalState resource.
## Per specs/features/survival_balance.md §3.1.


func _make_state() -> PlayerSurvivalState:
	var s := PlayerSurvivalState.new()
	return s


func _make_balance() -> SurvivalBalance:
	return SurvivalBalance.new()


func test_default_state_is_full_health() -> void:
	var s := _make_state()
	assert_float(s.hp).is_equal_approx(100.0, 1e-5)
	assert_float(s.hunger).is_equal_approx(100.0, 1e-5)
	assert_float(s.thirst).is_equal_approx(100.0, 1e-5)
	assert_float(s.body_temp).is_equal_approx(0.0, 1e-5)
	assert_float(s.oxygen).is_equal_approx(100.0, 1e-5)
	assert_float(s.contamination).is_equal_approx(0.0, 1e-5)
	assert_bool(s.is_diving).is_false()
	assert_bool(s.is_dead()).is_false()


func test_snapshot_round_trip_preserves_values() -> void:
	var s := _make_state()
	s.hp = 47.0
	s.hunger = 23.5
	s.thirst = 60.0
	s.body_temp = -15.5
	s.oxygen = 88.0
	s.contamination = 12.0
	s.is_diving = true
	var snap: Dictionary = s.snapshot()
	var s2 := _make_state()
	s2.apply_snapshot(snap)
	assert_float(s2.hp).is_equal_approx(47.0, 1e-5)
	assert_float(s2.hunger).is_equal_approx(23.5, 1e-5)
	assert_float(s2.thirst).is_equal_approx(60.0, 1e-5)
	assert_float(s2.body_temp).is_equal_approx(-15.5, 1e-5)
	assert_float(s2.oxygen).is_equal_approx(88.0, 1e-5)
	assert_float(s2.contamination).is_equal_approx(12.0, 1e-5)
	assert_bool(s2.is_diving).is_true()


func test_apply_balance_clamping_pulls_values_into_range() -> void:
	var s := _make_state()
	var b := _make_balance()
	s.hp = 999.0  # > max
	s.hunger = -50.0  # < min
	s.body_temp = -500.0  # < min
	s.contamination = 200.0  # > max
	s.apply_balance_clamping(b)
	assert_float(s.hp).is_equal(b.hp_max)
	assert_float(s.hunger).is_equal(b.hunger_min)
	assert_float(s.body_temp).is_equal(b.body_temp_min)
	assert_float(s.contamination).is_equal(b.contamination_max)


func test_is_dead_when_hp_zero() -> void:
	var s := _make_state()
	s.hp = 0.0
	assert_bool(s.is_dead()).is_true()


func test_reset_to_full_restores_everything() -> void:
	var s := _make_state()
	s.hp = 1.0
	s.hunger = 1.0
	s.is_diving = true
	s.reset_to_full()
	assert_float(s.hp).is_equal_approx(100.0, 1e-5)
	assert_float(s.hunger).is_equal_approx(100.0, 1e-5)
	assert_bool(s.is_diving).is_false()
