class_name StructuralIntegrity
extends Node

## Tracks support relationships between FloatingNode parts and triggers
## collapse on parts that lose their support chain.
##
## Per specs/features/building_system.md §3.3.

## Adjacency map: id (NodePath) -> Array[id]
var _supports_for: Dictionary = {}
## Reverse map: id -> Array[id] (which nodes are supported BY this one)
var _supported_by: Dictionary = {}
## Foundation set: nodes considered self-supporting (e.g. base floats).
var _foundations: Dictionary = {}


func register_node(node: FloatingNode, is_foundation: bool = false) -> void:
	var id: NodePath = node.get_path()
	_supports_for[id] = []
	_supported_by[id] = []
	if is_foundation:
		_foundations[id] = true


func add_support(supporter: FloatingNode, dependent: FloatingNode) -> void:
	var s: NodePath = supporter.get_path()
	var d: NodePath = dependent.get_path()
	if not _supports_for.has(s):
		register_node(supporter)
	if not _supports_for.has(d):
		register_node(dependent)
	if not _supports_for[s].has(d):
		_supports_for[s].append(d)
	if not _supported_by[d].has(s):
		_supported_by[d].append(s)


func unregister_node(node: FloatingNode) -> void:
	var id: NodePath = node.get_path()
	if _supports_for.has(id):
		for dependent_id: NodePath in _supports_for[id]:
			if _supported_by.has(dependent_id):
				_supported_by[dependent_id].erase(id)
		_supports_for.erase(id)
	if _supported_by.has(id):
		_supported_by.erase(id)
	_foundations.erase(id)


## Recompute support reachability and trigger collapse on orphans.
## Returns the count of nodes that were newly marked unsupported.
func recompute() -> int:
	var reachable: Dictionary = {}
	# Dictionary.keys() returns untyped Array; convert via assign() to keep
	# the typed-array contract for stack.
	var stack: Array[NodePath] = []
	stack.assign(_foundations.keys())
	while not stack.is_empty():
		var current: NodePath = stack.pop_back()
		if reachable.has(current):
			continue
		reachable[current] = true
		if _supports_for.has(current):
			for dependent_id: NodePath in _supports_for[current]:
				stack.push_back(dependent_id)

	var newly_unsupported: int = 0
	for id: NodePath in _supports_for.keys():
		var node: Node = get_node_or_null(id)
		if node == null or not (node is FloatingNode):
			continue
		var fnode: FloatingNode = node
		if not reachable.has(id) and fnode.is_supported():
			fnode.mark_unsupported()
			fnode.begin_collapse()
			newly_unsupported += 1
	return newly_unsupported
