extends RefCounted

## Automated tests for Interactable lifecycle, error logging, and duplicate cleanup protection per TLF-007.

var assert_helper: RefCounted
var scene_tree: SceneTree


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


func _get_tree() -> SceneTree:
	if scene_tree != null:
		return scene_tree
	return Engine.get_main_loop() as SceneTree


func test_duplicate_interactable_removal_preserves_original() -> void:
	var tree = _get_tree()
	var session = GameSession.new()
	var registry = IdRegistry.new()
	registry.name = "IdRegistry"
	session.add_child(registry)
	session.id_registry = registry

	if tree != null and tree.root != null:
		tree.root.add_child(session)

	# 1. Original interactable enters tree under session and registers
	var orig_lever = Interactable.new()
	orig_lever.name = "OriginalLever"
	orig_lever.object_id = &"ch01.test_lever"
	session.add_child(orig_lever)
	if not orig_lever.is_inside_tree():
		orig_lever._ready()

	_assert_eq(registry.resolve(&"ch01.test_lever"), orig_lever, "Original lever must be registered")

	# 2. Duplicate interactable enters tree under session (rejected by IdRegistry)
	var dup_lever = Interactable.new()
	dup_lever.name = "DuplicateLever"
	dup_lever.object_id = &"ch01.test_lever"
	session.add_child(dup_lever)
	if not dup_lever.is_inside_tree():
		dup_lever._ready()

	_assert_eq(registry.resolve(&"ch01.test_lever"), orig_lever, "Original lever must remain registered after duplicate is rejected")

	# 3. Duplicate interactable is removed / destroyed (exits tree)
	if not dup_lever.is_inside_tree():
		dup_lever._exit_tree()
	session.remove_child(dup_lever)
	dup_lever.free()

	# CRITICAL (B1): The original lever MUST NOT have been erased by the duplicate's exit_tree!
	_assert_eq(registry.resolve(&"ch01.test_lever"), orig_lever, "Original lever must STILL be registered after duplicate is freed")

	# 4. Clean up original
	if not orig_lever.is_inside_tree():
		orig_lever._exit_tree()
	session.remove_child(orig_lever)
	orig_lever.free()
	_assert_eq(registry.resolve(&"ch01.test_lever"), null, "Lever must be unregistered after original is freed")

	if tree != null and tree.root != null and session.get_parent() == tree.root:
		tree.root.remove_child(session)
	session.free()


func test_empty_id_interactable_does_not_register() -> void:
	var tree = _get_tree()
	var session = GameSession.new()
	var registry = IdRegistry.new()
	registry.name = "IdRegistry"
	session.add_child(registry)
	session.id_registry = registry

	if tree != null and tree.root != null:
		tree.root.add_child(session)

	var empty_lever = Interactable.new()
	empty_lever.name = "EmptyIdLever"
	empty_lever.object_id = &""
	session.add_child(empty_lever)
	if not empty_lever.is_inside_tree():
		empty_lever._ready()

	_assert_false(registry.has_id(&""), "Empty ID must not be registered in IdRegistry")
	_assert_eq(registry.resolve(&""), null, "Empty ID must not resolve")

	if not empty_lever.is_inside_tree():
		empty_lever._exit_tree()
	session.remove_child(empty_lever)
	empty_lever.free()

	if tree != null and tree.root != null and session.get_parent() == tree.root:
		tree.root.remove_child(session)
	session.free()


func test_interactable_handles_missing_game_session() -> void:
	var orphan_lever = Interactable.new()
	orphan_lever.name = "OrphanLever"
	orphan_lever.object_id = &"ch01.orphan_lever"

	# Calling _ready without any session in ancestry or tree
	orphan_lever._ready()
	_assert_eq(orphan_lever.get_session(), null, "Orphan lever should have no session")

	orphan_lever.free()
