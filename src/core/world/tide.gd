class_name Tide
extends RefCounted

## Pure-function tide model.
##
## Per specs/features/day_night_cycle.md §3.4 — tide is a sine wave with
## configurable period and amplitude. Used by:
##   - building_system / boat_navigation: water height for buoyancy
##   - water_shader (uniform tide_offset): visual offset
##   - level scripts: opening/closing of low-tide-only ruins
##
## All methods are static so callers don't depend on a singleton or scene.

const DEFAULT_PERIOD_SEC: float = 12.0 * 60.0  # 12 game-hours @ 60 sec/hour default
const DEFAULT_AMPLITUDE_M: float = 2.0


## Returns the current tide offset (meters above mean sea level).
##   game_time_seconds: monotonic in-game time
##   period_sec:        full-cycle period in game seconds (default 12 game-hours)
##   amplitude_m:       peak deviation from mean (default ±2 m)
static func get_offset(
	game_time_seconds: float,
	period_sec: float = DEFAULT_PERIOD_SEC,
	amplitude_m: float = DEFAULT_AMPLITUDE_M
) -> float:
	if period_sec <= 0.0:
		return 0.0
	var phase: float = (game_time_seconds / period_sec) * TAU
	return amplitude_m * sin(phase)


## Returns seconds until the next high tide (offset = +amplitude).
static func seconds_to_next_high(
	game_time_seconds: float, period_sec: float = DEFAULT_PERIOD_SEC
) -> float:
	if period_sec <= 0.0:
		return 0.0
	# High tide occurs at phase = pi/2 within each cycle.
	var pos_in_cycle: float = fposmod(game_time_seconds, period_sec)
	var quarter: float = period_sec / 4.0
	var seconds_to_quarter: float = quarter - pos_in_cycle
	if seconds_to_quarter <= 0.0:
		seconds_to_quarter += period_sec
	return seconds_to_quarter


## Returns seconds until the next low tide (offset = -amplitude).
static func seconds_to_next_low(
	game_time_seconds: float, period_sec: float = DEFAULT_PERIOD_SEC
) -> float:
	if period_sec <= 0.0:
		return 0.0
	# Low tide occurs at phase = 3*pi/2 within each cycle.
	var pos_in_cycle: float = fposmod(game_time_seconds, period_sec)
	var three_quarter: float = period_sec * 0.75
	var seconds_to_three_quarter: float = three_quarter - pos_in_cycle
	if seconds_to_three_quarter <= 0.0:
		seconds_to_three_quarter += period_sec
	return seconds_to_three_quarter
