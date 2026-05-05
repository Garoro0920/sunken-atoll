extends GdUnitTestSuite

## Tests for PlayerInputController.
## All tests drive the controller via apply_snapshot so they don't
## depend on the Input singleton or InputMap registration.


func _make_player() -> PlayerCharacter:
	var p: PlayerCharacter = PlayerCharacter.new()
	add_child(p)
	return p


func _make_controller(player: PlayerCharacter) -> PlayerInputController:
	var ctrl: PlayerInputController = PlayerInputController.new()
	ctrl.player = player
	add_child(ctrl)
	return ctrl


func test_default_palette_is_t1_catalog() -> void:
	var ctrl := _make_controller(_make_player())
	assert_int(ctrl.available_parts.size()).is_equal(T1PartCatalog.ALL_IDS.size())
	assert_str(ctrl.get_selected_part_id()).is_equal(T1PartCatalog.ID_FOUNDATION)


func test_apply_snapshot_routes_movement_to_player() -> void:
	var player := _make_player()
	var ctrl := _make_controller(player)
	ctrl.apply_snapshot({&"strafe": 1.0, &"forward": -0.5})
	assert_float(player.move_input.x).is_equal_approx(1.0, 1e-5)
	assert_float(player.move_input.y).is_equal_approx(-0.5, 1e-5)


func test_apply_snapshot_jump_sets_request_jump() -> void:
	var player := _make_player()
	var ctrl := _make_controller(player)
	ctrl.apply_snapshot({&"jump_pressed": true})
	assert_bool(player.request_jump).is_true()


func test_apply_snapshot_dive_keys_passed_through() -> void:
	var player := _make_player()
	var ctrl := _make_controller(player)
	ctrl.apply_snapshot({&"dive_down": true, &"dive_up": false})
	assert_bool(player.request_dive_down).is_true()
	assert_bool(player.request_dive_up).is_false()


func test_build_toggle_flips_build_mode_and_emits() -> void:
	var ctrl := _make_controller(_make_player())
	var captured: Array = []
	ctrl.build_mode_changed.connect(func(active: bool) -> void: captured.append(active))
	ctrl.apply_snapshot({&"build_toggle_pressed": true})
	assert_bool(ctrl.build_mode_active).is_true()
	ctrl.apply_snapshot({&"build_toggle_pressed": true})
	assert_bool(ctrl.build_mode_active).is_false()
	assert_array(captured).is_equal([true, false])


func test_build_next_cycles_part_index_with_wrap() -> void:
	var ctrl := _make_controller(_make_player())
	var n: int = ctrl.available_parts.size()
	for i in n:
		ctrl.apply_snapshot({&"build_next_pressed": true})
	# After n cycles we should be back at the start.
	assert_int(ctrl.selected_part_index).is_equal(0)


func test_build_prev_cycles_backward_with_wrap() -> void:
	var ctrl := _make_controller(_make_player())
	var n: int = ctrl.available_parts.size()
	ctrl.apply_snapshot({&"build_prev_pressed": true})
	assert_int(ctrl.selected_part_index).is_equal(n - 1)


func test_build_place_outside_build_mode_is_noop() -> void:
	var player := _make_player()
	var ctrl := _make_controller(player)
	# Wire a placement so we can detect (lack of) calls.
	var placement := BuildingPlacement.new()
	add_child(placement)
	placement.parts_root = Node3D.new()
	add_child(placement.parts_root)
	ctrl.building_placement = placement
	ctrl.apply_snapshot({&"build_place_pressed": true})
	assert_int(placement.parts_root.get_child_count()).is_equal(0)


func test_build_place_in_build_mode_calls_placement() -> void:
	var player := _make_player()
	var ctrl := _make_controller(player)
	var placement := BuildingPlacement.new()
	placement.support_proximity_m = 50.0  # generous for unit-test geometry
	add_child(placement)
	placement.parts_root = Node3D.new()
	add_child(placement.parts_root)
	ctrl.building_placement = placement
	# Enter build mode; default selection is the foundation (self-supporting).
	ctrl.apply_snapshot({&"build_toggle_pressed": true})
	ctrl.apply_snapshot({&"build_place_pressed": true})
	# Exactly one part placed (the foundation).
	assert_int(placement.parts_root.get_child_count()).is_equal(1)


func test_interact_with_no_focus_emits_failure_reason() -> void:
	var player := _make_player()
	var ctrl := _make_controller(player)
	var captured: Array = []
	ctrl.interact_failed.connect(func(reason: String) -> void: captured.append(reason))
	ctrl.apply_snapshot({&"interact_pressed": true})
	assert_array(captured).is_equal(["no_focus"])


func test_interact_routes_to_focused_interactable() -> void:
	var player := _make_player()
	var ctrl := _make_controller(player)
	# Inject a focused interactable directly (bypassing the raycast that
	# requires a real World3D physics space).
	var captured_use: Array = []
	var fake := _RecordingInteractable.new(captured_use)
	add_child(fake)
	player._focused_interactable = fake
	ctrl.apply_snapshot({&"interact_pressed": true})
	assert_int(captured_use.size()).is_equal(1)


func test_part_palette_can_be_overridden() -> void:
	var player := _make_player()
	var ctrl: PlayerInputController = PlayerInputController.new()
	ctrl.player = player
	# Set the palette before adding to tree so _ready uses our list.
	ctrl.available_parts = [T1PartCatalog.ID_FLOOR, T1PartCatalog.ID_WALL]
	add_child(ctrl)
	assert_int(ctrl.available_parts.size()).is_equal(2)
	assert_str(ctrl.get_selected_part_id()).is_equal(T1PartCatalog.ID_FLOOR)
	ctrl.apply_snapshot({&"build_next_pressed": true})
	assert_str(ctrl.get_selected_part_id()).is_equal(T1PartCatalog.ID_WALL)


# --- Test doubles ---


class _RecordingInteractable:
	extends Interactable
	var _records: Array

	func _init(records: Array) -> void:
		_records = records

	func _do_use(_actor: Node) -> bool:
		_records.append(true)
		return true
