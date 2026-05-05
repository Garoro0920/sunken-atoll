class_name Weather
extends Node

## Markov-chain weather + wind authority.
##
## Per specs/features/day_night_cycle.md §3.3 / §3.5 / §3.7.
## Re-evaluates current weather once per game-minute boundary using a
## seeded Markov transition matrix. Storm events emit warning signals
## ahead of time so dependents (boat_navigation, building_system) can
## schedule safe-mode behavior.
##
## Hosted as autoload "WorldWeather" (see project.godot [autoload]).
## Authoritative on the host in multiplayer; clients receive broadcasts.

signal weather_changed(new_weather: int)
signal storm_warning(seconds_until_storm: float)
signal storm_started
signal storm_ended
signal wind_changed(direction: Vector2, speed_mps: float)

enum WeatherKind { CLEAR, CLOUDY, RAIN, FOG, STORM }

const STORM_WARNING_LEAD_GAME_SEC_DEFAULT: float = 7.5 * 60.0  # 7.5 game-minutes
const WIND_UPDATE_INTERVAL_GAME_SEC: float = 60.0  # update every game-minute

@export var storm_warning_lead_game_sec: float = STORM_WARNING_LEAD_GAME_SEC_DEFAULT
@export var deterministic_seed: int = 0xA70771  ## Set by host before session

var current_weather: int = WeatherKind.CLEAR
var wind_direction: Vector2 = Vector2(1, 0)
var wind_speed_mps: float = 3.0

var _rng: RandomNumberGenerator
var _transitions: Dictionary = _default_transition_matrix()
var _time_of_day: TimeOfDay = null
var _storm_warning_emitted_for_storm_at: float = -1.0
var _last_processed_minute: int = -1
var _next_wind_update_game_sec: float = 0.0
## Cached so tests can inject without depending on autoload registration.
var _injected_clock: TimeOfDay = null


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = deterministic_seed
	_resolve_clock()


## Tests inject a clock instance directly so they don't need the autoload.
func bind_clock(clock: TimeOfDay) -> void:
	_injected_clock = clock
	_resolve_clock()


func _resolve_clock() -> void:
	if _injected_clock != null:
		_time_of_day = _injected_clock
		return
	# Autoload registers under "WorldClock" (see project.godot [autoload]).
	# class_name TimeOfDay is the type, autoload key is WorldClock to avoid
	# the "hides an autoload singleton" parse-error.
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		_time_of_day = tree.root.get_node_or_null("WorldClock") as TimeOfDay


func _process(_delta: float) -> void:
	if _time_of_day == null:
		return
	tick(_time_of_day.get_game_time_seconds())


## Public so unit tests can drive the system without a SceneTree process loop.
func tick(now_game_sec: float) -> void:
	_check_minute_transition(now_game_sec)
	_maybe_emit_storm_warning(now_game_sec)
	_maybe_update_wind(now_game_sec)


func _check_minute_transition(now_game_sec: float) -> void:
	var current_minute: int = int(now_game_sec / 60.0)
	if current_minute == _last_processed_minute:
		return
	_last_processed_minute = current_minute
	_advance_weather_one_step()


func _advance_weather_one_step() -> void:
	var probs: PackedFloat32Array = _transitions[current_weather]
	var roll: float = _rng.randf()
	var cumulative: float = 0.0
	for kind in probs.size():
		cumulative += probs[kind]
		if roll <= cumulative:
			if kind != current_weather:
				_set_weather(kind)
			return
	# Numerical fallback (should never hit if rows sum to 1.0).
	_set_weather(probs.size() - 1)


func _set_weather(new_weather: int) -> void:
	var was_storm: bool = current_weather == WeatherKind.STORM
	var is_storm: bool = new_weather == WeatherKind.STORM
	current_weather = new_weather
	weather_changed.emit(new_weather)
	if is_storm and not was_storm:
		storm_started.emit()
	if was_storm and not is_storm:
		storm_ended.emit()
		_storm_warning_emitted_for_storm_at = -1.0


func _maybe_emit_storm_warning(now_game_sec: float) -> void:
	if current_weather == WeatherKind.STORM:
		return
	# Look ahead one minute: if next sample WOULD be a storm, warn.
	# We can't predict markov, so we emit warning when conditions are
	# ripe (e.g. CLOUDY + wind > threshold). Keeping deterministic and
	# auditable is more important than predicting markov in this MVP.
	var probable_storm: bool = current_weather == WeatherKind.CLOUDY and wind_speed_mps > 18.0
	if not probable_storm:
		return
	var warn_at: float = now_game_sec + storm_warning_lead_game_sec
	if absf(warn_at - _storm_warning_emitted_for_storm_at) < 1.0:
		return
	_storm_warning_emitted_for_storm_at = warn_at
	storm_warning.emit(storm_warning_lead_game_sec)


func _maybe_update_wind(now_game_sec: float) -> void:
	if now_game_sec < _next_wind_update_game_sec:
		return
	_next_wind_update_game_sec = now_game_sec + WIND_UPDATE_INTERVAL_GAME_SEC
	# Slow drift in direction; speed scales with weather kind.
	var drift_radians: float = _rng.randf_range(-0.2, 0.2)
	wind_direction = wind_direction.rotated(drift_radians).normalized()
	wind_speed_mps = _wind_speed_for_weather(current_weather)
	wind_changed.emit(wind_direction, wind_speed_mps)


func _wind_speed_for_weather(kind: int) -> float:
	match kind:
		WeatherKind.CLEAR:
			return _rng.randf_range(2.0, 6.0)
		WeatherKind.CLOUDY:
			return _rng.randf_range(5.0, 12.0)
		WeatherKind.RAIN:
			return _rng.randf_range(7.0, 14.0)
		WeatherKind.FOG:
			return _rng.randf_range(0.0, 3.0)
		WeatherKind.STORM:
			return _rng.randf_range(20.0, 32.0)
		_:
			return 5.0


## Default transition matrix per specs/features/day_night_cycle.md §3.3.
## Each row is the probability distribution from the keyed weather to all
## kinds (in WeatherKind enum order). Rows must sum to 1.0.
static func _default_transition_matrix() -> Dictionary:
	return {
		WeatherKind.CLEAR: PackedFloat32Array([0.85, 0.10, 0.03, 0.01, 0.01]),
		WeatherKind.CLOUDY: PackedFloat32Array([0.20, 0.55, 0.15, 0.05, 0.05]),
		WeatherKind.RAIN: PackedFloat32Array([0.05, 0.35, 0.50, 0.05, 0.05]),
		WeatherKind.FOG: PackedFloat32Array([0.40, 0.30, 0.05, 0.20, 0.05]),
		WeatherKind.STORM: PackedFloat32Array([0.05, 0.35, 0.20, 0.05, 0.35]),
	}
