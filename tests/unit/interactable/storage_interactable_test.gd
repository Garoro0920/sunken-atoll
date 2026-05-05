extends GdUnitTestSuite

## Tests for StorageInteractable.


func _make_storage(stored: Inventory) -> StorageInteractable:
	var s := StorageInteractable.new()
	s.stored = stored
	add_child(s)
	return s


func _make_inventory() -> Inventory:
	var inv := Inventory.new()
	add_child(inv)
	return inv


func test_use_without_stored_inventory_fails() -> void:
	var s := _make_storage(null)
	assert_bool(s.use(self)).is_false()


func test_use_emits_opened_with_stored_reference() -> void:
	var stored := _make_inventory()
	stored.add(T1ItemCatalog.ID_WOOD, 5)
	var s := _make_storage(stored)
	var captured: Array = []
	s.opened.connect(func(actor: Node, inv: Inventory) -> void: captured.append([actor, inv]))
	var ok: bool = s.use(self)
	assert_bool(ok).is_true()
	assert_int(captured.size()).is_equal(1)
	assert_object(captured[0][0]).is_equal(self)
	assert_object(captured[0][1]).is_equal(stored)
