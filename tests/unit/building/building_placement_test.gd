extends GdUnitTestSuite

## Tests for BuildingPlacement + StructuralIntegrity integration.
## Per specs/features/building_system.md §3.4 / §3.6 / §3.7.

const SHAPE_SIZE := Vector3(0.4, 0.2, 0.4)


func _make_floating_node(definition: BuildingPartDefinition) -> FloatingNode:
	# Tests use a minimal FloatingNode without buoyancy sampling so the
	# structural-integrity wiring is exercised without physics noise.
	var node: FloatingNode = FloatingNode.new()
	node.displaced_volume = definition.displaced_volume
	node.sample_extents = (
		definition.sample_extents
		if definition.sample_extents.length_squared() > 0.0
		else SHAPE_SIZE
	)
	node.set_meta("definition", definition)
	# A bare RigidBody3D without a collider would assert in Godot, so we
	# attach a small box shape.
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SHAPE_SIZE
	col.shape = box
	node.add_child(col)
	return node


func _factory(definition: BuildingPartDefinition) -> Node3D:
	return _make_floating_node(definition)


func _make_placement() -> BuildingPlacement:
	var placement := BuildingPlacement.new()
	add_child(placement)
	placement.parts_root = Node3D.new()
	add_child(placement.parts_root)
	placement.integrity = StructuralIntegrity.new()
	add_child(placement.integrity)
	placement.support_proximity_m = 5.0  # generous for unit-test geometry
	return placement


func test_snap_to_grid_rounds_xz_only() -> void:
	var placement := _make_placement()
	var snapped: Vector3 = placement.snap_to_grid(Vector3(0.4, 1.5, 0.6), 1.0)
	assert_float(snapped.x).is_equal_approx(0.0, 1e-5)
	assert_float(snapped.y).is_equal_approx(1.5, 1e-5)
	assert_float(snapped.z).is_equal_approx(1.0, 1e-5)


func test_snap_returns_input_when_step_zero() -> void:
	var placement := _make_placement()
	var p: Vector3 = Vector3(1.7, 2.0, 3.3)
	assert_vector(placement.snap_to_grid(p, 0.0)).is_equal(p)


func test_foundation_places_without_supporter() -> void:
	var placement := _make_placement()
	var foundation_def: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_FOUNDATION)
	var instance: Node3D = placement.try_place(foundation_def, Vector3.ZERO, 0.0, _factory)
	assert_object(instance).is_not_null()
	assert_int(placement.parts_root.get_child_count()).is_equal(1)


func test_floor_rejected_without_foundation() -> void:
	var placement := _make_placement()
	var floor_def: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_FLOOR)
	var rejected: Array = []
	placement.placement_rejected.connect(
		func(reason: String, _d: BuildingPartDefinition) -> void: rejected.append(reason)
	)
	var instance: Node3D = placement.try_place(floor_def, Vector3.ZERO, 0.0, _factory)
	assert_object(instance).is_null()
	assert_array(rejected).contains(["no_supporting_part_in_proximity"])


func test_floor_accepts_foundation_neighbor() -> void:
	var placement := _make_placement()
	# Place a foundation, then try to place a floor slightly above it.
	var foundation: Node3D = placement.try_place(
		T1PartCatalog.find(T1PartCatalog.ID_FOUNDATION), Vector3.ZERO, 0.0, _factory
	)
	assert_object(foundation).is_not_null()
	var floor_node: Node3D = placement.try_place(
		T1PartCatalog.find(T1PartCatalog.ID_FLOOR), Vector3(0.0, 0.5, 0.0), 0.0, _factory
	)
	assert_object(floor_node).is_not_null()


func test_max_per_base_limits_bed_count() -> void:
	var placement := _make_placement()
	# Set up: foundation + floor (return values intentionally discarded).
	placement.try_place(
		T1PartCatalog.find(T1PartCatalog.ID_FOUNDATION), Vector3.ZERO, 0.0, _factory
	)
	placement.try_place(
		T1PartCatalog.find(T1PartCatalog.ID_FLOOR), Vector3(0.0, 0.5, 0.0), 0.0, _factory
	)
	var bed_def: BuildingPartDefinition = T1PartCatalog.find(T1PartCatalog.ID_BED)
	# Place 4 beds successfully; the 5th should be rejected.
	for i in 4:
		var bed: Node3D = placement.try_place(bed_def, Vector3(float(i), 0.7, 0.0), 0.0, _factory)
		assert_object(bed).is_not_null()
	var fifth: Node3D = placement.try_place(bed_def, Vector3(5.0, 0.7, 0.0), 0.0, _factory)
	assert_object(fifth).is_null()


func test_integrity_marks_orphan_floor_unsupported_when_foundation_unregistered() -> void:
	var placement := _make_placement()
	var foundation: Node3D = placement.try_place(
		T1PartCatalog.find(T1PartCatalog.ID_FOUNDATION), Vector3.ZERO, 0.0, _factory
	)
	var floor_node: Node3D = placement.try_place(
		T1PartCatalog.find(T1PartCatalog.ID_FLOOR), Vector3(0.0, 0.5, 0.0), 0.0, _factory
	)
	# Sanity: integrity recompute reports zero new orphans while connected.
	assert_int(placement.integrity.recompute()).is_equal(0)
	# Remove the foundation from the integrity tracker → floor becomes orphan.
	placement.integrity.unregister_node(foundation as FloatingNode)
	assert_int(placement.integrity.recompute()).is_greater_equal(1)
	# The floor itself is still in the scene; integrity flagged it for collapse.
	assert_bool((floor_node as FloatingNode).is_supported()).is_false()
