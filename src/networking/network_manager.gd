class_name NetworkManager
extends Node

## Single entry point for the multiplayer prototype.
## Per specs/features/multiplayer_session.md §3 and specs/epics/prototype_phase.md §6.
##
## MVP backend: ENet (built-in). The GodotSteam Lobby path is stubbed and will be
## wired in once the GDExtension is added per docs/02_services/version_policy.md §9.1.
## Both backends share this front-end API so call sites stay backend-agnostic.

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connected_to_server
signal connection_failed
signal server_disconnected

const DEFAULT_PORT: int = 4242
const MAX_PLAYERS: int = 4  # MVP per multiplayer_session.md §3.2

enum Backend { ENET, STEAM }

var backend: Backend = Backend.ENET
var connected_peers: Array[int] = []


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_server(port: int = DEFAULT_PORT) -> bool:
	match backend:
		Backend.ENET:
			var peer := ENetMultiplayerPeer.new()
			var err := peer.create_server(port, MAX_PLAYERS)
			if err != OK:
				push_error("ENet host failed: %s" % error_string(err))
				return false
			multiplayer.multiplayer_peer = peer
			connected_peers.append(1)  # Host id
			return true
		Backend.STEAM:
			# TODO: GodotSteam Lobby creation. Stubbed pending GDExtension install
			# (docs/02_services/version_policy.md §9.1: GodotSteam 4.18.1).
			push_warning("Steam backend not yet wired. Falling back to ENet.")
			backend = Backend.ENET
			return host_server(port)
	return false


func join_server(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> bool:
	match backend:
		Backend.ENET:
			var peer := ENetMultiplayerPeer.new()
			var err := peer.create_client(address, port)
			if err != OK:
				push_error("ENet join failed: %s" % error_string(err))
				return false
			multiplayer.multiplayer_peer = peer
			return true
		Backend.STEAM:
			push_warning("Steam backend not yet wired. Falling back to ENet.")
			backend = Backend.ENET
			return join_server(address, port)
	return false


func disconnect_from_session() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	connected_peers.clear()


func is_host() -> bool:
	return multiplayer.is_server()


func get_local_peer_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return 0
	return multiplayer.get_unique_id()


func _on_peer_connected(peer_id: int) -> void:
	if not connected_peers.has(peer_id):
		connected_peers.append(peer_id)
	player_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	connected_peers.erase(peer_id)
	player_disconnected.emit(peer_id)


func _on_connected() -> void:
	connected_to_server.emit()


func _on_connection_failed() -> void:
	connection_failed.emit()
	disconnect_from_session()


func _on_server_disconnected() -> void:
	server_disconnected.emit()
	disconnect_from_session()
