class_name WaterTestController
extends Node3D

## Controller for the water shader prototype scene.
## Per specs/features/water_shader.md §3.3 — exposes preset switching for the
## four environment bands (shallow / urban / ruins / deep) and storm intensity
## driven by a debug HUD.

const PRESET_PATHS := {
	"shallow": "res://resources/materials/water/preset_shallow.tres",
	"urban": "res://resources/materials/water/preset_urban.tres",
	"ruins": "res://resources/materials/water/preset_ruins.tres",
	"deep": "res://resources/materials/water/preset_deep.tres",
}

@export var water_mesh_path: NodePath
@export var initial_preset: String = "shallow"

# prvvars before onreadyprvvars per .gdlintrc class-definitions-order.
var _current_preset: String = ""
var _storm_intensity: float = 0.0

@onready var _water_mesh: MeshInstance3D = get_node(water_mesh_path)


func _ready() -> void:
	apply_preset(initial_preset)


func apply_preset(name: String) -> void:
	if not PRESET_PATHS.has(name):
		push_warning("Unknown water preset: %s" % name)
		return
	var mat := load(PRESET_PATHS[name]) as ShaderMaterial
	if mat == null:
		push_warning("Failed to load preset material: %s" % PRESET_PATHS[name])
		return
	_water_mesh.material_override = mat
	_current_preset = name


func set_storm_intensity(value: float) -> void:
	_storm_intensity = clampf(value, 0.0, 1.0)
	var mat := _water_mesh.material_override as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("storm_intensity", _storm_intensity)


func _unhandled_input(event: InputEvent) -> void:
	# Debug shortcuts: keys 1..4 cycle presets, [/] adjust storm intensity.
	if not (event is InputEventKey and event.pressed):
		return
	var key := event as InputEventKey
	match key.keycode:
		KEY_1:
			apply_preset("shallow")
		KEY_2:
			apply_preset("urban")
		KEY_3:
			apply_preset("ruins")
		KEY_4:
			apply_preset("deep")
		KEY_BRACKETLEFT:
			set_storm_intensity(_storm_intensity - 0.1)
		KEY_BRACKETRIGHT:
			set_storm_intensity(_storm_intensity + 0.1)
