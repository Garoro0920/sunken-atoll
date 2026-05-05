extends Node3D

## Spawns N floating nodes in a regular grid for the floating physics benchmark.
## Per specs/epics/prototype_phase.md §5.2 — supports the 100/250/500 cohort sizes.

@export var spawn_count: int = 100
@export var grid_spacing: float = 1.5
@export var spawn_origin_y: float = 1.0
@export var floating_node_scene: PackedScene
@export var water_field_path: NodePath
@export var register_with_integrity: bool = true

@onready var _integrity: StructuralIntegrity = get_node_or_null("../StructuralIntegrity") as StructuralIntegrity


func _ready() -> void:
	if floating_node_scene == null:
		push_warning("PhysicsSpawner has no floating_node_scene assigned.")
		return
	var side: int = int(ceil(sqrt(float(spawn_count))))
	var spawned: int = 0
	for i in side:
		for j in side:
			if spawned >= spawn_count:
				return
			var node: FloatingNode = floating_node_scene.instantiate()
			node.water_field_path = water_field_path
			node.position = Vector3(
				(float(i) - float(side) * 0.5) * grid_spacing,
				spawn_origin_y,
				(float(j) - float(side) * 0.5) * grid_spacing
			)
			add_child(node)
			if register_with_integrity and _integrity != null:
				# First column treated as foundation for the support test.
				_integrity.register_node(node, j == 0)
			spawned += 1
