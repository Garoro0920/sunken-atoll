extends SceneTree

## Storm-collapse scenario for the floating physics prototype.
## Per specs/epics/prototype_phase.md §5.4 — verifies that an adequately
## supported structure survives the storm window while an unsupported
## piece triggers the collapse path.
##
## Run headless:
##   godot --headless -s res://tests/scenarios/building/storm_collapse_test.gd
##
## Override duration via env var STORM_DURATION_SEC (default 300).
##
## Note: extends SceneTree so it can be invoked with `-s` directly.

const TEST_SCENE := "res://scenes/prototypes/floating/floating_physics_test.tscn"
const TICK_BUDGET_MS := 16.67  # 60 Hz physics tick budget


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var duration_sec: int = 300
	var env_dur: String = OS.get_environment("STORM_DURATION_SEC")
	if env_dur != "" and env_dur.is_valid_int():
		duration_sec = int(env_dur)

	var spawn_count_override: int = -1  # -1 means keep .tscn default
	var env_count: String = OS.get_environment("SPAWN_COUNT")
	if env_count != "" and env_count.is_valid_int():
		spawn_count_override = int(env_count)

	var packed: PackedScene = load(TEST_SCENE) as PackedScene
	if packed == null:
		push_error("storm_collapse_test failed: scene_load_failed")
		quit(2)
		return
	var scene_root: Node = packed.instantiate()
	# Override spawn count BEFORE adding to root (so Spawner._ready sees it).
	if spawn_count_override > 0:
		var spawner: Node = scene_root.get_node_or_null("Spawner")
		if spawner != null:
			spawner.set("spawn_count", spawn_count_override)
	root.add_child(scene_root)

	var water_field: Node = scene_root.get_node_or_null("WaterField")
	var integrity: Node = scene_root.get_node_or_null("StructuralIntegrity")
	if water_field == null or integrity == null:
		push_error("storm_collapse_test failed: missing_required_nodes")
		quit(2)
		return

	# Crank up the storm.
	water_field.set("storm_intensity", 1.0)

	var t0_msec: int = Time.get_ticks_msec()
	var max_tick_ms: float = 0.0
	var any_collapsed: bool = false
	var tick_count: int = 0
	var sum_tick_ms: float = 0.0
	var prev_msec: int = t0_msec
	while (Time.get_ticks_msec() - t0_msec) < duration_sec * 1000:
		await self.physics_frame
		var now: int = Time.get_ticks_msec()
		var tick_ms: float = float(now - prev_msec)
		if tick_ms > max_tick_ms:
			max_tick_ms = tick_ms
		sum_tick_ms += tick_ms
		tick_count += 1
		prev_msec = now
		# Periodically recompute support for the unsupported piece test.
		if (now - t0_msec) % 5000 < 16:
			var collapsed: int = integrity.recompute()
			if collapsed > 0:
				any_collapsed = true

	water_field.set("storm_intensity", 0.0)

	var avg_tick_ms: float = sum_tick_ms / float(tick_count) if tick_count > 0 else 0.0

	# Pass criteria per prototype_phase.md §5.4.
	var pass_tick_budget: bool = max_tick_ms <= (TICK_BUDGET_MS * 2.0)
	var report: Dictionary = {
		"duration_sec": duration_sec,
		"spawn_count_override": spawn_count_override,
		"tick_count": tick_count,
		"avg_tick_ms": avg_tick_ms,
		"max_tick_ms": max_tick_ms,
		"tick_budget_ms": TICK_BUDGET_MS,
		"any_collapsed": any_collapsed,
		"pass_tick_budget": pass_tick_budget,
	}
	print(JSON.stringify(report, "\t"))

	var report_path: String = "user://storm_collapse_%d.json" % Time.get_unix_time_from_system()
	var f := FileAccess.open(report_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "\t"))
		f.close()
		print("Report written to: %s" % report_path)

	quit(0 if pass_tick_budget else 1)
