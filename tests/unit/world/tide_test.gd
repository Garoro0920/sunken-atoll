extends GdUnitTestSuite

## Pure-function tests for Tide.
## Per specs/features/day_night_cycle.md §3.4.


func test_offset_is_zero_at_origin() -> void:
	var offset: float = Tide.get_offset(0.0, 100.0, 2.0)
	assert_float(offset).is_equal_approx(0.0, 1e-6)


func test_offset_reaches_positive_amplitude_at_quarter_period() -> void:
	var offset: float = Tide.get_offset(25.0, 100.0, 2.0)
	assert_float(offset).is_equal_approx(2.0, 1e-5)


func test_offset_returns_to_zero_at_half_period() -> void:
	var offset: float = Tide.get_offset(50.0, 100.0, 2.0)
	assert_float(offset).is_equal_approx(0.0, 1e-5)


func test_offset_reaches_negative_amplitude_at_three_quarter_period() -> void:
	var offset: float = Tide.get_offset(75.0, 100.0, 2.0)
	assert_float(offset).is_equal_approx(-2.0, 1e-5)


func test_offset_is_periodic() -> void:
	var a: float = Tide.get_offset(33.3, 100.0, 2.0)
	var b: float = Tide.get_offset(33.3 + 100.0, 100.0, 2.0)
	assert_float(a).is_equal_approx(b, 1e-5)


func test_zero_period_returns_zero() -> void:
	assert_float(Tide.get_offset(50.0, 0.0, 2.0)).is_equal(0.0)


func test_seconds_to_next_high_at_origin() -> void:
	# At t=0 with period 100, high tide is at t=25.
	assert_float(Tide.seconds_to_next_high(0.0, 100.0)).is_equal_approx(25.0, 1e-5)


func test_seconds_to_next_low_at_origin() -> void:
	# At t=0 with period 100, low tide is at t=75.
	assert_float(Tide.seconds_to_next_low(0.0, 100.0)).is_equal_approx(75.0, 1e-5)


func test_seconds_to_next_high_wraps_after_quarter() -> void:
	# At t=30 (past first high at 25), next high is one full period later.
	var seconds: float = Tide.seconds_to_next_high(30.0, 100.0)
	assert_float(seconds).is_equal_approx(95.0, 1e-5)
