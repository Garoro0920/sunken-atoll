extends GdUnitTestSuite

## Tests for SurvivalManager.
## Per specs/features/survival_balance.md §3.2 / §3.3 / §3.5.


func _make_manager() -> SurvivalManager:
	var mgr: SurvivalManager = SurvivalManager.new()
	mgr.state = PlayerSurvivalState.new()
	mgr.balance = SurvivalBalance.new()
	add_child(mgr)
	return mgr


func test_step_decays_hunger_and_thirst() -> void:
	var mgr: SurvivalManager = _make_manager()
	var initial_hunger: float = mgr.state.hunger
	var initial_thirst: float = mgr.state.thirst
	mgr.step(10.0)  # 10 game-minutes
	assert_float(mgr.state.hunger).is_less(initial_hunger)
	assert_float(mgr.state.thirst).is_less(initial_thirst)


func test_eat_increases_hunger_clamped_to_max() -> void:
	var mgr: SurvivalManager = _make_manager()
	mgr.state.hunger = 80.0
	mgr.eat(50.0)
	assert_float(mgr.state.hunger).is_equal(mgr.balance.hunger_max)


func test_drink_increases_thirst_clamped_to_max() -> void:
	var mgr: SurvivalManager = _make_manager()
	mgr.state.thirst = 50.0
	mgr.drink(30.0)
	assert_float(mgr.state.thirst).is_equal_approx(80.0, 1e-5)


func test_starvation_below_threshold_damages_hp() -> void:
	var mgr: SurvivalManager = _make_manager()
	mgr.state.hunger = 0.0  # below lethal threshold
	mgr.state.hp = 100.0
	mgr.step(10.0)
	assert_float(mgr.state.hp).is_less(100.0)


func test_dehydration_below_threshold_damages_hp() -> void:
	var mgr: SurvivalManager = _make_manager()
	mgr.state.thirst = 0.0
	mgr.state.hp = 100.0
	mgr.step(10.0)
	assert_float(mgr.state.hp).is_less(100.0)


func test_diving_consumes_oxygen() -> void:
	var mgr: SurvivalManager = _make_manager()
	mgr.set_diving(true)
	var initial_oxygen: float = mgr.state.oxygen
	mgr.step(1.0)
	assert_float(mgr.state.oxygen).is_less(initial_oxygen)


func test_oxygen_recovers_when_not_diving() -> void:
	var mgr: SurvivalManager = _make_manager()
	mgr.state.oxygen = 50.0
	mgr.set_diving(false)
	mgr.step(1.0)
	assert_float(mgr.state.oxygen).is_greater(50.0)


func test_oxygen_zero_drowns_player() -> void:
	var mgr: SurvivalManager = _make_manager()
	mgr.set_diving(true)
	mgr.state.oxygen = 0.0
	mgr.state.hp = 100.0
	mgr.step(1.0)
	# Drown damage is large per spec; expect significant HP loss
	assert_float(mgr.state.hp).is_less(100.0)


func test_contamination_above_lethal_damages_hp() -> void:
	var mgr: SurvivalManager = _make_manager()
	mgr.state.contamination = mgr.balance.contamination_lethal_threshold + 5.0
	mgr.state.hp = 100.0
	mgr.step(10.0)
	assert_float(mgr.state.hp).is_less(100.0)


func test_player_died_signal_fires_when_hp_hits_zero() -> void:
	var mgr: SurvivalManager = _make_manager()
	# Use Array to defeat lambda value-capture for primitives.
	var died_count: Array = [0]
	mgr.player_died.connect(func() -> void: died_count[0] += 1)
	mgr.state.hp = 1.0
	mgr.take_damage(50.0)
	assert_int(died_count[0]).is_equal(1)


func test_lethal_threshold_crossed_emits_once_per_dip() -> void:
	var mgr: SurvivalManager = _make_manager()
	var crossings: Array = []
	mgr.lethal_threshold_crossed.connect(func(zone: String) -> void: crossings.append(zone))
	mgr.state.hunger = 0.0  # below lethal
	mgr.step(1.0)
	mgr.step(1.0)  # still starving — should NOT re-emit
	mgr.eat(100.0)  # restores above threshold
	mgr.step(1.0)  # hunger now decayed but still above threshold
	mgr.state.hunger = 0.0  # second dip
	mgr.step(1.0)  # re-emit
	assert_int(crossings.count("starvation")).is_equal(2)


func test_clamping_keeps_stats_within_bounds_after_step() -> void:
	var mgr: SurvivalManager = _make_manager()
	mgr.state.hp = -50.0
	mgr.state.contamination = 999.0
	mgr.step(1.0)
	assert_float(mgr.state.hp).is_greater_equal(mgr.balance.hp_min)
	assert_float(mgr.state.contamination).is_less_equal(mgr.balance.contamination_max)


func test_bind_world_updates_subscribed_clock() -> void:
	var mgr: SurvivalManager = _make_manager()
	var clock: TimeOfDay = TimeOfDay.new()
	clock.seconds_per_game_hour = 60.0
	add_child(clock)
	var weather: Weather = Weather.new()
	add_child(weather)
	mgr.bind_world(clock, weather)
	# Trigger a minute_changed via clock.advance and confirm step was called
	# by observing state mutation.
	var prev_hunger: float = mgr.state.hunger
	clock.advance(60.0)  # 1 game-minute
	# advance() emits minute_changed which calls step(1.0)
	assert_float(mgr.state.hunger).is_less(prev_hunger)
