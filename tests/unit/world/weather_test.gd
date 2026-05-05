extends GdUnitTestSuite

## Unit tests for Weather autoload class.
## Tests inject a TimeOfDay clock so they don't depend on autoload registration.


func _make_clock() -> TimeOfDay:
	var clock: TimeOfDay = TimeOfDay.new()
	clock.seconds_per_game_hour = 60.0
	add_child(clock)
	return clock


func _make_weather(seed_value: int) -> Weather:
	var weather: Weather = Weather.new()
	weather.deterministic_seed = seed_value
	add_child(weather)  # _ready runs here, RNG is seeded
	weather.bind_clock(_make_clock())
	return weather


func test_initial_state_is_clear() -> void:
	var weather: Weather = _make_weather(42)
	assert_int(weather.current_weather).is_equal(Weather.WeatherKind.CLEAR)


func test_seeded_run_is_deterministic() -> void:
	# Two independently seeded runs must produce the same sequence
	# of weather changes after the same number of ticks.
	var run_a: Array = _collect_changes(_make_weather(123), 200)
	var run_b: Array = _collect_changes(_make_weather(123), 200)
	assert_array(run_a).is_equal(run_b)


func test_different_seeds_diverge() -> void:
	var run_a: Array = _collect_changes(_make_weather(1), 500)
	var run_b: Array = _collect_changes(_make_weather(999_999), 500)
	# Not requiring full divergence in every position; just that the
	# sequences are not identical (extremely unlikely with 500 steps).
	assert_bool(run_a == run_b).is_false()


func test_storm_started_signal_fires_only_once_per_entry() -> void:
	# Force the markov to enter storm by stubbing the transitions table
	# with one that always picks STORM from CLEAR.
	var weather: Weather = _make_weather(0)
	weather._transitions = {
		Weather.WeatherKind.CLEAR: PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 1.0]),
		Weather.WeatherKind.STORM: PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 1.0]),
	}
	# GDScript lambdas capture local int by value; using an Array gives
	# mutable shared state visible in the outer scope.
	var counter: Array = [0]
	weather.storm_started.connect(func() -> void: counter[0] += 1)
	# Advance several minute boundaries.
	for i in 5:
		weather.tick(float((i + 1) * 60))
	# CLEAR -> STORM happens on first transition; subsequent stays in STORM.
	assert_int(counter[0]).is_equal(1)


func test_wind_changes_with_weather() -> void:
	var weather: Weather = _make_weather(7)
	# Lock the markov to STORM so subsequent ticks do not transition away
	# before we sample wind.
	weather._transitions = {
		Weather.WeatherKind.STORM: PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 1.0]),
	}
	weather._set_weather(Weather.WeatherKind.STORM)
	var wind_event: Array = []
	weather.wind_changed.connect(
		func(dir: Vector2, speed: float) -> void: wind_event.append([dir, speed])
	)
	# wind updates every 60 game-sec
	weather.tick(0.0)
	weather.tick(120.0)
	assert_int(wind_event.size()).is_greater_equal(1)
	# In STORM range = 20..32 m/s
	var last_speed: float = wind_event[wind_event.size() - 1][1]
	assert_float(last_speed).is_greater_equal(20.0)
	assert_float(last_speed).is_less_equal(32.0)


# ----------------------------------------------------------------------
# helpers
# ----------------------------------------------------------------------
func _collect_changes(weather: Weather, ticks: int) -> Array:
	var seen: Array = []
	weather.weather_changed.connect(func(k: int) -> void: seen.append([weather.current_weather, k]))
	for i in ticks:
		weather.tick(float((i + 1) * 60))
	return seen
