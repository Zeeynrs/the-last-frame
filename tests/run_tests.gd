extends SceneTree

## Zero-dependency test runner per ADR-012.
## Discovers res://tests/**/test_*.gd, executes test_* methods,
## records assertion failures, prints summary and exits with failure count.

class AssertHelper extends RefCounted:
	var current_file: String = ""
	var current_method: String = ""
	var failures: Array[Dictionary] = []

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
		print("  FAIL: [%s::%s] %s" % [current_file, current_method, msg])


func _init() -> void:
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
		if script == null or not (script is GDScript):
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

		var method_list = script.get_script_method_list()
		var methods: Array[String] = []
		for m in method_list:
			if m["name"].begins_with("test_"):
				methods.append(m["name"])
		methods.sort()

		for method_name in methods:
			assert_helper.set_context(file_path, method_name)
			var failures_before = assert_helper.failures.size()

			var arg_count: int = 0
			for m in method_list:
				if m["name"] == method_name:
					arg_count = m["args"].size()
					break

			if arg_count == 1:
				instance.call(method_name, assert_helper)
			else:
				instance.call(method_name)

			var failures_after = assert_helper.failures.size()
			if failures_after == failures_before:
				passed += 1
				print("  PASS: %s" % method_name)
			else:
				failed += 1

		if instance is Node:
			instance.free()

	print("---------------------------")
	print("TESTS: %d passed, %d failed" % [passed, failed])
	quit(failed)


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
