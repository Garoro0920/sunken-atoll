extends GdUnitTestSuite

## Tests for Inventory.
## Per specs/features/building_system.md §3.4 (craft_cost) and
##     specs/game_design_document.md §4.3 (clafting hierarchy).


func _make_inventory() -> Inventory:
	var inv: Inventory = Inventory.new()
	add_child(inv)
	return inv


func test_count_unknown_item_returns_zero() -> void:
	var inv := _make_inventory()
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(0)


func test_add_then_count_increases_quantity() -> void:
	var inv := _make_inventory()
	var leftover: int = inv.add(T1ItemCatalog.ID_WOOD, 5)
	assert_int(leftover).is_equal(0)
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(5)


func test_add_overflow_returns_leftover() -> void:
	var inv := _make_inventory()
	# Wood max_stack = 99 in the catalog; try to add 200.
	var leftover: int = inv.add(T1ItemCatalog.ID_WOOD, 200)
	assert_int(leftover).is_equal(101)
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(99)


func test_add_emits_overflow_signal_with_leftover() -> void:
	var inv := _make_inventory()
	var emitted: Array = []
	inv.item_overflowed.connect(
		func(item_id: StringName, leftover: int) -> void: emitted.append([item_id, leftover])
	)
	inv.add(T1ItemCatalog.ID_WOOD, 200)
	assert_array(emitted).contains([[T1ItemCatalog.ID_WOOD, 101]])


func test_add_zero_or_negative_is_noop() -> void:
	var inv := _make_inventory()
	var changed_count: Array = [0]
	inv.changed.connect(func() -> void: changed_count[0] += 1)
	assert_int(inv.add(T1ItemCatalog.ID_WOOD, 0)).is_equal(0)
	assert_int(inv.add(T1ItemCatalog.ID_WOOD, -10)).is_equal(0)
	assert_int(changed_count[0]).is_equal(0)


func test_remove_succeeds_only_when_enough_stock() -> void:
	var inv := _make_inventory()
	inv.add(T1ItemCatalog.ID_WOOD, 5)
	assert_bool(inv.remove(T1ItemCatalog.ID_WOOD, 3)).is_true()
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(2)
	assert_bool(inv.remove(T1ItemCatalog.ID_WOOD, 10)).is_false()
	# Failed remove leaves quantity unchanged.
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(2)


func test_remove_to_zero_erases_key() -> void:
	var inv := _make_inventory()
	inv.add(T1ItemCatalog.ID_WOOD, 5)
	inv.remove(T1ItemCatalog.ID_WOOD, 5)
	# count returns 0 even though entry was removed
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(0)
	# snapshot doesn't contain the key
	assert_bool(inv.snapshot().has(T1ItemCatalog.ID_WOOD)).is_false()


func test_can_afford_true_when_all_costs_present() -> void:
	var inv := _make_inventory()
	inv.add(T1ItemCatalog.ID_WOOD, 8)
	inv.add(T1ItemCatalog.ID_ROPE, 4)
	var cost: Dictionary = {T1ItemCatalog.ID_WOOD: 5, T1ItemCatalog.ID_ROPE: 2}
	assert_bool(inv.can_afford(cost)).is_true()


func test_can_afford_false_when_any_cost_missing() -> void:
	var inv := _make_inventory()
	inv.add(T1ItemCatalog.ID_WOOD, 3)
	var cost: Dictionary = {T1ItemCatalog.ID_WOOD: 5}
	assert_bool(inv.can_afford(cost)).is_false()


func test_consume_cost_atomic_failure_keeps_inventory_unchanged() -> void:
	var inv := _make_inventory()
	inv.add(T1ItemCatalog.ID_WOOD, 8)
	# rope is missing entirely; consume should leave wood alone.
	var cost: Dictionary = {T1ItemCatalog.ID_WOOD: 5, T1ItemCatalog.ID_ROPE: 2}
	assert_bool(inv.consume_cost(cost)).is_false()
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(8)
	assert_int(inv.count(T1ItemCatalog.ID_ROPE)).is_equal(0)


func test_consume_cost_success_subtracts_each_item() -> void:
	var inv := _make_inventory()
	inv.add(T1ItemCatalog.ID_WOOD, 8)
	inv.add(T1ItemCatalog.ID_ROPE, 4)
	var cost: Dictionary = {T1ItemCatalog.ID_WOOD: 5, T1ItemCatalog.ID_ROPE: 2}
	assert_bool(inv.consume_cost(cost)).is_true()
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(3)
	assert_int(inv.count(T1ItemCatalog.ID_ROPE)).is_equal(2)


func test_snapshot_round_trip_preserves_quantities() -> void:
	var inv := _make_inventory()
	inv.add(T1ItemCatalog.ID_WOOD, 5)
	inv.add(T1ItemCatalog.ID_ROPE, 2)
	var snap: Dictionary = inv.snapshot()
	var inv2 := _make_inventory()
	inv2.apply_snapshot(snap)
	assert_int(inv2.count(T1ItemCatalog.ID_WOOD)).is_equal(5)
	assert_int(inv2.count(T1ItemCatalog.ID_ROPE)).is_equal(2)


func test_total_weight_uses_catalog_definitions() -> void:
	var inv := _make_inventory()
	# wood weight 0.5 * 4 = 2.0
	inv.add(T1ItemCatalog.ID_WOOD, 4)
	# rope weight 0.3 * 2 = 0.6
	inv.add(T1ItemCatalog.ID_ROPE, 2)
	assert_float(inv.total_weight_kg()).is_equal_approx(2.6, 1e-5)


func test_max_total_weight_caps_added_quantity() -> void:
	var inv := _make_inventory()
	inv.max_total_weight_kg = 1.0  # only fits 2 wood (1.0 kg)
	var leftover: int = inv.add(T1ItemCatalog.ID_WOOD, 5)
	assert_int(leftover).is_equal(3)
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(2)


func test_clear_resets_inventory() -> void:
	var inv := _make_inventory()
	inv.add(T1ItemCatalog.ID_WOOD, 5)
	var changed_count: Array = [0]
	inv.changed.connect(func() -> void: changed_count[0] += 1)
	inv.clear()
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_equal(0)
	assert_int(changed_count[0]).is_equal(1)
