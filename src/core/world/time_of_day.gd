class_name TimeOfDay
extends Node

## In-game clock authority.
##
## Per specs/features/day_night_cycle.md §3.1 / §3.2 / §3.7.
## Single source of truth for the current game time. Other systems
## (Weather, Tide computation, lighting) derive from this clock.
##
## Hosted as autoload "WorldClock" (see project.godot [autoload]).
## class_name TimeOfDay is the type for static annotations; the autoload
## key is intentionally different to avoid the "hides an autoload
## singleton" parse error.
## On clients in a multiplayer session the host periodically broadcasts
## the authoritative game time; clients interpolate locally between
## broadcasts (interpolation handled here, broadcast handled by the
## multiplayer layer — wired up in MVP Sprint 1 follow-up).

## Emitted whenever the in-game minute boundary is crossed.
signal minute_changed(game_hour: int, game_minute: int)
## Emitted at each phase transition (dawn / day / dusk / night).
signal phase_changed(new_phase: int)
## Emitted with the latest tide offset every physics tick.
## Subscribers (water shader, buoyancy) consume this directly.
signal tide_offset_changed(offset_m: float)

enum Phase { NIGHT, DAWN, DAY, DUSK }

const SECONDS_PER_GAME_HOUR_DEFAULT: float = 60.0  # 1 real minute = 1 game hour
const PHASE_DAWN_HOUR: int = 5
const PHASE_DAY_HOUR: int = 7
const PHASE_DUSK_HOUR: int = 17
const PHASE_NIGHT_HOUR: int = 19

## Real seconds per game hour. Overridable via WorldSettings later;
## Inspector-editable for ad-hoc tuning.
@export var seconds_per_game_hour: float = SECONDS_PER_GAME_HOUR_DEFAULT
## Tide period in *game* seconds. Default = 12 game-hours.
@export var tide_period_game_sec: float = 12.0 * 3600.0
@export var tide_amplitude_m: float = Tide.DEFAULT_AMPLITUDE_M

var _game_time_seconds: float = 0.0
var _last_emitted_minute: int = -1
var _last_emitted_phase: int = -1


func _process(delta: float) -> void:
	if seconds_per_game_hour <= 0.0:
		return
	var game_seconds_per_real_second: float = 3600.0 / seconds_per_game_hour
	advance(delta * game_seconds_per_real_second)


## Advance the game clock by the given number of *game* seconds.
## Used by _process for normal flow and by tests/save-load for jumps.
func advance(game_seconds: float) -> void:
	if game_seconds <= 0.0:
		return
	_game_time_seconds += game_seconds
	_emit_minute_signal_if_needed()
	_emit_phase_signal_if_needed()
	tide_offset_changed.emit(get_tide_offset())


func get_game_time_seconds() -> float:
	return _game_time_seconds


func set_game_time_seconds(value: float) -> void:
	_game_time_seconds = maxf(0.0, value)
	# Reset memoized signals so the next emit fires with the new state.
	_last_emitted_minute = -1
	_last_emitted_phase = -1


func get_hour() -> int:
	return int(_game_time_seconds / 3600.0) % 24


func get_minute() -> int:
	return int(_game_time_seconds / 60.0) % 60


func get_day() -> int:
	return int(_game_time_seconds / (3600.0 * 24.0))


func get_phase() -> int:
	var hour: int = get_hour()
	if hour >= PHASE_DAY_HOUR and hour < PHASE_DUSK_HOUR:
		return Phase.DAY
	if hour >= PHASE_DAWN_HOUR and hour < PHASE_DAY_HOUR:
		return Phase.DAWN
	if hour >= PHASE_DUSK_HOUR and hour < PHASE_NIGHT_HOUR:
		return Phase.DUSK
	return Phase.NIGHT


func get_tide_offset() -> float:
	return Tide.get_offset(_game_time_seconds, tide_period_game_sec, tide_amplitude_m)


func _emit_minute_signal_if_needed() -> void:
	var current_minute: int = get_minute() + get_hour() * 60 + get_day() * 1440
	if current_minute != _last_emitted_minute:
		_last_emitted_minute = current_minute
		minute_changed.emit(get_hour(), get_minute())


func _emit_phase_signal_if_needed() -> void:
	var current_phase: int = get_phase()
	if current_phase != _last_emitted_phase:
		_last_emitted_phase = current_phase
		phase_changed.emit(current_phase)
