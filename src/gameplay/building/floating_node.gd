class_name FloatingNode
extends RigidBody3D

## Floating body that samples water height and applies buoyancy + drag.
##
## Per specs/features/building_system.md §3.2 and specs/epics/prototype_phase.md §5.2.
##
## The water surface is approximated by sampling at N points around the body and
## integrating buoyancy force per point. This is intentionally simple for the
## prototype — the production version will share the analytical Gerstner field
## with the shader so visual and physical waves match exactly.
##
## Connections (rigid joints to neighbors) are managed by StructuralIntegrity.

const SAMPLE_GRID_SIDE: int = 3  # 3x3 = 9 buoyancy samples per body
const GRAVITY: float = 9.8

## Volume below the resting waterline (m^3) — used to compute buoyancy at full submersion.
@export var displaced_volume: float = 1.0
## Linear drag coefficient applied while in water.
@export var water_linear_drag: float = 0.8
## Angular drag coefficient applied while in water.
@export var water_angular_drag: float = 0.6
## Bounding extents (half-extents) for sampling around the body's local origin.
@export var sample_extents: Vector3 = Vector3(0.5, 0.0, 0.5)

## Reference to a node providing get_water_height(world_pos: Vector3) -> float.
@export var water_field_path: NodePath

var _water_field: Node = null
var _support_state: int = 0  # 0 = ok, 1 = unsupported, 2 = collapsing
var _collapse_timer: float = 0.0


func _ready() -> void:
	if not water_field_path.is_empty():
		_water_field = get_node_or_null(water_field_path)
	# Per specs/features/multiplayer_session.md §3.3, physics ticks are fixed.
	# Body settings here keep behavior deterministic across clients.
	custom_integrator = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _water_field == null:
		return
	var transform := state.transform
	var total_force := Vector3.ZERO
	var total_torque := Vector3.ZERO

	var sample_count: int = SAMPLE_GRID_SIDE * SAMPLE_GRID_SIDE
	var per_sample_volume: float = displaced_volume / float(sample_count)
	var step_x: float = (sample_extents.x * 2.0) / float(SAMPLE_GRID_SIDE - 1)
	var step_z: float = (sample_extents.z * 2.0) / float(SAMPLE_GRID_SIDE - 1)

	for i in SAMPLE_GRID_SIDE:
		for j in SAMPLE_GRID_SIDE:
			var local := Vector3(
				-sample_extents.x + float(i) * step_x,
				0.0,
				-sample_extents.z + float(j) * step_z
			)
			var world_pos: Vector3 = transform * local
			var water_y: float = _water_field.call("get_water_height", world_pos)
			var depth: float = water_y - world_pos.y
			if depth <= 0.0:
				continue
			# Submerged. Apply buoyancy force at this sample point.
			var submerged_fraction: float = clampf(depth / max(sample_extents.y * 2.0, 0.5), 0.0, 1.0)
			var force_mag: float = GRAVITY * per_sample_volume * 1000.0 * submerged_fraction
			var sample_force := Vector3.UP * force_mag
			total_force += sample_force
			total_torque += (world_pos - transform.origin).cross(sample_force)

	state.apply_central_force(total_force)
	state.apply_torque(total_torque)

	# Submerged drag (proportional to fraction of points below water).
	var any_submerged: bool = total_force.length_squared() > 0.0
	if any_submerged:
		state.linear_velocity *= 1.0 - clampf(water_linear_drag * state.step, 0.0, 1.0)
		state.angular_velocity *= 1.0 - clampf(water_angular_drag * state.step, 0.0, 1.0)

	# Collapse handling: unsupported pieces fall under gravity for `_collapse_timer`
	# seconds before being despawned, giving the player a chance to rescue.
	if _support_state == 2:
		_collapse_timer -= state.step
		if _collapse_timer <= 0.0:
			queue_free()


func mark_unsupported() -> void:
	if _support_state == 0:
		_support_state = 1


func begin_collapse(grace_seconds: float = 3.0) -> void:
	if _support_state != 2:
		_support_state = 2
		_collapse_timer = grace_seconds


func is_supported() -> bool:
	return _support_state == 0
