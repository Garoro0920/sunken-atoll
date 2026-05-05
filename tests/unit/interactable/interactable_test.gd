extends GdUnitTestSuite

## Tests for the Interactable base class.


func test_use_emits_signal_with_success_true() -> void:
	var node := Interactable.new()
	add_child(node)
	var captured: Array = []
	node.used.connect(func(actor: Node, ok: bool) -> void: captured.append([actor, ok]))
	var ok: bool = node.use(self)
	assert_bool(ok).is_true()
	assert_int(captured.size()).is_equal(1)
	assert_object(captured[0][0]).is_equal(self)
	assert_bool(captured[0][1]).is_true()


func test_disabled_interactable_emits_failure_signal_and_skips_logic() -> void:
	# Subclass that would otherwise count calls — but disabled gate
	# must short-circuit before _do_use runs.
	var counter: Array = [0]
	var subclass := _CountingInteractable.new(counter)
	add_child(subclass)
	subclass.enabled = false
	var ok: bool = subclass.use(self)
	assert_bool(ok).is_false()
	assert_int(counter[0]).is_equal(0)


func test_subclass_failure_propagates_through_used_signal() -> void:
	var subclass := _AlwaysFailInteractable.new()
	add_child(subclass)
	var captured: Array = []
	subclass.used.connect(func(_a: Node, ok: bool) -> void: captured.append(ok))
	var ok: bool = subclass.use(self)
	assert_bool(ok).is_false()
	assert_array(captured).contains([false])


# --- Local test doubles ---


class _CountingInteractable:
	extends Interactable
	var _counter: Array

	func _init(counter: Array) -> void:
		_counter = counter

	func _do_use(_actor: Node) -> bool:
		_counter[0] += 1
		return true


class _AlwaysFailInteractable:
	extends Interactable

	func _do_use(_actor: Node) -> bool:
		return false
