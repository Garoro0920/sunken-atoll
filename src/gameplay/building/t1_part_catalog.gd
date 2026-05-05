class_name T1PartCatalog
extends RefCounted

## T1 building parts catalog.
##
## Per specs/features/building_system.md §5 (T1 仮拠点).
## This is the code-resident source of truth for the 7 T1 parts. A
## follow-up will mirror these into .tres files under
## resources/data/building/t1/ for designer editing without code
## changes; until then `T1PartCatalog.find(id)` is the canonical
## lookup used by gameplay and tests.

const ID_FOUNDATION := &"t1_foundation"
const ID_FLOOR := &"t1_floor"
const ID_WALL := &"t1_wall"
const ID_ROOF := &"t1_roof"
const ID_BED := &"t1_bed"
const ID_STORAGE := &"t1_storage"
const ID_WATER_PURIFIER := &"t1_water_purifier"

const ALL_IDS: Array[StringName] = [
	ID_FOUNDATION,
	ID_FLOOR,
	ID_WALL,
	ID_ROOF,
	ID_BED,
	ID_STORAGE,
	ID_WATER_PURIFIER,
]


static func find(part_id: StringName) -> BuildingPartDefinition:
	match part_id:
		ID_FOUNDATION:
			return _foundation()
		ID_FLOOR:
			return _floor()
		ID_WALL:
			return _wall()
		ID_ROOF:
			return _roof()
		ID_BED:
			return _bed()
		ID_STORAGE:
			return _storage()
		ID_WATER_PURIFIER:
			return _water_purifier()
	return null


static func _foundation() -> BuildingPartDefinition:
	var d := BuildingPartDefinition.new()
	d.id = ID_FOUNDATION
	d.display_name = "T1 Foundation"
	d.category = BuildingPartDefinition.Category.FOUNDATION
	d.size_m = Vector3(3.0, 0.4, 3.0)
	d.snap_step_m = 3.0  # foundations align to a 3-unit grid
	d.supported_by = []
	d.supports = [BuildingPartDefinition.Category.FOUNDATION, BuildingPartDefinition.Category.FLOOR]
	d.is_self_supporting = true
	d.displaced_volume = 3.6
	d.sample_extents = Vector3(1.5, 0.2, 1.5)
	d.craft_cost = {&"wood": 8, &"rope": 4}
	d.max_per_base = 0
	return d


static func _floor() -> BuildingPartDefinition:
	var d := BuildingPartDefinition.new()
	d.id = ID_FLOOR
	d.display_name = "T1 Floor"
	d.category = BuildingPartDefinition.Category.FLOOR
	d.size_m = Vector3(1.0, 0.2, 1.0)
	d.snap_step_m = 1.0
	d.supported_by = [
		BuildingPartDefinition.Category.FOUNDATION, BuildingPartDefinition.Category.FLOOR
	]
	d.supports = [
		BuildingPartDefinition.Category.WALL,
		BuildingPartDefinition.Category.FURNITURE,
		BuildingPartDefinition.Category.FUNCTIONAL,
		BuildingPartDefinition.Category.FLOOR,
	]
	d.craft_cost = {&"wood": 3}
	return d


static func _wall() -> BuildingPartDefinition:
	var d := BuildingPartDefinition.new()
	d.id = ID_WALL
	d.display_name = "T1 Wall"
	d.category = BuildingPartDefinition.Category.WALL
	d.size_m = Vector3(1.0, 2.0, 0.1)
	d.snap_step_m = 1.0
	d.supported_by = [BuildingPartDefinition.Category.FLOOR, BuildingPartDefinition.Category.WALL]
	d.supports = [BuildingPartDefinition.Category.ROOF, BuildingPartDefinition.Category.WALL]
	d.craft_cost = {&"wood": 2}
	return d


static func _roof() -> BuildingPartDefinition:
	var d := BuildingPartDefinition.new()
	d.id = ID_ROOF
	d.display_name = "T1 Roof"
	d.category = BuildingPartDefinition.Category.ROOF
	d.size_m = Vector3(1.0, 0.2, 1.0)
	d.snap_step_m = 1.0
	d.supported_by = [BuildingPartDefinition.Category.WALL]
	d.supports = []
	d.craft_cost = {&"wood": 3}
	return d


static func _bed() -> BuildingPartDefinition:
	var d := BuildingPartDefinition.new()
	d.id = ID_BED
	d.display_name = "T1 Bed"
	d.category = BuildingPartDefinition.Category.FURNITURE
	d.size_m = Vector3(2.0, 0.5, 1.0)
	d.snap_step_m = 1.0
	d.supported_by = [BuildingPartDefinition.Category.FLOOR]
	d.supports = []
	d.craft_cost = {&"wood": 4, &"cloth": 3}
	d.max_per_base = 4  # 4-player MVP
	return d


static func _storage() -> BuildingPartDefinition:
	var d := BuildingPartDefinition.new()
	d.id = ID_STORAGE
	d.display_name = "T1 Storage"
	d.category = BuildingPartDefinition.Category.FURNITURE
	d.size_m = Vector3(1.0, 1.0, 1.0)
	d.snap_step_m = 1.0
	d.supported_by = [BuildingPartDefinition.Category.FLOOR]
	d.supports = []
	d.craft_cost = {&"wood": 5}
	return d


static func _water_purifier() -> BuildingPartDefinition:
	var d := BuildingPartDefinition.new()
	d.id = ID_WATER_PURIFIER
	d.display_name = "T1 Water Purifier"
	d.category = BuildingPartDefinition.Category.FUNCTIONAL
	d.size_m = Vector3(1.0, 1.2, 1.0)
	d.snap_step_m = 1.0
	d.supported_by = [BuildingPartDefinition.Category.FLOOR]
	d.supports = []
	d.craft_cost = {&"wood": 4, &"metal_scrap": 2}
	d.max_per_base = 2
	return d
