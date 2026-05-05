class_name PlayerCharacter
extends CharacterBody3D

## Top-level player body. Owns a SurvivalManager child and delegates
## velocity decisions to PlayerLocomotion.
##
## Per specs/features/survival_balance.md §3,
##     specs/features/multiplayer_session.md §3.3 (multiplayer authority
##     hookup will be added on top of this in a follow-up; the proto
##     scenes/prototypes/multiplayer/player.gd shows the pattern),
##     specs/game_design_document.md §4.1 / §4.5 / §4.6.

signal interactable_focused(target: Node)
signal interactable_lost
signal locomotion_state_changed(new_state: int)

## Optional water field provider exposing get_water_height(world_pos: Vector3).
## In production this points at the AnalyticalWaterField autoload-equivalent;
## tests pass a stub object with the same method.
@export var water_field_path: NodePath
## Survival manager attached to this player. If null, locomotion still
## works but oxygen / temperature deltas don't propagate.
@export var survival_manager_path: NodePath
## Inventory child node — Interactables (storage, water_purifier) read
## this via get_inventory(). Optional; null means craft / pick-up
## mechanics are disabled for this player.
@export var inventory_path: NodePath
@export var interact_origin_height_m: float = 1.0
@export var interact_range_m: float = 2.5
## Physics layer mask used for the interactable raycast. Default scans
## both the world layer (so we hit a part's StaticBody3D) and the
## interactable layer (so we definitely catch it). The Interactable
## itself is found by walking the collider's children — see
## _find_interactable_in_collider.
@export_flags_3d_physics var interact_layer_mask: int = 0b00001001  # layers 1 + 4
## Optional speed multiplier driven by SurvivalManager-derived modifiers
## (e.g. hunger penalty). Updated externally; defaults to 1.0.
@export var speed_scale: float = 1.0
## Mouse-look — rotation per pixel of mouse motion. Tuned for the demo;
## production will move this to a per-user settings resource.
@export var mouse_sensitivity_rad_per_pixel: float = 0.003
## Pitch clamps so the player can't somersault. Roughly ±80 degrees.
@export var pitch_min_rad: float = -1.4
@export var pitch_max_rad: float = 1.4
## Path to the first-person camera (relative to this node). Resolved on
## _ready into _camera; left null if the path doesn't resolve so unit
## tests that build a PlayerCharacter without a camera still work.
@export var camera_path: NodePath = NodePath("Camera3D")

# Input intent — populated by a higher-level input layer; tests poke
# these directly to drive _physics_process. Pubvars first per
# .gdlintrc class-definitions-order rule.
var move_input: Vector2 = Vector2.ZERO
var request_jump: bool = false
var request_dive_down: bool = false
var request_dive_up: bool = false

# State seams that also let unit tests bind without a scene tree.
var _water_field: Node = null
var _survival: SurvivalManager = null
var _inventory: Inventory = null
var _state: int = PlayerLocomotion.LocomotionState.GROUND
var _focused_interactable: Node = null
var _camera: Camera3D = null


func _ready() -> void:
	if not water_field_path.is_empty():
		_water_field = get_node_or_null(water_field_path)
	if not survival_manager_path.is_empty():
		_survival = get_node_or_null(survival_manager_path) as SurvivalManager
	if not inventory_path.is_empty():
		_inventory = get_node_or_null(inventory_path) as Inventory
	if not camera_path.is_empty():
		_camera = get_node_or_null(camera_path) as Camera3D
	_resync_state()


## First-person mouse-look. `delta_x` and `delta_y` are pixels of mouse
## motion (typically from InputEventMouseMotion.relative). Rotates the
## body around world Y for yaw and the camera around its local X for
## pitch, with pitch clamped to [pitch_min_rad, pitch_max_rad].
##
## Public so PlayerInputController (or remote-input replays) can drive
## look without depending on Godot's Input singleton.
func apply_mouse_look(delta_x: float, delta_y: float) -> void:
	rotate_y(-delta_x * mouse_sensitivity_rad_per_pixel)
	if _camera == null:
		return
	var new_pitch: float = clampf(
		_camera.rotation.x - delta_y * mouse_sensitivity_rad_per_pixel,
		pitch_min_rad,
		pitch_max_rad
	)
	_camera.rotation.x = new_pitch


## Test seam: bind a Camera3D directly without going through scene-tree
## paths. Production code resolves the camera in _ready.
func bind_camera(camera: Camera3D) -> void:
	_camera = camera


## Convenience accessors used by Interactables.
func get_survival_manager() -> SurvivalManager:
	return _survival


func get_inventory() -> Inventory:
	return _inventory


## Test seam: bind dependencies without going through scene-tree paths.
func bind_dependencies(water_field: Node, survival: SurvivalManager) -> void:
	_water_field = water_field
	_survival = survival
	_resync_state()


## Test seam: optionally bind an inventory after construction.
func bind_inventory(inventory: Inventory) -> void:
	_inventory = inventory


func _physics_process(delta: float) -> void:
	_resync_state()
	velocity = (
		PlayerLocomotion
		. compute_velocity(
			_state,
			velocity,
			global_transform.basis,
			move_input,
			request_jump,
			request_dive_down,
			request_dive_up,
			delta,
			speed_scale,
		)
	)
	move_and_slide()
	_sync_survival_diving()
	_update_focused_interactable()
	# request_jump is rising-edge only; consume after the tick.
	request_jump = false


## Drive a single physics step from a unit test that has not put the
## node into the SceneTree's _physics_process path.
func step_for_test(delta: float) -> void:
	_resync_state()
	velocity = (
		PlayerLocomotion
		. compute_velocity(
			_state,
			velocity,
			global_transform.basis,
			move_input,
			request_jump,
			request_dive_down,
			request_dive_up,
			delta,
			speed_scale,
		)
	)
	# Skip move_and_slide (requires a real space) and interactable raycast.
	_sync_survival_diving()
	request_jump = false


func get_locomotion_state() -> int:
	return _state


func get_focused_interactable() -> Node:
	return _focused_interactable


func _resync_state() -> void:
	var water_y: Variant = _sample_water_y()
	var prev: int = _state
	_state = PlayerLocomotion.compute_state(global_position.y, water_y, is_on_floor())
	if _state != prev:
		locomotion_state_changed.emit(_state)


func _sample_water_y() -> Variant:
	if _water_field == null:
		return null
	if not _water_field.has_method("get_water_height"):
		return null
	return _water_field.call("get_water_height", global_position)


func _sync_survival_diving() -> void:
	if _survival == null:
		return
	_survival.set_diving(PlayerLocomotion.is_diving(_state))


func _update_focused_interactable() -> void:
	# Skip when not yet inside the scene tree (e.g. early in setup).
	var world: World3D = get_world_3d()
	if world == null:
		return
	var space_state: PhysicsDirectSpaceState3D = world.direct_space_state
	if space_state == null:
		return
	var origin: Vector3 = global_position + Vector3.UP * interact_origin_height_m
	var forward: Vector3 = -global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(
		origin, origin + forward * interact_range_m, interact_layer_mask
	)
	query.exclude = [self]
	var hit: Dictionary = space_state.intersect_ray(query)
	var new_focus: Node = null
	if not hit.is_empty():
		var collider: Node = hit.get("collider", null) as Node
		new_focus = _find_interactable_in_collider(collider)
	if new_focus != _focused_interactable:
		_focused_interactable = new_focus
		if new_focus == null:
			interactable_lost.emit()
		else:
			interactable_focused.emit(new_focus)


## A part's StaticBody3D root carries an Interactable child (per
## PartFactory). The raycast hits the StaticBody3D, so we walk one
## level down to find the actual Interactable.
func _find_interactable_in_collider(collider: Node) -> Interactable:
	if collider == null:
		return null
	if collider is Interactable:
		return collider as Interactable
	for child in collider.get_children():
		if child is Interactable:
			return child as Interactable
	return null


## Hook called by the input layer when the interact key is pressed.
## Returns the focused Node if any (so callers can treat it as a "use"
## verb on storage / water_purifier / etc.).
func interact() -> Node:
	return _focused_interactable
