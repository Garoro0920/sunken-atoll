class_name Inventory
extends Node

## Bucket-style inventory keyed by item id.
##
## Per specs/features/building_system.md §3.4 (craft_cost), MVP uses a
## flat Dictionary[item_id -> quantity] rather than per-slot stacks
## because the consumer APIs (can_afford / consume_cost) only need
## totals. A slot-based UI representation can be derived from this
## bucket by reading max_stack from ItemDefinition lookups; the
## inventory itself stays simple and easy to test.

signal changed
signal item_overflowed(item_id: StringName, leftover: int)

## Optional weight cap. 0 = no limit.
@export var max_total_weight_kg: float = 0.0
## Optional cap on the total quantity of any one item id (in addition
## to ItemDefinition.max_stack). 0 = no extra cap.
@export var max_per_item: int = 0

## Hook to look up ItemDefinition by id. Defaults to T1ItemCatalog.find;
## tests can substitute by reassigning before calling weight/add APIs.
var item_lookup: Callable = Callable(T1ItemCatalog, &"find")

var _quantities: Dictionary = {}


## Returns the current quantity of an item (0 if absent).
func count(item_id: StringName) -> int:
	return int(_quantities.get(item_id, 0))


## Adds `quantity` of `item_id`. Returns leftover that didn't fit
## (because of max_stack, per-item cap, or weight limit).
func add(item_id: StringName, quantity: int) -> int:
	if quantity <= 0:
		return 0
	var def: ItemDefinition = _resolve_definition(item_id)
	var stack_cap: int = (
		_per_item_cap(def) if def != null else (max_per_item if max_per_item > 0 else quantity)
	)
	var current: int = count(item_id)
	var headroom_by_stack: int = max(stack_cap - current, 0)
	var allowed: int = min(quantity, headroom_by_stack)
	# Weight gate.
	if def != null and max_total_weight_kg > 0.0:
		var remaining_weight: float = max_total_weight_kg - total_weight_kg()
		var weight_per: float = max(def.weight_kg, 0.0)
		if weight_per > 0.0:
			var allowed_by_weight: int = int(floorf(remaining_weight / weight_per))
			allowed = min(allowed, max(allowed_by_weight, 0))
	if allowed > 0:
		_quantities[item_id] = current + allowed
		changed.emit()
	var leftover: int = quantity - allowed
	if leftover > 0:
		item_overflowed.emit(item_id, leftover)
	return leftover


## Removes `quantity` of `item_id`. Returns true if the full amount was
## removed; false (and no mutation) if there isn't enough on hand.
func remove(item_id: StringName, quantity: int) -> bool:
	if quantity <= 0:
		return true
	if count(item_id) < quantity:
		return false
	var new_qty: int = count(item_id) - quantity
	if new_qty == 0:
		_quantities.erase(item_id)
	else:
		_quantities[item_id] = new_qty
	changed.emit()
	return true


## True iff every {item_id: qty} in `cost` is currently in stock.
func can_afford(cost: Dictionary) -> bool:
	for key in cost.keys():
		var item_id: StringName = key as StringName
		var required: int = int(cost[key])
		if count(item_id) < required:
			return false
	return true


## Atomically subtracts `cost`. Returns true on success, false if any
## requirement isn't met (and no items are deducted in that case).
func consume_cost(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for key in cost.keys():
		var item_id: StringName = key as StringName
		var required: int = int(cost[key])
		_quantities[item_id] = count(item_id) - required
		if _quantities[item_id] <= 0:
			_quantities.erase(item_id)
	changed.emit()
	return true


## Total carried weight, using ItemDefinition.weight_kg for each id.
## Items the lookup can't resolve contribute 0.
func total_weight_kg() -> float:
	var total: float = 0.0
	for item_id in _quantities.keys():
		var def: ItemDefinition = _resolve_definition(item_id)
		if def != null:
			total += def.weight_kg * float(_quantities[item_id])
	return total


## Snapshot for save/load — copy of the underlying bucket.
func snapshot() -> Dictionary:
	return _quantities.duplicate(true)


func apply_snapshot(d: Dictionary) -> void:
	_quantities.clear()
	for key in d.keys():
		var item_id: StringName = key as StringName
		var qty: int = int(d[key])
		if qty > 0:
			_quantities[item_id] = qty
	changed.emit()


func clear() -> void:
	if _quantities.is_empty():
		return
	_quantities.clear()
	changed.emit()


# --- Internals ---


func _resolve_definition(item_id: StringName) -> ItemDefinition:
	if item_lookup.is_null():
		return null
	var v: Variant = item_lookup.call(item_id)
	return v as ItemDefinition


func _per_item_cap(def: ItemDefinition) -> int:
	if def == null:
		return max_per_item if max_per_item > 0 else 0
	if max_per_item > 0:
		return min(def.max_stack, max_per_item)
	return def.max_stack
