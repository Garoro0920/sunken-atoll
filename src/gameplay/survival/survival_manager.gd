class_name SurvivalManager
extends Node

## Drives the survival state per game-minute.
##
## Per specs/features/survival_balance.md §3.1 / §3.2 / §3.3.
## Subscribes to WorldClock.minute_changed (or an injected clock for
## tests) and applies decay, weather-driven body-temp deltas, and
## lethal-threshold HP damage.
##
## All mutations route through this manager so signal-based dependents
## (HUD, audio cues, AI awareness) can subscribe to a single source.

signal state_changed(state: PlayerSurvivalState)
signal lethal_threshold_crossed(zone: String)  # e.g. "starvation", "drown"
signal player_died

const DEFAULT_BALANCE_PATH := "res://resources/data/balance/survival.tres"

@export var state: PlayerSurvivalState
@export var balance: SurvivalBalance

# Test-injection seams. Manager looks these up in _ready when null.
var _clock: TimeOfDay = null
var _weather: Weather = null
var _emitted_zones: Dictionary = {}


func _ready() -> void:
	if state == null:
		state = PlayerSurvivalState.new()
	if balance == null:
		balance = (
			(load(DEFAULT_BALANCE_PATH) as SurvivalBalance)
			if ResourceLoader.exists(DEFAULT_BALANCE_PATH)
			else SurvivalBalance.new()
		)
	_resolve_world_singletons()
	_subscribe_clock()


## Test seam: inject specific instances and (re)subscribe.
func bind_world(clock: TimeOfDay, weather: Weather) -> void:
	_unsubscribe_clock()
	_clock = clock
	_weather = weather
	_subscribe_clock()


func _resolve_world_singletons() -> void:
	if _clock != null and _weather != null:
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	if _clock == null:
		_clock = tree.root.get_node_or_null("WorldClock") as TimeOfDay
	if _weather == null:
		_weather = tree.root.get_node_or_null("WorldWeather") as Weather


func _subscribe_clock() -> void:
	if _clock == null:
		return
	if not _clock.minute_changed.is_connected(_on_minute_changed):
		_clock.minute_changed.connect(_on_minute_changed)


func _unsubscribe_clock() -> void:
	if _clock != null and _clock.minute_changed.is_connected(_on_minute_changed):
		_clock.minute_changed.disconnect(_on_minute_changed)


func _on_minute_changed(_hour: int, _minute: int) -> void:
	# Always invoked once per game-minute boundary.
	step(1.0)


## Apply one game-minute worth of decay/effects. Public so unit tests
## can drive the manager without needing a SceneTree process loop.
func step(game_minutes: float) -> void:
	if game_minutes <= 0.0 or state == null or balance == null:
		return
	_apply_natural_decay(game_minutes)
	_apply_weather_temperature(game_minutes)
	_apply_dive_oxygen(game_minutes)
	_apply_lethal_damage(game_minutes)
	state.apply_balance_clamping(balance)
	state_changed.emit(state)
	if state.is_dead():
		player_died.emit()


# --- Mutators (called by gameplay systems) ---


func eat(food_value: float) -> void:
	if state == null:
		return
	state.hunger = clampf(state.hunger + food_value, balance.hunger_min, balance.hunger_max)
	state_changed.emit(state)


func drink(water_value: float) -> void:
	if state == null:
		return
	state.thirst = clampf(state.thirst + water_value, balance.thirst_min, balance.thirst_max)
	state_changed.emit(state)


func take_damage(amount: float) -> void:
	if state == null or amount <= 0.0:
		return
	state.hp = maxf(state.hp - amount, balance.hp_min)
	state_changed.emit(state)
	if state.is_dead():
		player_died.emit()


func warm_up(degrees: float) -> void:
	if state == null:
		return
	state.body_temp = clampf(
		state.body_temp + degrees, balance.body_temp_min, balance.body_temp_max
	)
	state_changed.emit(state)


func set_diving(diving: bool) -> void:
	if state == null:
		return
	state.is_diving = diving


func cleanse_contamination(amount: float) -> void:
	if state == null or amount <= 0.0:
		return
	state.contamination = maxf(state.contamination - amount, balance.contamination_min)
	state_changed.emit(state)


# --- Internal step helpers ---


func _apply_natural_decay(game_minutes: float) -> void:
	state.hunger -= balance.hunger_decay_per_min * game_minutes
	state.thirst -= balance.thirst_decay_per_min * game_minutes
	state.contamination -= balance.contamination_recovery_per_min * game_minutes


func _apply_weather_temperature(game_minutes: float) -> void:
	var delta_per_min: float = balance.body_temp_delta_clear_day
	if _clock != null:
		var phase: int = _clock.get_phase()
		if phase == TimeOfDay.Phase.NIGHT:
			delta_per_min = balance.body_temp_delta_night
	if _weather != null:
		match _weather.current_weather:
			Weather.WeatherKind.RAIN:
				delta_per_min = minf(delta_per_min, balance.body_temp_delta_rain)
			Weather.WeatherKind.STORM:
				delta_per_min = minf(delta_per_min, balance.body_temp_delta_storm)
			_:
				pass
	# Drift body_temp toward the equilibrium implied by delta sign.
	state.body_temp += delta_per_min * game_minutes


func _apply_dive_oxygen(game_minutes: float) -> void:
	if state.is_diving:
		state.oxygen -= balance.oxygen_decay_per_min_when_diving * game_minutes
	else:
		# Rapid recovery while above water.
		state.oxygen = minf(state.oxygen + 30.0 * game_minutes, balance.oxygen_max)


func _apply_lethal_damage(game_minutes: float) -> void:
	if state.hunger < balance.hunger_lethal_threshold:
		state.hp -= balance.hp_damage_when_starving * game_minutes
		_emit_zone_once_per_dip("starvation")
	else:
		_emitted_zones.erase("starvation")
	if state.thirst < balance.thirst_lethal_threshold:
		state.hp -= balance.hp_damage_when_dehydrated * game_minutes
		_emit_zone_once_per_dip("dehydration")
	else:
		_emitted_zones.erase("dehydration")
	if absf(state.body_temp) >= balance.body_temp_lethal_abs:
		state.hp -= balance.hp_damage_when_extreme_temp * game_minutes
		_emit_zone_once_per_dip("extreme_temperature")
	else:
		_emitted_zones.erase("extreme_temperature")
	if state.oxygen <= balance.oxygen_min:
		state.hp -= balance.hp_damage_when_oxygen_zero * game_minutes
		_emit_zone_once_per_dip("drowning")
	else:
		_emitted_zones.erase("drowning")
	if state.contamination >= balance.contamination_lethal_threshold:
		state.hp -= balance.hp_damage_when_contaminated * game_minutes
		_emit_zone_once_per_dip("contamination")
	else:
		_emitted_zones.erase("contamination")


func _emit_zone_once_per_dip(zone: String) -> void:
	if _emitted_zones.has(zone):
		return
	_emitted_zones[zone] = true
	lethal_threshold_crossed.emit(zone)
