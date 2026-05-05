class_name BuildingPartDefinition
extends Resource

## Designer-tunable definition for one building part type.
##
## Per specs/features/building_system.md §3.1 (構造階層).
## Each part declares which categories it can be supported by and which
## categories it can support, plus its physical / functional traits.
## Saved as .tres so designers add new parts without code changes.

## Categories used by the structural integrity layer to validate
## "this part can rest on that part" relationships.
enum Category {
	FOUNDATION,  # Floats, anchors the structure to the water column
	FLOOR,  # Walkable surface that sits on a foundation/floor
	WALL,  # Vertical structure on a floor; supports roofs
	ROOF,  # Horizontal cover supported by walls
	FURNITURE,  # Bed, storage, etc.; supported by floor
	FUNCTIONAL,  # Water purifier, cookfire, etc.; supported by floor
}

@export var id: StringName  ## Stable id, e.g. &"t1_foundation"
@export var display_name: String
@export var category: Category = Category.FLOOR
@export var size_m: Vector3 = Vector3(1, 0.4, 1)  ## Bounding extents
@export var snap_step_m: float = 1.0  ## Lateral grid step

## Categories this part can be placed *on* (i.e. that supply support).
## A FLOOR placed on a FOUNDATION → supported_by includes FOUNDATION.
@export var supported_by: Array[int] = []
## Categories this part can support (i.e. parts that may rest on it).
@export var supports: Array[int] = []
## True if this part is itself self-supporting in the structural graph.
## Foundations are the only category that should set this.
@export var is_self_supporting: bool = false

## Buoyancy traits — used only when category == FOUNDATION (FloatingNode uses).
@export var displaced_volume: float = 0.0
@export var sample_extents: Vector3 = Vector3.ZERO

## Resource cost to craft (key = item id, value = quantity).
## Designers can extend without code; placement check reads this dict.
@export var craft_cost: Dictionary = {}

## Maximum count per single base for balance reasons; 0 = unlimited.
@export var max_per_base: int = 0


## Convenience: returns true if this part can rest on the supplier's category.
func can_be_supported_by(supplier_category: int) -> bool:
	return supplier_category in supported_by


## Convenience: returns true if this part can support the dependent's category.
func can_support(dependent_category: int) -> bool:
	return dependent_category in supports
