extends GdUnitTestSuite

## Tests for T1ItemCatalog.


func test_all_ids_resolve_to_definitions() -> void:
	for item_id in T1ItemCatalog.ALL_IDS:
		var def: ItemDefinition = T1ItemCatalog.find(item_id)
		assert_object(def).is_not_null()
		assert_str(def.id).is_equal(item_id)


func test_unknown_id_returns_null() -> void:
	assert_object(T1ItemCatalog.find(&"nonexistent")).is_null()


func test_consumables_carry_consumable_category() -> void:
	assert_int(T1ItemCatalog.find(T1ItemCatalog.ID_FRESH_WATER).category).is_equal(
		ItemDefinition.Category.CONSUMABLE
	)
	assert_int(T1ItemCatalog.find(T1ItemCatalog.ID_FOOD_FISH).category).is_equal(
		ItemDefinition.Category.CONSUMABLE
	)


func test_raw_materials_carry_raw_category() -> void:
	for raw_id in [
		T1ItemCatalog.ID_WOOD,
		T1ItemCatalog.ID_ROPE,
		T1ItemCatalog.ID_CLOTH,
		T1ItemCatalog.ID_METAL_SCRAP,
	]:
		assert_int(T1ItemCatalog.find(raw_id).category).is_equal(ItemDefinition.Category.RAW)


func test_metal_scrap_is_heaviest_raw_material() -> void:
	var metal: ItemDefinition = T1ItemCatalog.find(T1ItemCatalog.ID_METAL_SCRAP)
	for raw_id in [T1ItemCatalog.ID_WOOD, T1ItemCatalog.ID_ROPE, T1ItemCatalog.ID_CLOTH]:
		var other: ItemDefinition = T1ItemCatalog.find(raw_id)
		assert_float(metal.weight_kg).is_greater_equal(other.weight_kg)
