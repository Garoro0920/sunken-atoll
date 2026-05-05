extends Node

## Registers the project's InputMap actions at runtime.
##
## We bootstrap actions in code (instead of in project.godot's [input]
## section) because hand-editing the [input] block is brittle: Godot
## 4.6 silently drops actions whose object encoding it can't parse,
## which manifests as "input does nothing at all" with no error in the
## log. This autoload runs before any scene's _ready, so by the time
## PlayerInputController polls Input.get_action_strength(...), the
## actions are guaranteed to exist.
##
## Hosted as autoload "InputMapBootstrap" (see project.godot [autoload]).
## Idempotent: re-registration is skipped per-action.

const ACTIONS: Dictionary = {
	&"move_forward": KEY_W,
	&"move_back": KEY_S,
	&"move_left": KEY_A,
	&"move_right": KEY_D,
	&"jump": KEY_SPACE,
	&"dive_up": KEY_SPACE,  # same key as jump (context decides)
	&"dive_down": KEY_SHIFT,
	&"interact": KEY_E,
	&"build_toggle": KEY_B,
	&"build_place": KEY_F,
	&"build_next": KEY_Q,
	&"build_prev": KEY_Z,
}


func _ready() -> void:
	for action_name in ACTIONS.keys():
		var name_sn: StringName = action_name as StringName
		if not InputMap.has_action(name_sn):
			InputMap.add_action(name_sn)
		var event := InputEventKey.new()
		event.physical_keycode = ACTIONS[action_name]
		# Avoid duplicate events on hot-reload.
		var already_bound: bool = false
		for existing in InputMap.action_get_events(name_sn):
			if (
				existing is InputEventKey
				and (existing as InputEventKey).physical_keycode == event.physical_keycode
			):
				already_bound = true
				break
		if not already_bound:
			InputMap.action_add_event(name_sn, event)
