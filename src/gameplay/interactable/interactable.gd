class_name Interactable
extends Node

## Base for "use" verbs the player can trigger via PlayerCharacter.interact().
##
## Per specs/features/building_system.md §3.5 (T1 機能設備) and
## specs/features/survival_balance.md §3 (eat/drink/warm).
##
## Subclasses override _do_use(actor) and return true on success.
## The base wraps that call with the enabled gate and signal emission so
## listeners (HUD chimes, audio, multiplayer broadcasts) get one event
## per attempted use rather than each subclass remembering to emit.

signal used(by: Node, success: bool)

@export var display_label: String = ""
@export var enabled: bool = true


## Public entry point. Returns true on success.
func use(actor: Node) -> bool:
	if not enabled:
		used.emit(actor, false)
		return false
	var ok: bool = _do_use(actor)
	used.emit(actor, ok)
	return ok


## Override in subclasses. Default is a no-op success so trivial test
## doubles work without subclassing.
func _do_use(_actor: Node) -> bool:
	return true
