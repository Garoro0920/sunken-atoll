class_name StrandingDemo
extends Node3D

## Sprint 1 demo level: 浅瀬 + 漂着プレイヤー + T1 拠点を建てて使うまでの
## エンドツーエンドフローを実装するシーン。
##
## Per specs/epics/mvp_implementation.md §5.1 (Sprint 1 DoD).
## Wires the systems implemented over Sprint 1:
##   PlayerCharacter (+ SurvivalManager + Inventory + PlayerInputController)
##   BuildingPlacement (with player's Inventory + StructuralIntegrity)
##   WorldClock + WorldWeather (autoloads)
##   AnalyticalWaterField (proto-derived)
##
## A starter inventory is granted on _ready so the player can immediately
## craft a foundation, floor, bed, storage, and water purifier — enough to
## exercise the full Sprint 1 DoD loop.

const STARTER_KIT: Dictionary = {
	&"wood": 24,
	&"rope": 6,
	&"cloth": 4,
	&"metal_scrap": 3,
	&"food_fish": 4,  # for testing eat() once that integration lands
}

@export var auto_grant_starter: bool = true

@onready var player: PlayerCharacter = $Player
@onready var input: PlayerInputController = $Player/PlayerInputController
@onready var placement: BuildingPlacement = $BuildingPlacement
@onready var integrity: StructuralIntegrity = $StructuralIntegrity
@onready var parts_root: Node3D = $Parts
@onready var water_field: Node = $WaterField
@onready var hud: DemoHud = $DemoHud


func _ready() -> void:
	_wire_systems()
	if auto_grant_starter:
		_grant_starter_inventory()
	_wire_hud()
	# Mouse capture only when this scene is the project's running main
	# scene — guarded so the smoke test's add_child instantiation does
	# not steal the editor mouse.
	if get_tree().current_scene == self:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _wire_systems() -> void:
	# BuildingPlacement needs a parts_root, an integrity tracker, and the
	# player's inventory for craft_cost gating.
	placement.parts_root = parts_root
	placement.integrity = integrity
	placement.inventory = player.get_inventory()

	# PlayerInputController already has `player` set via the player scene;
	# wire its building_placement here at the level.
	input.building_placement = placement

	# Player needs the water field so locomotion picks SWIM_SURFACE / DIVING
	# when the body crosses the surface.
	player.bind_dependencies(water_field, player.get_survival_manager())


func _wire_hud() -> void:
	if hud == null:
		return
	# Drive HUD from the systems' signals so PO can verify input
	# without the engine console.
	input.build_mode_changed.connect(hud.update_build_mode)
	input.selected_part_changed.connect(hud.update_selected_part)
	player.interactable_focused.connect(hud.update_interact_target)
	player.interactable_lost.connect(func() -> void: hud.update_interact_target(null))
	var inv: Inventory = player.get_inventory()
	if inv != null:
		inv.changed.connect(func() -> void: hud.update_inventory(inv))
	# Initial sync.
	hud.update_build_mode(input.build_mode_active)
	hud.update_selected_part(input.get_selected_part_id())
	hud.update_interact_target(player.get_focused_interactable())
	hud.update_inventory(inv)


func _grant_starter_inventory() -> void:
	var inv: Inventory = player.get_inventory()
	if inv == null:
		push_warning("StrandingDemo: player has no inventory; starter kit skipped")
		return
	for key in STARTER_KIT.keys():
		var item_id: StringName = key as StringName
		var quantity: int = int(STARTER_KIT[key])
		inv.add(item_id, quantity)
