extends Node

## Bootstrap controller for the multiplayer prototype scene.
## Spawns a player capsule for the local peer on host/join, and for every
## remote peer that connects.
##
## Per specs/epics/prototype_phase.md §6.3.

const PLAYER_SCENE := preload("res://scenes/prototypes/multiplayer/player.tscn")

@export var network_manager_path: NodePath
@export var spawn_root_path: NodePath

@onready var _net: NetworkManager = get_node(network_manager_path)
@onready var _spawn_root: Node3D = get_node(spawn_root_path)


func _ready() -> void:
	_net.player_connected.connect(_on_player_connected)
	_net.player_disconnected.connect(_on_player_disconnected)
	_net.connected_to_server.connect(_on_self_connected)


func host() -> bool:
	if _net.host_server():
		_spawn_player_for(_net.get_local_peer_id())
		return true
	return false


func join(address: String = "127.0.0.1") -> bool:
	return _net.join_server(address)


func _on_player_connected(peer_id: int) -> void:
	# Server spawns players for connecting peers.
	if _net.is_host():
		_spawn_player_for(peer_id)


func _on_self_connected() -> void:
	_spawn_player_for(_net.get_local_peer_id())


func _on_player_disconnected(peer_id: int) -> void:
	var name := "Player_%d" % peer_id
	if _spawn_root.has_node(name):
		_spawn_root.get_node(name).queue_free()


func _spawn_player_for(peer_id: int) -> void:
	if peer_id <= 0:
		return
	var name := "Player_%d" % peer_id
	if _spawn_root.has_node(name):
		return
	var p: ProtoPlayer = PLAYER_SCENE.instantiate()
	p.name = name
	p.peer_id = peer_id
	p.position = Vector3(randi_range(-3, 3), 1.0, randi_range(-3, 3))
	_spawn_root.add_child(p, true)
