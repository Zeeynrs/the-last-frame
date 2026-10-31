extends "res://tests/support/base_test.gd"

## Headless runs never use the player's settings file (ADR-011 am., ISSUE-026, TLF-036).

const SETTINGS_SCRIPT := "res://scripts/settings/settings.gd"


func _script() -> GDScript:
	return load(SETTINGS_SCRIPT) as GDScript


func test_headless_resolves_to_headless_settings() -> void:
	var s := _script()
	_assert_eq(s.resolve_default_settings_path("headless", ""), s.HEADLESS_SETTINGS_PATH, "headless -> headless settings")
	_assert_eq(s.resolve_default_settings_path("headless", "0"), s.HEADLESS_SETTINGS_PATH, "only '1' overrides")
	_assert_eq(s.HEADLESS_SETTINGS_PATH, "user://headless/settings.cfg", "headless settings path")


func test_windowed_resolves_to_real_settings() -> void:
	var s := _script()
	_assert_eq(s.resolve_default_settings_path("Windows", ""), s.DEFAULT_SETTINGS_PATH, "windowed -> real settings")
	_assert_eq(s.DEFAULT_SETTINGS_PATH, "user://settings.cfg", "real settings path")


func test_env_override_resolves_to_real_settings() -> void:
	var s := _script()
	_assert_eq(s.resolve_default_settings_path("headless", "1"), s.DEFAULT_SETTINGS_PATH, "TLF_ALLOW_REAL_USER_DATA=1 -> real settings")


func test_new_settings_use_the_resolved_path_and_assignment_wins() -> void:
	var s := _script()
	var expected: String = s.resolve_default_settings_path(DisplayServer.get_name(), OS.get_environment(s.ALLOW_REAL_USER_DATA_ENV))
	var settings: Node = s.new()
	_assert_eq(settings.settings_path, expected, "new Settings resolve their path at _init")
	settings.settings_path = "user://tlf_test_explicit_settings.cfg"
	_assert_eq(settings.settings_path, "user://tlf_test_explicit_settings.cfg", "an explicit settings_path wins")
	settings.free()


func test_this_headless_run_never_targets_the_real_settings() -> void:
	var s := _script()
	if not _assert_eq(DisplayServer.get_name(), "headless", "the test runner runs headless"):
		return
	if OS.get_environment(s.ALLOW_REAL_USER_DATA_ENV) == "1":
		print("  NOTE: TLF_ALLOW_REAL_USER_DATA=1 is set; real-settings guard check skipped.")
		return
	var autoload := _tree().root.get_node_or_null("Settings")
	if _assert_true(autoload != null, "Settings autoload registered"):
		_assert_eq(autoload.settings_path, s.HEADLESS_SETTINGS_PATH, "Settings autoload is on the headless path")
