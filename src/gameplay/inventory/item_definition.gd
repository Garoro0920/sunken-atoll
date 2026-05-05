class_name ItemDefinition
extends Resource

## Designer-tunable item type.
##
## Per specs/game_design_document.md §4.3 (クラフト階層) and
## specs/features/building_system.md §3.4 (craft_cost dict refers to
## these ids).

enum Category {
	RAW,  # Wood, rope, cloth — gathered direct
	REFINED,  # Refined plank, treated rope
	PART,  # Crafted intermediate (hinge, motor)
	FINISHED,  # Equippable / placeable
	CONSUMABLE,  # Food, fresh water, medical
}

@export var id: StringName
@export var display_name: String
@export var max_stack: int = 99
@export var weight_kg: float = 0.1
@export var category: Category = Category.RAW
