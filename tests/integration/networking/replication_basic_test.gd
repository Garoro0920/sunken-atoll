extends GdUnitTestSuite

## Basic NetworkManager unit/integration test.
## Per specs/epics/prototype_phase.md §6.5 — verifies the host/join API
## surface works in a single-process loopback.

const NetworkManagerScript := preload("res://src/networking/network_manager.gd")


func test_host_starts_with_local_peer() -> void:
	var net: NetworkManager = NetworkManagerScript.new()
	add_child(net)
	var ok := net.host_server(34242)
	assert_bool(ok).is_true()
	assert_bool(net.is_host()).is_true()
	assert_int(net.get_local_peer_id()).is_equal(1)
	net.disconnect_from_session()


func test_join_without_server_fails_gracefully() -> void:
	var net: NetworkManager = NetworkManagerScript.new()
	add_child(net)
	# Connecting to a port with no listener should not crash; the peer is set
	# but connection_failed will fire asynchronously. We assert the call returns
	# successfully (peer creation OK) without raising.
	var ok := net.join_server("127.0.0.1", 34243)
	assert_bool(ok).is_true()
	net.disconnect_from_session()
