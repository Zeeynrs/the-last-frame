extends SceneTree

## Zero-dependency test runner per ADR-012.
## Discovers res://tests/**/test_*.gd, executes test_* methods,
## records assertion failures, prints summary and exits with failure count.
##
## Frame-stepping (TLF-029): a test that awaits becomes a coroutine; the runner then steps
## physics frames until it completes, or fails it after `timeout_frames` (default 3600).
## Sync tests run back to back in one frame, exactly as before. After every test the runner
## releases all input actions and frees nodes the test left under the root.

const DEFAULT_TIMEOUT_FRAMES: int = 3600

class AssertHelper extends RefCounted:
	var current_file: String = ""
	var current_method: String = ""
	var failures: Array[Dictionary] = []
	## Quiet helpers record without printing (runner self-tests use them for expected failures).
	var quiet: bool = false

	func set_context(file_path: String, method_name: String) -> void:
		current_file = file_path
		current_method = method_name

	func assert_true(condition: bool, message: String = "") -> bool:
		if not condition:
			var msg = message if message != "" else "Expected true, got false"
			_record_failure(msg)
			return false
		return true

	func assert_false(condition: bool, message: String = "") -> bool:
		if condition:
			var msg = message if message != "" else "Expected false, got true"
			_record_failure(msg)
			return false
		return true

	func assert_eq(actual, expected, message: String = "") -> bool:
		if actual != expected:
			var default_msg = "Expected %s, got %s" % [str(expected), str(actual)]
			var msg = "%s (%s)" % [message, default_msg] if message != "" else default_msg
			_record_failure(msg)
			return false
		return true

	func assert_ne(actual, expected, message: String = "") -> bool:
		if actual == expected:
			var default_msg = "Expected not %s, got %s" % [str(expected), str(actual)]
			var msg = "%s (%s)" % [message, default_msg] if message != "" else default_msg
			_record_failure(msg)
			return false
		return true

	func assert_not_null(val, message: String = "") -> bool:
		if val == null:
			var msg = message if message != "" else "Expected non-null value, got null"
			_record_failure(msg)
			return false
		return true

	func fail(message: String = "") -> void:
		var msg = message if message != "" else "Explicit test failure"
		_record_failure(msg)

	func _record_failure(msg: String) -> void:
		failures.append({
			"file": current_file,
			"method": current_method,
			"message": msg
		})
		if not quiet:
			print("  FAIL: [%s::%s] %s" % [current_file, current_method, msg])


var _has_run: bool = false


## Tests run from the first frame: during _init()/_initialize() the root is not yet inside the
## tree, so nodes added by tests would never receive _ready().
func _process(_delta: float) -> bool:
	if not _has_run:
		_has_run = true
		_run_all()
	return false


func _run_all() -> void:
	print("--- Running Test Suite ---")
	var test_files: Array[String] = []
	_discover_test_files("res://tests", test_files)
	test_files.sort()

	if test_files.is_empty():
		print("WARNING: No test files found under res://tests/")
		print("TESTS: 0 passed, 0 failed")
		quit(0)
		return

	var assert_helper = AssertHelper.new()
	var passed: int = 0
	var failed: int = 0

	for file_path in test_files:
		print("Test file: %s" % file_path)
		var script = load(file_path)
		if script == null or not (script is GDScript) or not script.can_instantiate():
			print("  ERROR: Failed to load script %s" % file_path)
			failed += 1
			continue

		var instance = script.new()
		if instance == null:
			print("  ERROR: Failed to instantiate script %s" % file_path)
			failed += 1
			continue

		if "assert_helper" in instance:
			instance.assert_helper = assert_helper
		if "scene_tree" in instance:
			instance.scene_tree = self

		var methods: Array[String] = []
		for m in script.get_script_method_list():
			if m["name"].begins_with("test_"):
				methods.append(m["name"])
		methods.sort()

		for method_name in methods:
			assert_helper.set_context(file_path, method_name)
			if await run_test(instance, method_name, assert_helper):
				passed += 1
				print("  PASS: %s" % method_name)
			else:
				failed += 1

		if instance is Node:
			instance.free()

	print("---------------------------")
	print("TESTS: %d passed, %d failed" % [passed, failed])
	quit(failed)


## Runs one test method and returns true when it recorded no failures. Awaits coroutines
## (stepping physics frames) up to the instance's `timeout_frames`. Always releases input and
## frees nodes the test left under the root. Public so runner self-tests can drive fixtures.
func run_test(instance: Object, method_name: String, helper: AssertHelper) -> bool:
	var failures_before: int = helper.failures.size()
	var root_before: Array[Node] = root.get_children()

	var arg_count: int = 0
	for m in instance.get_script().get_script_method_list():
		if m["name"] == method_name:
			arg_count = m["args"].size()
			break

	var result = instance.call(method_name, helper) if arg_count == 1 else instance.call(method_name)

	if result is Object and result.get_class() == "GDScriptFunctionState":
		var done: Array[bool] = [false]
		result.completed.connect(func(_value) -> void: done[0] = true)
		var limit: int = DEFAULT_TIMEOUT_FRAMES
		if "timeout_frames" in instance:
			limit = instance.timeout_frames
		var frames: int = 0
		while not done[0] and frames < limit:
			await physics_frame
			frames += 1
		if not done[0]:
			helper.fail("Timed out after %d physics frames (async test never finished)" % limit)
			# Detach the abandoned coroutine: its helpers stop driving input and its later
			# assertions go to a discarded helper instead of the next test.
			if "aborted" in instance:
				instance.aborted = true
			if "assert_helper" in instance:
				var discard := AssertHelper.new()
				discard.quiet = true
				instance.assert_helper = discard

	_release_all_input(instance)
	_free_new_root_children(root_before, method_name)
	return helper.failures.size() == failures_before


func make_assert_helper(is_quiet: bool = true) -> AssertHelper:
	var helper := AssertHelper.new()
	helper.quiet = is_quiet
	return helper


func _release_all_input(instance: Object) -> void:
	if instance.has_method("release_all_input"):
		instance.release_all_input()
	# Apply any press still buffered, then clear every action, whoever pressed it.
	Input.flush_buffered_events()
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _free_new_root_children(before: Array[Node], method_name: String) -> void:
	var leftovers: Array[Node] = []
	for child in root.get_children():
		if not before.has(child):
			leftovers.append(child)
	if leftovers.is_empty():
		return
	print("  NOTE: %s left %d node(s) under the root; freed them." % [method_name, leftovers.size()])
	for node in leftovers:
		root.remove_child(node)
		node.free()


func _discover_test_files(dir_path: String, out_files: Array[String]) -> void:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_discover_test_files(dir_path.path_join(file_name), out_files)
		else:
			if file_name.begins_with("test_") and file_name.ends_with(".gd"):
				out_files.append(dir_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
