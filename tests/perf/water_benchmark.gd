extends SceneTree

## Water shader benchmark.
## Per specs/epics/prototype_phase.md §4.4 — measures GPU/CPU cost of the
## prototype water surface across the four environment-band presets.
##
## Run headless:
##   godot --headless -s res://tests/perf/water_benchmark.gd
##
## Output: JSON written to user://water_benchmark_<timestamp>.json so CI
## can ingest it (build/test_reports/perf/water.json).
##
## Note: extends SceneTree so it can be invoked with `-s` directly. This
## avoids the "doesn't inherit from SceneTree or MainLoop" error that
## occurred when extending Node.

const TEST_SCENE := "res://scenes/prototypes/water/water_test.tscn"
const PRESETS := ["shallow", "urban", "ruins", "deep"]
const WARMUP_FRAMES := 60
const MEASURE_FRAMES := 600  # ~10 seconds at 60 FPS, less if uncapped

var _scene_root: Node = null
var _controller: Node = null
var _results: Array = []


func _init() -> void:
	# _init runs at startup. Defer the actual run so the SceneTree finishes
	# wiring before we touch root / process_frame.
	_run.call_deferred()


func _run() -> void:
	var packed: PackedScene = load(TEST_SCENE) as PackedScene
	if packed == null:
		push_error("Failed to load water test scene: %s" % TEST_SCENE)
		quit(1)
		return
	_scene_root = packed.instantiate()
	root.add_child(_scene_root)
	_controller = _scene_root

	for preset in PRESETS:
		await _measure_preset(preset)
	_write_report()
	quit(0)


func _measure_preset(preset_name: String) -> void:
	if _controller.has_method("apply_preset"):
		_controller.apply_preset(preset_name)

	# Warmup: shaders compile, GPU caches prime.
	for i in WARMUP_FRAMES:
		await self.process_frame

	var frame_times_ms: PackedFloat32Array = PackedFloat32Array()
	var prev_usec := Time.get_ticks_usec()
	for i in MEASURE_FRAMES:
		await self.process_frame
		var now_usec := Time.get_ticks_usec()
		frame_times_ms.push_back(float(now_usec - prev_usec) / 1000.0)
		prev_usec = now_usec

	var sorted := Array(frame_times_ms)
	sorted.sort()
	var avg_ms := 0.0
	for f in frame_times_ms:
		avg_ms += f
	avg_ms /= float(frame_times_ms.size())

	var p99_index: int = int(float(sorted.size()) * 0.99)
	var p99_ms := float(sorted[p99_index])

	var avg_fps: float = 1000.0 / maxf(avg_ms, 0.001)
	var one_pct_low_fps: float = 1000.0 / maxf(p99_ms, 0.001)

	var entry := {
		"preset": preset_name,
		"frames_measured": MEASURE_FRAMES,
		"avg_frame_ms": avg_ms,
		"p99_frame_ms": p99_ms,
		"avg_fps": avg_fps,
		"one_percent_low_fps": one_pct_low_fps,
	}
	_results.append(entry)
	print(
		(
			"  %s: avg %.2f ms (%.1f fps), 1%% low %.2f ms (%.1f fps)"
			% [preset_name, avg_ms, avg_fps, p99_ms, one_pct_low_fps]
		)
	)


func _write_report() -> void:
	var path := "user://water_benchmark_%d.json" % Time.get_unix_time_from_system()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write benchmark report: %s" % path)
		return
	var doc := {
		"version": 1,
		"scene": TEST_SCENE,
		"renderer":
		(
			"opengl3"
			if "opengl" in str(RenderingServer.get_video_adapter_name()).to_lower()
			else "default"
		),
		"adapter": RenderingServer.get_video_adapter_name(),
		"results": _results,
	}
	var json_text := JSON.stringify(doc, "\t")
	f.store_string(json_text)
	f.close()
	print("Benchmark written to: %s" % path)
