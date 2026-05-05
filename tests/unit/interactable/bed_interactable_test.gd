extends GdUnitTestSuite

## Tests for BedInteractable.


# Test double exposing get_survival_manager().
class _ActorWithSurvival:
	extends Node
	var survival: SurvivalManager

	func _init(survival_mgr: SurvivalManager) -> void:
		survival = survival_mgr

	func get_survival_manager() -> SurvivalManager:
		return survival


func _make_bed(clock: TimeOfDay) -> BedInteractable:
	var b := BedInteractable.new()
	b.sleep_game_hours = 6
	b.warm_up_amount = 30.0
	add_child(b)
	b.bind_clock(clock)
	return b


func _make_clock() -> TimeOfDay:
	var clock := TimeOfDay.new()
	clock.seconds_per_game_hour = 60.0
	add_child(clock)
	return clock


func _make_survival() -> SurvivalManager:
	var mgr := SurvivalManager.new()
	mgr.state = PlayerSurvivalState.new()
	mgr.balance = SurvivalBalance.new()
	add_child(mgr)
	return mgr


func test_use_advances_clock_by_sleep_game_hours() -> void:
	var clock := _make_clock()
	var bed := _make_bed(clock)
	var t_before: float = clock.get_game_time_seconds()
	bed.use(null)
	var t_after: float = clock.get_game_time_seconds()
	assert_float(t_after - t_before).is_equal_approx(6.0 * 3600.0, 1e-3)


func test_use_warms_actor_body_temperature() -> void:
	var clock := _make_clock()
	var bed := _make_bed(clock)
	var survival := _make_survival()
	survival.state.body_temp = -20.0
	var actor := _ActorWithSurvival.new(survival)
	add_child(actor)
	bed.use(actor)
	assert_float(survival.state.body_temp).is_equal_approx(10.0, 1e-3)


func test_slept_signal_reports_duration_and_warmth() -> void:
	var clock := _make_clock()
	var bed := _make_bed(clock)
	var survival := _make_survival()
	var actor := _ActorWithSurvival.new(survival)
	add_child(actor)
	var captured: Array = []
	bed.slept.connect(
		func(_a: Node, advanced: float, warmed: float) -> void: captured.append([advanced, warmed])
	)
	bed.use(actor)
	assert_int(captured.size()).is_equal(1)
	assert_float(captured[0][0]).is_equal_approx(6.0 * 3600.0, 1e-3)
	assert_float(captured[0][1]).is_equal_approx(30.0, 1e-3)


func test_use_without_actor_still_advances_clock() -> void:
	var clock := _make_clock()
	var bed := _make_bed(clock)
	var t_before: float = clock.get_game_time_seconds()
	bed.use(null)
	assert_float(clock.get_game_time_seconds() - t_before).is_equal_approx(6.0 * 3600.0, 1e-3)


func test_disabled_bed_skips_advance_and_warm() -> void:
	var clock := _make_clock()
	var bed := _make_bed(clock)
	var survival := _make_survival()
	survival.state.body_temp = 0.0
	var actor := _ActorWithSurvival.new(survival)
	add_child(actor)
	bed.enabled = false
	var t_before: float = clock.get_game_time_seconds()
	bed.use(actor)
	assert_float(clock.get_game_time_seconds()).is_equal(t_before)
	assert_float(survival.state.body_temp).is_equal(0.0)
