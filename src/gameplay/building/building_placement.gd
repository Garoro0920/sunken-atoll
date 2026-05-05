class_name BuildingPlacement
extends Node

## Places building parts into the world with snapping and structural validation.
##
## Per specs/features/building_system.md §3.4 / §3.6 / §3.7.
## Stays input-agnostic: the placement validation and commit are pure
## functions that gameplay code (or tests) can drive directly. A higher-
## level PlayerBuildingInput script will translate keyboard/mouse into
## try_place() calls in a later iteration.

signal part_placed(part: Node3D, definition: BuildingPartDefinition)
signal placement_rejected(reason: String, definition: BuildingPartDefinition)

## Optional: inject a StructuralIntegrity to update on commit. If null
## the placement still succeeds but no adjacency tracking happens.
@export var integrity: StructuralIntegrity

## Parent node where committed parts are added as children (e.g. the
## "Base" Node3D in a level scene).
@export var parts_root: Node3D

## Lateral snap grid (XZ plane). Y is determined by support height.
@export var snap_step_m: float = 1.0

## Maximum vertical distance from a candidate position to a supporter
## surface for adjacency to be considered valid.
@export var support_proximity_m: float = 0.25


## Commit a part at the requested transform. Returns the spawned node on
## success, or null on rejection. The reason for rejection is broadcast
## via placement_rejected.
##
## To keep the function unit-testable, the part itself is constructed by
## a `factory` callable that returns a Node3D. Production code will pass
## a closure that instantiates the matching .tscn for the definition.
func try_place(
	definition: BuildingPartDefinition,
	position_m: Vector3,
	rotation_y_rad: float,
	factory: Callable
) -> Node3D:
	if definition == null:
		_reject(definition, "definition_null")
		return null
	if parts_root == null:
		_reject(definition, "parts_root_unbound")
		return null

	var snapped_pos: Vector3 = snap_to_grid(position_m, definition.snap_step_m)

	if not _passes_support_check(definition, snapped_pos):
		_reject(definition, "no_supporting_part_in_proximity")
		return null

	if not _passes_max_count_check(definition):
		_reject(definition, "max_per_base_exceeded")
		return null

	var instance: Node3D = factory.call(definition) as Node3D
	if instance == null:
		_reject(definition, "factory_returned_null")
		return null
	instance.position = snapped_pos
	instance.rotation.y = rotation_y_rad
	parts_root.add_child(instance)

	if integrity != null and instance is FloatingNode:
		# Foundation parts are registered as foundation; everything else
		# is registered as a dependent. Adjacency wiring (add_support)
		# happens in _connect_to_neighbors.
		var fn: FloatingNode = instance as FloatingNode
		integrity.register_node(fn, definition.is_self_supporting)
		_connect_to_neighbors(definition, fn, snapped_pos)

	part_placed.emit(instance, definition)
	return instance


## Snap a position to the configured grid step. Y is preserved.
func snap_to_grid(position_m: Vector3, step_m: float) -> Vector3:
	if step_m <= 0.0:
		return position_m
	return Vector3(
		roundf(position_m.x / step_m) * step_m, position_m.y, roundf(position_m.z / step_m) * step_m
	)


## Pure check: does the proposed position have a valid supporter nearby?
## Foundations are self-supporting; other categories must find a
## compatible neighbor in support_proximity_m below or beside them.
func _passes_support_check(definition: BuildingPartDefinition, position_m: Vector3) -> bool:
	if definition.is_self_supporting:
		return true
	if parts_root == null:
		return false
	for child in parts_root.get_children():
		var neighbor: Node3D = child as Node3D
		if neighbor == null or not neighbor.has_meta("definition"):
			continue
		var neighbor_def: BuildingPartDefinition = neighbor.get_meta("definition")
		if not neighbor_def.can_support(definition.category):
			continue
		if not definition.can_be_supported_by(neighbor_def.category):
			continue
		if (
			neighbor.position.distance_to(position_m)
			<= support_proximity_m + maxf(definition.size_m.length(), neighbor_def.size_m.length())
		):
			return true
	return false


func _passes_max_count_check(definition: BuildingPartDefinition) -> bool:
	if definition.max_per_base <= 0:
		return true
	var count: int = 0
	for child in parts_root.get_children():
		if not (child is Node3D):
			continue
		if not (child as Node3D).has_meta("definition"):
			continue
		if (child as Node3D).get_meta("definition").id == definition.id:
			count += 1
	return count < definition.max_per_base


## Walk neighbors and call integrity.add_support for compatible pairs so
## the support graph reflects the freshly placed node.
func _connect_to_neighbors(
	definition: BuildingPartDefinition, instance: FloatingNode, snapped_pos: Vector3
) -> void:
	if integrity == null:
		return
	for child in parts_root.get_children():
		if child == instance:
			continue
		var neighbor: Node3D = child as Node3D
		if neighbor == null or not neighbor.has_meta("definition"):
			continue
		var neighbor_def: BuildingPartDefinition = neighbor.get_meta("definition")
		var neighbor_node: FloatingNode = neighbor as FloatingNode
		if neighbor_node == null:
			continue
		if (
			neighbor.position.distance_to(snapped_pos)
			> support_proximity_m + maxf(definition.size_m.length(), neighbor_def.size_m.length())
		):
			continue
		# neighbor supports this new part
		if (
			neighbor_def.can_support(definition.category)
			and definition.can_be_supported_by(neighbor_def.category)
		):
			integrity.add_support(neighbor_node, instance)
		# this new part may itself support the neighbor (e.g. wall placed before roof)
		if (
			definition.can_support(neighbor_def.category)
			and neighbor_def.can_be_supported_by(definition.category)
		):
			integrity.add_support(instance, neighbor_node)


func _reject(definition: BuildingPartDefinition, reason: String) -> void:
	placement_rejected.emit(reason, definition)
