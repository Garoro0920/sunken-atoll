class_name WaterPurifierInteractable
extends Interactable

## T1 manual water purifier.
##
## Per specs/features/building_system.md §3.5 (T1 淡水化) and
## specs/features/survival_balance.md §3 (drinks generate fresh_water
## that the player consumes via SurvivalManager.drink()).
##
## Accumulates fresh_water units over game-time. The actor uses the
## station to transfer the produced units into their inventory.

signal water_generated(amount: int)
signal water_collected(actor: Node, amount: int)

@export var game_seconds_per_unit: float = 60.0  # 1 game-minute → 1 unit
@export var max_capacity: int = 5

var water_in_chamber: int = 0

var _accumulator: float = 0.0


## Public so unit tests can step the system without a SceneTree process
## loop. Production wires _on_minute_changed to TimeOfDay.minute_changed.
func tick(game_seconds_delta: float) -> void:
	if game_seconds_delta <= 0.0:
		return
	if water_in_chamber >= max_capacity:
		return
	_accumulator += game_seconds_delta
	var produced: int = 0
	while _accumulator >= game_seconds_per_unit and water_in_chamber < max_capacity:
		_accumulator -= game_seconds_per_unit
		water_in_chamber += 1
		produced += 1
	if produced > 0:
		water_generated.emit(produced)


func _do_use(actor: Node) -> bool:
	if water_in_chamber <= 0:
		return false
	var inventory: Inventory = _resolve_inventory(actor)
	if inventory == null:
		return false
	var leftover: int = inventory.add(T1ItemCatalog.ID_FRESH_WATER, water_in_chamber)
	var taken: int = water_in_chamber - leftover
	water_in_chamber = leftover
	if taken > 0:
		water_collected.emit(actor, taken)
		return true
	return false


func _resolve_inventory(actor: Node) -> Inventory:
	if actor == null:
		return null
	if actor.has_method("get_inventory"):
		var v: Variant = actor.call("get_inventory")
		return v as Inventory
	# Fallback: look for an "Inventory" child on the actor.
	return actor.get_node_or_null("Inventory") as Inventory
