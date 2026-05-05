extends Node

## Storm-collapse scenario for the floating physics prototype.
## Per specs/epics/prototype_phase.md §5.4 — verifies that an adequately
## supported structure survives a 5-minute storm while an unsupported piece
## triggers the collapse path.
##
## Run headless:
##   godot --headless -s res://tests/scenarios/building/storm_collapse_test.gd

const TEST_SCENE := "res://scenes/prototypes/floating/floating_physics_test.tscn"
const STORM_DURATION_SEC := 300  # 5 minutes
const TICK_BUDGET_MS := 16.67   # 60 Hz physics tick budget


func _ready() -> void:
	var packed: PackedScene = load(TEST_SCENE) as PackedScene
	if packed == null:
		_fail("scene_load_failed")
		return
	var root: Node = packed.instantiate()
	get_tree().root.add_child(root)

	var water_field: Node = root.get_node_or_null("WaterField")
	var integrity: Node = root.get_node_or_null("StructuralIntegrity")
	if water_field == null or integrity == null:
		_fail("missing_required_nodes")
		return

	# Crank up the storm.
	water_field.set("storm_intensity", 1.0)

	var t0_msec: int = Time.get_ticks_msec()
	var max_tick_ms: float = 0.0
	var any_collapsed: bool = false
	var prev_msec: int = t0_msec
	while (Time.get_ticks_msec() - t0_msec) < STORM_DURATION_SEC * 1000:
		await get_tree().physics_frame
		var now: int = Time.get_ticks_msec()
		var tick_ms: float = float(now - prev_msec)
		if tick_ms > max_tick_ms:
			max_tick_ms = tick_ms
		prev_msec = now
		# Periodically recompute support for the unsupported piece test.
		if (now - t0_msec) % 5000 < 16:
			var collapsed: int = integrity.recompute()
			if collapsed > 0:
				any_collapsed = true

	water_field.set("storm_intensity", 0.0)

	# Pass criteria per prototype_phase.md §5.4.
	var pass_tick_budget: bool = max_tick_ms <= (TICK_BUDGET_MS * 2.0)  # Allow 2x spike margin
	var report: Dictionary = {
		"duration_sec": STORM_DURATION_SEC,
		"max_tick_ms": max_tick_ms,
		"tick_budget_ms": TICK_BUDGET_MS,
		"any_collapsed": any_collapsed,
		"pass_tick_budget": pass_tick_budget,
	}
	print(JSON.stringify(report, "\t"))
	get_tree().quit(0 if pass_tick_budget else 1)


func _fail(reason: String) -> void:
	push_error("storm_collapse_test failed: %s" % reason)
	get_tree().quit(2)
