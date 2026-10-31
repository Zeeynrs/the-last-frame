extends RefCounted

## Automated tests for IdRegistry per ADR-005 and TLF-007.

var assert_helper: RefCounted


func _assert_eq(actual, expected, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_eq(actual, expected, msg)
	assert(actual == expected, msg)
	return actual == expected


func _assert_true(cond: bool, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_true(cond, msg)
	assert(cond, msg)
	return cond


func _assert_false(cond: bool, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_false(cond, msg)
	assert(not cond, msg)
	return not cond


func test_valid_id_registration() -> void:
	var registry = IdRegistry.new()
	var node_a = Node.new()
	var node_b = Node.new()

	var ok_a = registry.register(&"ch01.platform.gate_01", node_a)
	var ok_b = registry.register(&"global.pocket_watch", node_b)

	_assert_true(ok_a, "Registration of 'ch01.platform.gate_01' should succeed")
	_assert_true(ok_b, "Registration of 'global.pocket_watch' should succeed")
	_assert_eq(registry.resolve(&"ch01.platform.gate_01"), node_a, "Resolving node_a should return node_a")
	_assert_eq(registry.resolve(&"global.pocket_watch"), node_b, "Resolving node_b should return node_b")

	node_a.free()
	node_b.free()
	registry.free()


func test_empty_id_rejected() -> void:
	var registry = IdRegistry.new()
	var node = Node.new()

	var ok = registry.register(&"", node)
	_assert_false(ok, "Empty ID must be rejected")
	_assert_eq(registry.resolve(&""), null, "Empty ID should not resolve")

	node.free()
	registry.free()


func test_malformed_ids_rejected() -> void:
	var registry = IdRegistry.new()
	var node = Node.new()

	var malformed_ids: Array[StringName] = [
		&"ch1.gate",           # missing second digit in chapter
		&"platform.gate",      # missing chapter/global prefix
		&"ch01.",              # trailing dot
		&"ch01..gate",         # double dot
		&"CH01.gate",          # uppercase chapter
		&"global.Gate",        # uppercase name
		&"global.pocket-watch",# dash not allowed (only underscore)
		&"global"              # no dotted path
	]

	for bad_id in malformed_ids:
		var ok = registry.register(bad_id, node)
		_assert_false(ok, "Malformed ID '%s' should be rejected" % bad_id)

	node.free()
	registry.free()


func test_duplicate_id_rejected() -> void:
	var registry = IdRegistry.new()
	var node1 = Node.new()
	var node2 = Node.new()

	var first_ok = registry.register(&"ch01.test_node", node1)
	_assert_true(first_ok, "First registration of 'ch01.test_node' should succeed")

	var second_ok = registry.register(&"ch01.test_node", node2)
	_assert_false(second_ok, "Duplicate registration of 'ch01.test_node' must be rejected")
	_assert_eq(registry.resolve(&"ch01.test_node"), node1, "Original node must remain registered")

	node1.free()
	node2.free()
	registry.free()


func test_unregister_and_resolve() -> void:
	var registry = IdRegistry.new()
	var node = Node.new()

	registry.register(&"ch01.temp_item", node)
	_assert_true(registry.has_id(&"ch01.temp_item"), "Registry should contain registered ID")

	var unreg_ok = registry.unregister(&"ch01.temp_item")
	_assert_true(unreg_ok, "Unregistering valid ID should return true")
	_assert_false(registry.has_id(&"ch01.temp_item"), "Registry should no longer contain unregistered ID")
	_assert_eq(registry.resolve(&"ch01.temp_item"), null, "Unregistered ID should resolve to null")

	node.free()
	registry.free()
