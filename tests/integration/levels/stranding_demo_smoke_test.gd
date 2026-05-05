extends GdUnitTestSuite

## Smoke test: load the Sprint 1 stranding demo and confirm wiring.
##
## Catches scene-level regressions early without requiring a windowed
## Godot instance: instantiates the scene, runs _ready, and asserts on
## the wiring established in StrandingDemo._wire_systems().

const SCENE_PATH := "res://scenes/levels/stranding/stranding_demo.tscn"


func test_scene_loads_as_packed_scene() -> void:
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_object(packed).is_not_null()


func test_instantiated_scene_has_expected_top_level_nodes() -> void:
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	var root: Node = packed.instantiate()
	add_child(root)
	# Wait one frame so child @onready vars resolve. add_child triggers
	# _ready synchronously in Godot 4 only when inside the SceneTree.
	for child_name in [
		"WorldEnvironment",
		"Sun",
		"WaterField",
		"WaterMesh",
		"Island",
		"Player",
		"StructuralIntegrity",
		"BuildingPlacement",
		"Parts"
	]:
		assert_object(root.get_node_or_null(child_name)).is_not_null()


func test_player_has_inventory_after_starter_grant() -> void:
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	var root: Node = packed.instantiate()
	add_child(root)
	var player: PlayerCharacter = root.get_node("Player") as PlayerCharacter
	assert_object(player).is_not_null()
	var inv: Inventory = player.get_inventory()
	assert_object(inv).is_not_null()
	# StrandingDemo._grant_starter_inventory ran in _ready.
	assert_int(inv.count(T1ItemCatalog.ID_WOOD)).is_greater_equal(20)
	assert_int(inv.count(T1ItemCatalog.ID_ROPE)).is_greater_equal(4)


func test_building_placement_is_wired_to_inventory_and_integrity() -> void:
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	var root: Node = packed.instantiate()
	add_child(root)
	var placement: BuildingPlacement = root.get_node("BuildingPlacement") as BuildingPlacement
	assert_object(placement).is_not_null()
	assert_object(placement.parts_root).is_not_null()
	assert_object(placement.integrity).is_not_null()
	assert_object(placement.inventory).is_not_null()


func test_player_can_afford_t1_foundation_after_starter_grant() -> void:
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	var root: Node = packed.instantiate()
	add_child(root)
	var inv: Inventory = (root.get_node("Player") as PlayerCharacter).get_inventory()
	var foundation_def: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_FOUNDATION)
	assert_bool(inv.can_afford(foundation_def.craft_cost)).is_true()
