extends GdUnitTestSuite

## Unit tests for TimeOfDay autoload class.
## Tests instantiate TimeOfDay directly (not via autoload) so they
## don't depend on project.godot autoload registration.


func _make_clock() -> TimeOfDay:
	var clock: TimeOfDay = TimeOfDay.new()
	clock.seconds_per_game_hour = 60.0
	clock.tide_period_game_sec = 100.0
	clock.tide_amplitude_m = 2.0
	add_child(clock)
	return clock


func test_initial_state() -> void:
	var clock: TimeOfDay = _make_clock()
	assert_int(clock.get_hour()).is_equal(0)
	assert_int(clock.get_minute()).is_equal(0)
	assert_int(clock.get_day()).is_equal(0)
	assert_int(clock.get_phase()).is_equal(TimeOfDay.Phase.NIGHT)
	clock.queue_free()


func test_advance_one_hour() -> void:
	var clock: TimeOfDay = _make_clock()
	clock.advance(3600.0)
	assert_int(clock.get_hour()).is_equal(1)
	assert_int(clock.get_minute()).is_equal(0)
	clock.queue_free()


func test_phase_transitions_through_day() -> void:
	var clock: TimeOfDay = _make_clock()
	# 5:00 = DAWN
	clock.set_game_time_seconds(5.0 * 3600.0)
	assert_int(clock.get_phase()).is_equal(TimeOfDay.Phase.DAWN)
	# 7:00 = DAY
	clock.set_game_time_seconds(7.0 * 3600.0)
	assert_int(clock.get_phase()).is_equal(TimeOfDay.Phase.DAY)
	# 17:00 = DUSK
	clock.set_game_time_seconds(17.0 * 3600.0)
	assert_int(clock.get_phase()).is_equal(TimeOfDay.Phase.DUSK)
	# 19:00 = NIGHT
	clock.set_game_time_seconds(19.0 * 3600.0)
	assert_int(clock.get_phase()).is_equal(TimeOfDay.Phase.NIGHT)
	# 23:00 still NIGHT
	clock.set_game_time_seconds(23.0 * 3600.0)
	assert_int(clock.get_phase()).is_equal(TimeOfDay.Phase.NIGHT)
	clock.queue_free()


func test_minute_signal_emits_on_minute_boundary() -> void:
	var clock: TimeOfDay = _make_clock()
	var emitted: Array = []
	clock.minute_changed.connect(func(h: int, m: int) -> void: emitted.append([h, m]))
	# Note: advance() emits at most once per call; cross two boundaries
	# via two separate calls.
	clock.advance(60.0)
	clock.advance(60.0)
	assert_int(emitted.size()).is_equal(2)
	clock.queue_free()


func test_phase_signal_emits_on_phase_transition() -> void:
	var clock: TimeOfDay = _make_clock()
	var emitted: Array = []
	clock.phase_changed.connect(func(p: int) -> void: emitted.append(p))
	# Jump from NIGHT (0:00) to DAWN (5:00)
	clock.set_game_time_seconds(0.0)
	clock.advance(5.0 * 3600.0 + 1.0)
	assert_array(emitted).contains([TimeOfDay.Phase.DAWN])
	clock.queue_free()


func test_set_game_time_resets_internal_memo() -> void:
	var clock: TimeOfDay = _make_clock()
	clock.advance(60.0)  # warm internal memo
	clock.set_game_time_seconds(0.0)
	# After reset, the next advance should re-emit minute boundary
	# even though we visually went back to time=0.
	# GDScript lambdas capture int by value; use Array for shared state.
	var counter: Array = [0]
	clock.minute_changed.connect(func(_h: int, _m: int) -> void: counter[0] += 1)
	clock.advance(61.0)
	assert_int(counter[0]).is_greater_equal(1)
	clock.queue_free()


func test_tide_offset_uses_configured_amplitude_and_period() -> void:
	var clock: TimeOfDay = _make_clock()
	# Period = 100 game-sec, quarter cycle = 25 game-sec → +amplitude
	clock.set_game_time_seconds(25.0)
	assert_float(clock.get_tide_offset()).is_equal_approx(2.0, 1e-5)
	clock.queue_free()
