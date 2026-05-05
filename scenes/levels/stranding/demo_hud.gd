class_name DemoHud
extends Control

## Minimal heads-up display for the Sprint 1 stranding demo.
##
## Surfaces the otherwise-invisible state changes that the demo
## generates (build mode toggle, selected part cycling, focused
## interactable) so PO and Claude Code can verify input + system
## interaction without instrumenting the engine.
##
## Was originally `extends CanvasLayer` but on Godot 4.6.2 +
## Compatibility renderer that combination caused the entire 3D
## viewport to render only the WorldEnvironment background_color
## (sky-blue, no geometry). Switching to a Control with full-rect
## anchors + MOUSE_FILTER_IGNORE preserves the same visual layout
## without disturbing the 3D viewport. The bisect chain
## (stranding_minimal -> _with_player -> _no_hud) confirmed the
## CanvasLayer-rooted HUD as the single cause.

@onready var build_mode_label: Label = $MarginContainer/VBox/BuildModeLabel
@onready var selected_part_label: Label = $MarginContainer/VBox/SelectedPartLabel
@onready var interact_label: Label = $MarginContainer/VBox/InteractLabel
@onready var inventory_label: Label = $MarginContainer/VBox/InventoryLabel


func _ready() -> void:
	update_build_mode(false)
	update_selected_part(&"")
	update_interact_target(null)
	update_inventory(null)


func update_build_mode(active: bool) -> void:
	if build_mode_label == null:
		return
	build_mode_label.text = "Build mode: %s" % ("ON [B]" if active else "OFF [B]")


func update_selected_part(part_id: StringName) -> void:
	if selected_part_label == null:
		return
	if part_id == &"":
		selected_part_label.text = "Selected: (none)"
		return
	var def: BuildingPartDefinition = T1PartCatalog.find(part_id)
	var label: String = "(unknown)" if def == null else def.display_name
	selected_part_label.text = "Selected: %s   [Q/Z cycle, F place]" % label


func update_interact_target(target: Node) -> void:
	if interact_label == null:
		return
	if target == null:
		interact_label.text = "Look at: (nothing)   [E interact]"
		return
	var label: String = ""
	if target is Interactable:
		label = (target as Interactable).display_label
	if label.is_empty():
		label = target.name
	interact_label.text = "Look at: %s   [E interact]" % label


func update_inventory(inv: Inventory) -> void:
	if inventory_label == null:
		return
	if inv == null:
		inventory_label.text = "Inventory: (none)"
		return
	var snapshot: Dictionary = inv.snapshot()
	var parts: Array[String] = []
	for key in snapshot.keys():
		var item_id: StringName = key as StringName
		parts.append("%s x%d" % [String(item_id), int(snapshot[key])])
	if parts.is_empty():
		inventory_label.text = "Inventory: (empty)"
	else:
		inventory_label.text = "Inventory: %s" % ", ".join(parts)
