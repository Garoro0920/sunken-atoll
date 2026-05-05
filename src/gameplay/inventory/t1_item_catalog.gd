class_name T1ItemCatalog
extends RefCounted

## Code-resident item catalog for Sprint 1.
##
## Designer-editable .tres mirrors are a follow-up (same pattern as
## T1PartCatalog). For now this is the canonical lookup for tests and
## production initialization.

const ID_WOOD := &"wood"
const ID_ROPE := &"rope"
const ID_CLOTH := &"cloth"
const ID_METAL_SCRAP := &"metal_scrap"
const ID_FRESH_WATER := &"fresh_water"
const ID_FOOD_FISH := &"food_fish"

const ALL_IDS: Array[StringName] = [
	ID_WOOD,
	ID_ROPE,
	ID_CLOTH,
	ID_METAL_SCRAP,
	ID_FRESH_WATER,
	ID_FOOD_FISH,
]


static func find(item_id: StringName) -> ItemDefinition:
	match item_id:
		ID_WOOD:
			return _wood()
		ID_ROPE:
			return _rope()
		ID_CLOTH:
			return _cloth()
		ID_METAL_SCRAP:
			return _metal_scrap()
		ID_FRESH_WATER:
			return _fresh_water()
		ID_FOOD_FISH:
			return _food_fish()
	return null


static func _wood() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ID_WOOD
	d.display_name = "Wood"
	d.max_stack = 99
	d.weight_kg = 0.5
	d.category = ItemDefinition.Category.RAW
	return d


static func _rope() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ID_ROPE
	d.display_name = "Rope"
	d.max_stack = 50
	d.weight_kg = 0.3
	d.category = ItemDefinition.Category.RAW
	return d


static func _cloth() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ID_CLOTH
	d.display_name = "Cloth"
	d.max_stack = 50
	d.weight_kg = 0.2
	d.category = ItemDefinition.Category.RAW
	return d


static func _metal_scrap() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ID_METAL_SCRAP
	d.display_name = "Metal Scrap"
	d.max_stack = 30
	d.weight_kg = 1.0
	d.category = ItemDefinition.Category.RAW
	return d


static func _fresh_water() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ID_FRESH_WATER
	d.display_name = "Fresh Water"
	d.max_stack = 10
	d.weight_kg = 1.0
	d.category = ItemDefinition.Category.CONSUMABLE
	return d


static func _food_fish() -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = ID_FOOD_FISH
	d.display_name = "Fish"
	d.max_stack = 20
	d.weight_kg = 0.4
	d.category = ItemDefinition.Category.CONSUMABLE
	return d
