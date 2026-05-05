extends Node

## Water shader benchmark.
## Per specs/epics/prototype_phase.md §4.4 — measures GPU/CPU cost of the
## prototype water surface across the four environment-band presets.
##
## Run headless:
##   godot --headless -s res://tests/perf/water_benchmark.gd
##
## Output: JSON written to user://water_benchmark_<timestamp>.json so CI
## can ingest it (build/test_reports/perf/water.json).

const TEST_SCENE := "res://scenes/prototypes/water/water_test.tscn"
const PRESETS := ["shallow", "urban", "ruins", "deep"]
const WARMUP_FRAMES := 60
const MEASURE_FRAMES := 600  # ~10 seconds at 60 FPS

var _scene_root: Node = null
var _controller: Node = null
var _results: Array = []


func _ready() -> void:
	var packed: PackedScene = load(TEST_SCENE) as PackedScene
	if packed == null:
		push_error("Failed to load water test scene: %s" % TEST_SCENE)
		quit_with_code(1)
		return
	_scene_root = packed.instantiate()
	get_tree().root.add_child(_scene_root)
	_controller = _scene_root

	for preset in PRESETS:
		await _measure_preset(preset)
	_write_report()
	quit_with_code(0)


func _measure_preset(name: String) -> void:
	if _controller.has_method("apply_preset"):
		_controller.apply_preset(name)

	# Warmup: shaders compile, GPU caches prime.
	for i in WARMUP_FRAMES:
		await get_tree().process_frame

	var frame_times_ms: PackedFloat32Array = PackedFloat32Array()
	var t0_msec := Time.get_ticks_usec()
	var prev_msec := t0_msec
	for i in MEASURE_FRAMES:
		await get_tree().process_frame
		var now_msec := Time.get_ticks_usec()
		frame_times_ms.push_back(float(now_msec - prev_msec) / 1000.0)
		prev_msec = now_msec

	var sorted := Array(frame_times_ms)
	sorted.sort()
	var avg_ms := 0.0
	for f in frame_times_ms:
		avg_ms += f
	avg_ms /= float(frame_times_ms.size())

	var p99_index: int = int(float(sorted.size()) * 0.99)
	var p99_ms := float(sorted[p99_index])

	var avg_fps := 1000.0 / max(avg_ms, 0.001)
	var one_pct_low_fps := 1000.0 / max(p99_ms, 0.001)

	var entry := {
		"preset": name,
		"frames_measured": MEASURE_FRAMES,
		"avg_frame_ms": avg_ms,
		"p99_frame_ms": p99_ms,
		"avg_fps": avg_fps,
		"one_percent_low_fps": one_pct_low_fps,
	}
	_results.append(entry)


func _write_report() -> void:
	var path := "user://water_benchmark_%d.json" % Time.get_unix_time_from_system()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write benchmark report: %s" % path)
		return
	var doc := {
		"version": 1,
		"scene": TEST_SCENE,
		"results": _results,
	}
	var json_text := JSON.stringify(doc, "\t")
	f.store_string(json_text)
	f.close()
	print("Benchmark written to: %s" % path)


func quit_with_code(code: int) -> void:
	get_tree().quit(code)
