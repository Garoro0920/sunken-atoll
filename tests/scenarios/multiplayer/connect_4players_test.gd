extends GdUnitTestSuite

## 4-player connect scenario.
## Per specs/epics/prototype_phase.md §6.4 — single-process loopback host + 3 clients.
## Real Steam-friend invitation testing requires manual verification.

const NetworkManagerScript := preload("res://src/networking/network_manager.gd")
const TEST_PORT: int = 34244


func test_4_clients_can_connect() -> void:
	var host: NetworkManager = _make_node()
	assert_bool(host.host_server(TEST_PORT)).is_true()

	var clients: Array[NetworkManager] = []
	for i in 3:
		var c: NetworkManager = _make_node()
		assert_bool(c.join_server("127.0.0.1", TEST_PORT)).is_true()
		clients.append(c)

	# Wait up to 30 seconds for all peers to connect.
	var deadline: int = Time.get_ticks_msec() + 30_000
	while host.connected_peers.size() < 4 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame

	assert_int(host.connected_peers.size()).is_equal(4)

	for c in clients:
		c.disconnect_from_session()
	host.disconnect_from_session()


func _make_node() -> NetworkManager:
	var n: NetworkManager = NetworkManagerScript.new()
	add_child(n)
	return n
