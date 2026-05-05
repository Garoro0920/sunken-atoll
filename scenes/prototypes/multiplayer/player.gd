class_name ProtoPlayer
extends CharacterBody3D

## Networked player capsule for the multiplayer prototype.
## - Owning client drives movement input.
## - State (position, rotation) synced via MultiplayerSynchronizer in the scene.
## - Server is authoritative for world interactions (not implemented in proto).
##
## Per specs/features/multiplayer_session.md §3.3.

const MOVE_SPEED: float = 5.0
const JUMP_VELOCITY: float = 5.5
const GRAVITY: float = 9.8

@export var peer_id: int = 1


func _ready() -> void:
	# Only the owning peer reads input. Set the multiplayer authority to the
	# peer that controls this body (set when spawned).
	set_multiplayer_authority(peer_id)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	move_and_slide()
