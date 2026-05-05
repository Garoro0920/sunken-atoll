class_name StorageInteractable
extends Interactable

## Lockerless shared chest.
##
## Per specs/features/building_system.md §3.5 (T1 倉庫).
## Holds an Inventory; opening it from the player's perspective is a
## UI concern, but the data side is just "ensure the actor can read /
## write our stored Inventory". The signal `opened` is what a future
## inventory-transfer UI will subscribe to.

signal opened(actor: Node, stored: Inventory)

@export var stored: Inventory


func _do_use(actor: Node) -> bool:
	if stored == null:
		return false
	opened.emit(actor, stored)
	return true
