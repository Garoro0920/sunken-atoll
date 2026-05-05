extends GdUnitTestSuite

## Tests for WaterPurifierInteractable.


# Test double — exposes get_inventory() so the purifier can route water
# into the actor's bag without a full PlayerCharacter scene.
class _ActorWithInventory:
	extends Node
	var inventory: Inventory

	func _init(inv: Inventory) -> void:
		inventory = inv

	func get_inventory() -> Inventory:
		return inventory


func _make_purifier() -> WaterPurifierInteractable:
	var p := WaterPurifierInteractable.new()
	p.game_seconds_per_unit = 60.0
	p.max_capacity = 5
	add_child(p)
	return p


func _make_actor_with_inventory() -> _ActorWithInventory:
	var inv := Inventory.new()
	add_child(inv)
	var actor := _ActorWithInventory.new(inv)
	add_child(actor)
	return actor


func test_tick_below_threshold_produces_nothing() -> void:
	var p := _make_purifier()
	p.tick(30.0)  # half a unit's worth
	assert_int(p.water_in_chamber).is_equal(0)


func test_tick_above_threshold_produces_one_unit() -> void:
	var p := _make_purifier()
	p.tick(60.0)
	assert_int(p.water_in_chamber).is_equal(1)


func test_tick_accumulates_multiple_units_per_call() -> void:
	var p := _make_purifier()
	p.tick(180.0)  # 3 game-minutes
	assert_int(p.water_in_chamber).is_equal(3)


func test_capacity_caps_production() -> void:
	var p := _make_purifier()
	p.tick(600.0)  # 10 minutes' worth, but capacity is 5
	assert_int(p.water_in_chamber).is_equal(5)


func test_water_generated_signal_emits_with_amount_produced() -> void:
	var p := _make_purifier()
	var emissions: Array = []
	p.water_generated.connect(func(amount: int) -> void: emissions.append(amount))
	p.tick(120.0)
	assert_array(emissions).contains([2])


func test_use_without_water_fails() -> void:
	var p := _make_purifier()
	var actor := _make_actor_with_inventory()
	assert_bool(p.use(actor)).is_false()


func test_use_transfers_water_to_actor_inventory() -> void:
	var p := _make_purifier()
	p.tick(180.0)
	assert_int(p.water_in_chamber).is_equal(3)
	var actor := _make_actor_with_inventory()
	var ok: bool = p.use(actor)
	assert_bool(ok).is_true()
	assert_int(p.water_in_chamber).is_equal(0)
	assert_int(actor.inventory.count(T1ItemCatalog.ID_FRESH_WATER)).is_equal(3)


func test_use_partial_when_inventory_caps_remainder() -> void:
	var p := _make_purifier()
	p.tick(300.0)  # 5 units (max capacity)
	var actor := _make_actor_with_inventory()
	# fresh_water max_stack is 10; pre-fill so only 4 units fit
	actor.inventory.add(T1ItemCatalog.ID_FRESH_WATER, 6)
	var ok: bool = p.use(actor)
	assert_bool(ok).is_true()
	# 4 fit; 1 stays in chamber.
	assert_int(p.water_in_chamber).is_equal(1)
	assert_int(actor.inventory.count(T1ItemCatalog.ID_FRESH_WATER)).is_equal(10)


func test_water_collected_signal_reports_taken_amount() -> void:
	var p := _make_purifier()
	p.tick(180.0)
	var actor := _make_actor_with_inventory()
	var captured: Array = []
	p.water_collected.connect(func(_a: Node, amount: int) -> void: captured.append(amount))
	p.use(actor)
	assert_array(captured).contains([3])
