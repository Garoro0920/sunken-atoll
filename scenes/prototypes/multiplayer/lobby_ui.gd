extends Control

## Minimal lobby UI for the multiplayer prototype.
## Buttons trigger host / join via the parent test controller.

@export var test_controller_path: NodePath
@export var address_field_path: NodePath
@export var status_label_path: NodePath
@export var net_manager_path: NodePath

@onready var _ctrl: Node = get_node(test_controller_path)
@onready var _addr: LineEdit = get_node(address_field_path)
@onready var _status: Label = get_node(status_label_path)
@onready var _net: NetworkManager = get_node(net_manager_path)


func _ready() -> void:
	_net.player_connected.connect(_refresh_status)
	_net.player_disconnected.connect(_refresh_status)
	_net.connection_failed.connect(_on_failed)
	_net.server_disconnected.connect(_on_server_dc)


func _on_host_pressed() -> void:
	if _ctrl.call("host"):
		_status.text = "Hosting on port %d" % NetworkManager.DEFAULT_PORT
	else:
		_status.text = "Failed to host."


func _on_join_pressed() -> void:
	var addr := _addr.text.strip_edges()
	if addr.is_empty():
		addr = "127.0.0.1"
	if _ctrl.call("join", addr):
		_status.text = "Connecting to %s..." % addr
	else:
		_status.text = "Join attempt failed."


func _refresh_status(_peer_id: int = 0) -> void:
	_status.text = "Peers: %d" % _net.connected_peers.size()


func _on_failed() -> void:
	_status.text = "Connection failed."


func _on_server_dc() -> void:
	_status.text = "Server disconnected."
