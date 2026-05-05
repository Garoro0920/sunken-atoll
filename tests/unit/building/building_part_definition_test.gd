extends GdUnitTestSuite

## Tests for BuildingPartDefinition + T1PartCatalog.
## Per specs/features/building_system.md §3.1 / §5.


func test_catalog_resolves_all_t1_ids() -> void:
	for part_id in T1PartCatalog.ALL_IDS:
		var def: BuildingPartDefinition = T1PartCatalog.find(part_id)
		assert_object(def).is_not_null()
		assert_str(def.id).is_equal(part_id)


func test_unknown_id_returns_null() -> void:
	assert_object(T1PartCatalog.find(&"nonexistent_part")).is_null()


func test_foundation_is_self_supporting() -> void:
	var f: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_FOUNDATION)
	assert_bool(f.is_self_supporting).is_true()
	assert_int(f.category).is_equal(BuildingPartDefinition.Category.FOUNDATION)


func test_floor_is_supported_by_foundation() -> void:
	var floor_def: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_FLOOR)
	assert_bool(floor_def.can_be_supported_by(BuildingPartDefinition.Category.FOUNDATION)).is_true()


func test_floor_supports_walls_and_furniture() -> void:
	var floor_def: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_FLOOR)
	assert_bool(floor_def.can_support(BuildingPartDefinition.Category.WALL)).is_true()
	assert_bool(floor_def.can_support(BuildingPartDefinition.Category.FURNITURE)).is_true()
	assert_bool(floor_def.can_support(BuildingPartDefinition.Category.FUNCTIONAL)).is_true()


func test_wall_supports_roof_and_walls_only() -> void:
	var wall: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_WALL)
	assert_bool(wall.can_support(BuildingPartDefinition.Category.ROOF)).is_true()
	assert_bool(wall.can_support(BuildingPartDefinition.Category.WALL)).is_true()
	assert_bool(wall.can_support(BuildingPartDefinition.Category.FLOOR)).is_false()


func test_furniture_must_be_on_floor() -> void:
	var bed: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_BED)
	assert_bool(bed.can_be_supported_by(BuildingPartDefinition.Category.FLOOR)).is_true()
	assert_bool(bed.can_be_supported_by(BuildingPartDefinition.Category.FOUNDATION)).is_false()


func test_max_per_base_capped_for_bed_and_purifier() -> void:
	assert_int(T1PartCatalog.find(T1PartCatalog.ID_BED).max_per_base).is_equal(4)
	assert_int(T1PartCatalog.find(T1PartCatalog.ID_WATER_PURIFIER).max_per_base).is_equal(2)
	assert_int(T1PartCatalog.find(T1PartCatalog.ID_FOUNDATION).max_per_base).is_equal(0)


func test_craft_costs_use_string_name_keys() -> void:
	var foundation: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_FOUNDATION)
	assert_bool(foundation.craft_cost.has(&"wood")).is_true()
	assert_int(foundation.craft_cost[&"wood"]).is_equal(8)
