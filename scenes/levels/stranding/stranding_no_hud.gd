class_name StrandingNoHud
extends Node3D

## Bisect-only variant of StrandingDemo with the HUD wiring removed.
## Used to test whether DemoHud is the cause of the runtime "sky-blue
## only" symptom. If this scene renders correctly, the HUD is the
## culprit and the production demo can replace it (or omit it for now).

const STARTER_KIT: Dictionary = {
	&"wood": 24,
	&"rope": 6,
	&"cloth": 4,
	&"metal_scrap": 3,
	&"food_fish": 4,
}

@export var auto_grant_starter: bool = true

@onready var player: PlayerCharacter = $Player
@onready var placement: BuildingPlacement = $BuildingPlacement
@onready var integrity: StructuralIntegrity = $StructuralIntegrity
@onready var parts_root: Node3D = $Parts
@onready var water_field: Node = $WaterField


func _ready() -> void:
	_wire_systems()
	if auto_grant_starter:
		_grant_starter_inventory()


func _wire_systems() -> void:
	placement.parts_root = parts_root
	placement.integrity = integrity
	placement.inventory = player.get_inventory()
	player.bind_dependencies(water_field, player.get_survival_manager())


func _grant_starter_inventory() -> void:
	var inv: Inventory = player.get_inventory()
	if inv == null:
		return
	for key in STARTER_KIT.keys():
		var item_id: StringName = key as StringName
		var quantity: int = int(STARTER_KIT[key])
		inv.add(item_id, quantity)
