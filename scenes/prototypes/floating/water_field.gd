class_name AnalyticalWaterField
extends Node

## CPU-side analytical mirror of the water shader's Gerstner waves.
## Provides get_water_height(world_pos) for FloatingNode buoyancy sampling
## so physics and visual surfaces stay in sync.
##
## Per specs/epics/prototype_phase.md §5.2 (note: visual + physics share the
## same wave parameters to avoid divergence).

const GRAVITY_C: float = 9.8

@export var wave_dir_a: Vector2 = Vector2(1.0, 0.0)
@export var wave_dir_b: Vector2 = Vector2(0.7, 0.7)
@export var wave_dir_c: Vector2 = Vector2(-0.3, 0.95)
@export var wave_amplitude_a: float = 0.30
@export var wave_amplitude_b: float = 0.18
@export var wave_amplitude_c: float = 0.10
@export var wave_length_a: float = 8.0
@export var wave_length_b: float = 5.0
@export var wave_length_c: float = 3.0
@export var wave_steepness: float = 0.5
@export var tide_offset: float = 0.0
@export var storm_intensity: float = 0.0


func get_water_height(world_pos: Vector3) -> float:
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var y: float = tide_offset
	y += _gerstner_y(world_pos, wave_dir_a, wave_amplitude_a, wave_length_a, t)
	y += _gerstner_y(world_pos, wave_dir_b, wave_amplitude_b, wave_length_b, t)
	y += _gerstner_y(world_pos, wave_dir_c, wave_amplitude_c, wave_length_c, t)
	return y


func _gerstner_y(
	pos: Vector3, dir_unnorm: Vector2, amplitude: float, wave_length: float, t: float
) -> float:
	var dir: Vector2 = dir_unnorm.normalized()
	var k: float = TAU / max(wave_length, 0.001)
	var c: float = sqrt(GRAVITY_C / k)
	var f: float = k * (dir.dot(Vector2(pos.x, pos.z)) - c * t)
	var a: float = amplitude * (1.0 + storm_intensity * 1.5)
	return a * sin(f)
