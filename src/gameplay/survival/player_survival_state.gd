class_name PlayerSurvivalState
extends Resource

## Mutable per-player survival state.
##
## Per specs/features/survival_balance.md §3.1.
## Owned by SurvivalManager; mutations are routed through methods that
## clamp to balance bounds. `apply_balance_clamping(balance)` reapplies
## bounds — call after deserialization or external poke.

@export var hp: float = 100.0
@export var hunger: float = 100.0
@export var thirst: float = 100.0
@export var body_temp: float = 0.0  # 0 = comfortable; +/- towards extremes
@export var oxygen: float = 100.0
@export var contamination: float = 0.0
@export var is_diving: bool = false


func snapshot() -> Dictionary:
	return {
		"hp": hp,
		"hunger": hunger,
		"thirst": thirst,
		"body_temp": body_temp,
		"oxygen": oxygen,
		"contamination": contamination,
		"is_diving": is_diving,
	}


func apply_snapshot(d: Dictionary) -> void:
	hp = float(d.get("hp", hp))
	hunger = float(d.get("hunger", hunger))
	thirst = float(d.get("thirst", thirst))
	body_temp = float(d.get("body_temp", body_temp))
	oxygen = float(d.get("oxygen", oxygen))
	contamination = float(d.get("contamination", contamination))
	is_diving = bool(d.get("is_diving", is_diving))


func reset_to_full() -> void:
	hp = 100.0
	hunger = 100.0
	thirst = 100.0
	body_temp = 0.0
	oxygen = 100.0
	contamination = 0.0
	is_diving = false


func is_dead() -> bool:
	return hp <= 0.0


func apply_balance_clamping(balance: SurvivalBalance) -> void:
	hp = clampf(hp, balance.hp_min, balance.hp_max)
	hunger = clampf(hunger, balance.hunger_min, balance.hunger_max)
	thirst = clampf(thirst, balance.thirst_min, balance.thirst_max)
	body_temp = clampf(body_temp, balance.body_temp_min, balance.body_temp_max)
	oxygen = clampf(oxygen, balance.oxygen_min, balance.oxygen_max)
	contamination = clampf(contamination, balance.contamination_min, balance.contamination_max)
