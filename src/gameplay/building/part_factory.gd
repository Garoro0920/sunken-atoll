class_name PartFactory
extends RefCounted

## Builds a runtime Node3D representation of a BuildingPartDefinition.
##
## Per specs/features/building_system.md §3.4 and §3.5. Sprint 1's
## stub factory used in PlayerInputController spawned a bare
## FloatingNode + collider, which made placed parts INVISIBLE and
## made the interact raycast pointless (no Interactable to focus).
## This factory replaces that stub with a proper built node:
##   - StaticBody3D root (placed parts don't need buoyancy on the
##     fixed island; the prototype-derived FloatingNode is reserved
##     for the actual floating-base scenes that will land in Sprint 2)
##   - MeshInstance3D child with a BoxMesh sized to the part
##   - CollisionShape3D child with a matching BoxShape3D
##   - For furniture / functional parts, an Interactable child of the
##     correct subclass so the player's interact raycast finds it via
##     PlayerCharacter._find_interactable_in_collider.
##
## A future iteration will swap the BoxMesh/StandardMaterial3D for
## real per-part .tscn prefabs; the public API (build(definition))
## stays the same.

const COLLISION_LAYER_WORLD := 1
const COLLISION_LAYER_INTERACTABLE := 1 << 3  # bit 4 (one-based: layer 4)


static func build(definition: BuildingPartDefinition) -> Node3D:
	var root := StaticBody3D.new()
	root.name = String(definition.id)
	root.set_meta("definition", definition)
	root.collision_layer = COLLISION_LAYER_WORLD
	root.collision_mask = COLLISION_LAYER_WORLD

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = definition.size_m
	mesh_inst.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = _color_for_category(definition.category)
	mesh_inst.material_override = material
	root.add_child(mesh_inst)

	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = definition.size_m
	col_shape.shape = box_shape
	root.add_child(col_shape)

	var interactable: Interactable = _maybe_create_interactable(definition)
	if interactable != null:
		interactable.name = "Interactable"
		root.add_child(interactable)
		# Add the interactable layer so the player raycast (which masks
		# both world and interactable layers) hits this body and we then
		# walk up to the Interactable child.
		root.collision_layer |= COLLISION_LAYER_INTERACTABLE

	return root


static func _maybe_create_interactable(definition: BuildingPartDefinition) -> Interactable:
	match definition.id:
		T1PartCatalog.ID_BED:
			var bed := BedInteractable.new()
			bed.display_label = "Sleep"
			return bed
		T1PartCatalog.ID_STORAGE:
			var storage := StorageInteractable.new()
			storage.display_label = "Open Storage"
			# Each storage instance owns its own internal Inventory.
			storage.stored = Inventory.new()
			return storage
		T1PartCatalog.ID_WATER_PURIFIER:
			var purifier := WaterPurifierInteractable.new()
			purifier.display_label = "Collect Water"
			return purifier
	return null


static func _color_for_category(category: int) -> Color:
	match category:
		BuildingPartDefinition.Category.FOUNDATION:
			return Color(0.62, 0.42, 0.22)  # weathered wood
		BuildingPartDefinition.Category.FLOOR:
			return Color(0.74, 0.56, 0.32)  # plank
		BuildingPartDefinition.Category.WALL:
			return Color(0.55, 0.42, 0.26)  # darker plank
		BuildingPartDefinition.Category.ROOF:
			return Color(0.42, 0.30, 0.18)  # darkest plank
		BuildingPartDefinition.Category.FURNITURE:
			return Color(0.28, 0.50, 0.72)  # blue-ish for utility
		BuildingPartDefinition.Category.FUNCTIONAL:
			return Color(0.40, 0.72, 0.55)  # teal-green for machine
	return Color(1, 1, 1)
