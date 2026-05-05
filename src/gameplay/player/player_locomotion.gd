class_name PlayerLocomotion
extends RefCounted

## Pure-function locomotion helpers.
##
## Per specs/features/survival_balance.md §3 (oxygen/dive),
##     specs/game_design_document.md §4.1 / §4.5 (movement/dive).
##
## The PlayerCharacter delegates state-transition and velocity decisions
## to these static functions so they remain trivially unit-testable
## without a scene tree, physics tick, or input device.

enum LocomotionState { GROUND, AIR, SWIM_SURFACE, DIVING }

const WATER_SURFACE_BAND_M: float = 0.1  # how far above water still counts as above
const SWIM_DEPTH_BAND_M: float = 0.5  # how far below water before switching to DIVING

const WALK_SPEED_MPS: float = 5.0
const RUN_SPEED_MPS: float = 8.0
const JUMP_VELOCITY_MPS: float = 5.5
const SWIM_SPEED_MPS: float = 3.0
const DIVE_SPEED_MPS: float = 2.5
const DIVE_VERTICAL_SPEED_MPS: float = 2.0
const GRAVITY_MPS2: float = 9.8
const SWIM_BUOYANCY_DAMPING: float = 0.6


## Decide the locomotion state from world position vs water surface.
## A null water_y means there is no water at this xz (treated as above).
static func compute_state(global_y: float, water_y: Variant, is_on_floor: bool) -> int:
	if water_y == null:
		return LocomotionState.GROUND if is_on_floor else LocomotionState.AIR
	var w: float = float(water_y)
	if global_y > w + WATER_SURFACE_BAND_M:
		return LocomotionState.GROUND if is_on_floor else LocomotionState.AIR
	if global_y > w - SWIM_DEPTH_BAND_M:
		return LocomotionState.SWIM_SURFACE
	return LocomotionState.DIVING


## Compute the next velocity from input + state.
##   move_input.x = strafe (-1..1), move_input.y = forward (-1..1)
##   request_jump = true on rising edge of jump
##   request_dive_down = true while the dive-down key is held
##   request_dive_up = true while the surface-up key is held
static func compute_velocity(
	state: int,
	current_velocity: Vector3,
	transform_basis: Basis,
	move_input: Vector2,
	request_jump: bool,
	request_dive_down: bool,
	request_dive_up: bool,
	delta: float,
	speed_scale: float = 1.0
) -> Vector3:
	var direction: Vector3 = transform_basis * Vector3(move_input.x, 0.0, move_input.y)
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
	var v: Vector3 = current_velocity
	match state:
		LocomotionState.GROUND:
			var speed: float = WALK_SPEED_MPS * speed_scale
			v.x = direction.x * speed
			v.z = direction.z * speed
			v.y = 0.0
			if request_jump:
				v.y = JUMP_VELOCITY_MPS
		LocomotionState.AIR:
			# Maintain horizontal momentum, apply gravity.
			v.x = move_toward(
				v.x, direction.x * WALK_SPEED_MPS * speed_scale, WALK_SPEED_MPS * delta
			)
			v.z = move_toward(
				v.z, direction.z * WALK_SPEED_MPS * speed_scale, WALK_SPEED_MPS * delta
			)
			v.y -= GRAVITY_MPS2 * delta
		LocomotionState.SWIM_SURFACE:
			var swim_speed: float = SWIM_SPEED_MPS * speed_scale
			v.x = direction.x * swim_speed
			v.z = direction.z * swim_speed
			# Light damping toward the surface.
			v.y = -v.y * SWIM_BUOYANCY_DAMPING
			if request_dive_down:
				v.y = -DIVE_VERTICAL_SPEED_MPS
		LocomotionState.DIVING:
			var dive_speed: float = DIVE_SPEED_MPS * speed_scale
			v.x = direction.x * dive_speed
			v.z = direction.z * dive_speed
			v.y = 0.0
			if request_dive_up:
				v.y = DIVE_VERTICAL_SPEED_MPS
			elif request_dive_down:
				v.y = -DIVE_VERTICAL_SPEED_MPS
	return v


## True when the locomotion state implies the player should consume oxygen
## via SurvivalManager.set_diving(true).
static func is_diving(state: int) -> bool:
	return state == LocomotionState.DIVING
