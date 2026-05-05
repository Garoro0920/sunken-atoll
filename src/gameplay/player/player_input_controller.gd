class_name PlayerInputController
extends Node

## Routes keyboard / mouse input to PlayerCharacter and BuildingPlacement.
##
## Per specs/features/building_system.md §3.4 (placement) and
## specs/features/survival_balance.md §3 (interact -> use), and the
## PlayerCharacter input intent fields (move_input, request_*, interact()).
##
## Design: _process polls the Godot Input singleton and packs the
## result into a snapshot Dictionary, then forwards to apply_snapshot.
## All state-changing logic lives in apply_snapshot, so unit tests can
## drive the controller without involving the Input singleton or a real
## InputMap registration.

signal build_mode_changed(active: bool)
signal selected_part_changed(part_id: StringName)
signal interact_failed(reason: String)

const ACTION_MOVE_FORWARD := &"move_forward"
const ACTION_MOVE_BACK := &"move_back"
const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"
const ACTION_JUMP := &"jump"
const ACTION_DIVE_UP := &"dive_up"
const ACTION_DIVE_DOWN := &"dive_down"
const ACTION_INTERACT := &"interact"
const ACTION_BUILD_TOGGLE := &"build_toggle"
const ACTION_BUILD_PLACE := &"build_place"
const ACTION_BUILD_NEXT := &"build_next"
const ACTION_BUILD_PREV := &"build_prev"

@export var player: PlayerCharacter
@export var building_placement: BuildingPlacement
## Distance in meters in front of the player to attempt placement.
@export var place_distance_m: float = 2.0
## Override the part palette for tests / prototypes; defaults to the
## full T1 catalog when empty.
@export var available_parts: Array[StringName] = []

var build_mode_active: bool = false
var selected_part_index: int = 0


func _ready() -> void:
	if available_parts.is_empty():
		# Use a member assignment (not setter) so listeners don't fire on
		# initialization.
		available_parts = T1PartCatalog.ALL_IDS.duplicate()
	# Fallback: when the controller is a direct child of a PlayerCharacter
	# and the .tscn export wiring didn't resolve (Godot 4.6 sometimes
	# leaves typed-Node @export NodePath assignments unresolved at scene
	# instantiation time), pick the parent up automatically.
	if player == null:
		var parent: Node = get_parent()
		if parent is PlayerCharacter:
			player = parent as PlayerCharacter


func _process(_delta: float) -> void:
	if player == null:
		return
	apply_snapshot(read_input_snapshot())


## Public so tests can construct an arbitrary snapshot without poking
## the Input singleton. Production code calls this from _process via
## read_input_snapshot.
func apply_snapshot(snapshot: Dictionary) -> void:
	if player == null:
		return
	player.move_input = Vector2(
		float(snapshot.get(&"strafe", 0.0)), float(snapshot.get(&"forward", 0.0))
	)
	if bool(snapshot.get(&"jump_pressed", false)):
		player.request_jump = true
	player.request_dive_down = bool(snapshot.get(&"dive_down", false))
	player.request_dive_up = bool(snapshot.get(&"dive_up", false))
	if bool(snapshot.get(&"interact_pressed", false)):
		_try_interact()
	if bool(snapshot.get(&"build_toggle_pressed", false)):
		_set_build_mode(not build_mode_active)
	if bool(snapshot.get(&"build_next_pressed", false)):
		_cycle_part(1)
	if bool(snapshot.get(&"build_prev_pressed", false)):
		_cycle_part(-1)
	if build_mode_active and bool(snapshot.get(&"build_place_pressed", false)):
		_try_place_at_cursor()


## Pure-function helper: build a snapshot from current Input singleton
## state. Public so production callers can override / combine snapshots
## (e.g. a remote player sending input over the wire).
func read_input_snapshot() -> Dictionary:
	return {
		&"strafe":
		Input.get_action_strength(ACTION_MOVE_RIGHT) - Input.get_action_strength(ACTION_MOVE_LEFT),
		&"forward":
		(
			Input.get_action_strength(ACTION_MOVE_BACK)
			- Input.get_action_strength(ACTION_MOVE_FORWARD)
		),
		&"jump_pressed": Input.is_action_just_pressed(ACTION_JUMP),
		&"dive_down": Input.is_action_pressed(ACTION_DIVE_DOWN),
		&"dive_up": Input.is_action_pressed(ACTION_DIVE_UP),
		&"interact_pressed": Input.is_action_just_pressed(ACTION_INTERACT),
		&"build_toggle_pressed": Input.is_action_just_pressed(ACTION_BUILD_TOGGLE),
		&"build_next_pressed": Input.is_action_just_pressed(ACTION_BUILD_NEXT),
		&"build_prev_pressed": Input.is_action_just_pressed(ACTION_BUILD_PREV),
		&"build_place_pressed": Input.is_action_just_pressed(ACTION_BUILD_PLACE),
	}


func get_selected_part_id() -> StringName:
	if available_parts.is_empty():
		return &""
	var idx: int = clampi(selected_part_index, 0, available_parts.size() - 1)
	return available_parts[idx]


# --- Internal handlers ---


func _try_interact() -> void:
	var target: Node = player.interact()
	if target == null:
		interact_failed.emit("no_focus")
		return
	if not (target is Interactable):
		interact_failed.emit("focus_not_interactable")
		return
	(target as Interactable).use(player)


func _set_build_mode(active: bool) -> void:
	if active == build_mode_active:
		return
	build_mode_active = active
	build_mode_changed.emit(active)


func _cycle_part(direction: int) -> void:
	if available_parts.is_empty():
		return
	var n: int = available_parts.size()
	selected_part_index = (selected_part_index + direction + n) % n
	selected_part_changed.emit(available_parts[selected_part_index])


func _try_place_at_cursor() -> void:
	if building_placement == null or player == null:
		return
	var part_id: StringName = get_selected_part_id()
	if part_id == &"":
		return
	var definition: BuildingPartDefinition = T1PartCatalog.find(part_id)
	if definition == null:
		return
	var forward: Vector3 = -player.global_transform.basis.z
	var pos: Vector3 = player.global_position + forward * place_distance_m
	var rot_y: float = player.rotation.y
	# Production-shaped factory: PartFactory builds a visible StaticBody3D
	# with a mesh, collision, and (for furniture / functional categories)
	# the appropriate Interactable child.
	var factory := func(d: BuildingPartDefinition) -> Node3D: return PartFactory.build(d)
	building_placement.try_place(definition, pos, rot_y, factory)
