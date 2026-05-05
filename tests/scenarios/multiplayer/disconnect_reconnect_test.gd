extends GdUnitTestSuite

## Disconnect/reconnect scenario.
## Per specs/epics/prototype_phase.md §6.4 — verifies disconnect detection
## (≤ 5 sec) and successful reconnection.

const NetworkManagerScript := preload("res://src/networking/network_manager.gd")
const TEST_PORT: int = 34245


func test_client_disconnect_is_detected() -> void:
	var host: NetworkManager = _make_node()
	assert_bool(host.host_server(TEST_PORT)).is_true()

	var client: NetworkManager = _make_node()
	assert_bool(client.join_server("127.0.0.1", TEST_PORT)).is_true()

	# Wait for connection.
	var deadline: int = Time.get_ticks_msec() + 30_000
	while host.connected_peers.size() < 2 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_int(host.connected_peers.size()).is_equal(2)

	# Drop the client.
	client.disconnect_from_session()

	# Host should detect within 5 seconds (multiplayer_session.md §3.6).
	deadline = Time.get_ticks_msec() + 5_000
	while host.connected_peers.size() > 1 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_int(host.connected_peers.size()).is_equal(1)

	host.disconnect_from_session()


func test_client_can_reconnect() -> void:
	var host: NetworkManager = _make_node()
	assert_bool(host.host_server(TEST_PORT + 1)).is_true()

	var client: NetworkManager = _make_node()
	assert_bool(client.join_server("127.0.0.1", TEST_PORT + 1)).is_true()
	await _await_peers(host, 2, 30_000)

	client.disconnect_from_session()
	await _await_peers(host, 1, 5_000)

	# Reconnect.
	assert_bool(client.join_server("127.0.0.1", TEST_PORT + 1)).is_true()
	await _await_peers(host, 2, 30_000)
	assert_int(host.connected_peers.size()).is_equal(2)

	client.disconnect_from_session()
	host.disconnect_from_session()


func _make_node() -> NetworkManager:
	var n: NetworkManager = NetworkManagerScript.new()
	add_child(n)
	return n


func _await_peers(net: NetworkManager, target: int, timeout_ms: int) -> void:
	var deadline: int = Time.get_ticks_msec() + timeout_ms
	while net.connected_peers.size() != target and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
