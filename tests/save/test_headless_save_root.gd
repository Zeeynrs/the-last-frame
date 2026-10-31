extends "res://tests/support/base_test.gd"

## Headless runs never use the player's save folder (ADR-011 am., ISSUE-026, TLF-036).


func test_headless_resolves_to_headless_root() -> void:
	_assert_eq(SaveStore.resolve_default_root("headless", ""), SaveStore.HEADLESS_ROOT, "headless -> headless root")
	_assert_eq(SaveStore.resolve_default_root("headless", "0"), SaveStore.HEADLESS_ROOT, "only '1' overrides")
	_assert_eq(SaveStore.HEADLESS_ROOT, "user://headless/saves", "headless root path")


func test_windowed_resolves_to_real_root() -> void:
	_assert_eq(SaveStore.resolve_default_root("Windows", ""), SaveStore.DEFAULT_ROOT, "windowed -> real root")
	_assert_eq(SaveStore.resolve_default_root("X11", ""), SaveStore.DEFAULT_ROOT, "any non-headless server -> real root")
	_assert_eq(SaveStore.DEFAULT_ROOT, "user://saves", "real root path")


func test_env_override_resolves_to_real_root() -> void:
	_assert_eq(SaveStore.resolve_default_root("headless", "1"), SaveStore.DEFAULT_ROOT, "TLF_ALLOW_REAL_USER_DATA=1 -> real root")
	_assert_eq(SaveStore.resolve_default_root("Windows", "1"), SaveStore.DEFAULT_ROOT, "override is a no-op when windowed")


func test_new_store_uses_the_resolved_root_and_assignment_wins() -> void:
	var expected := SaveStore.resolve_default_root(DisplayServer.get_name(), OS.get_environment(SaveStore.ALLOW_REAL_USER_DATA_ENV))
	var store := SaveStore.new()
	_assert_eq(store.save_root, expected, "a new SaveStore resolves its root at _init")
	store.save_root = "user://tlf_test_explicit_root"
	_assert_eq(store.slot_path(0), "user://tlf_test_explicit_root/slot_0.json", "an explicit save_root wins")
	store.free()


func test_this_headless_run_never_targets_the_real_saves() -> void:
	if not _assert_eq(DisplayServer.get_name(), "headless", "the test runner runs headless"):
		return
	if OS.get_environment(SaveStore.ALLOW_REAL_USER_DATA_ENV) == "1":
		print("  NOTE: TLF_ALLOW_REAL_USER_DATA=1 is set; real-root guard check skipped.")
		return
	var autoload := _tree().root.get_node_or_null("SaveService") as SaveStore
	if _assert_true(autoload != null, "SaveService autoload registered"):
		_assert_eq(autoload.save_root, SaveStore.HEADLESS_ROOT, "SaveService autoload is on the headless root")
		_assert_false(autoload.slot_path(0).begins_with(SaveStore.DEFAULT_ROOT + "/"), "autoload slot path is not under user://saves")
