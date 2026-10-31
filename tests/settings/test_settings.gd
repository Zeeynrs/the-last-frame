extends RefCounted

## Automated tests for Settings service, ConfigFile persistence, audio bus volume scaling,
## accessibility timing assist, input remapping, and echo_reset action per TLF-017.

var assert_helper: RefCounted
var scene_tree: SceneTree
var _settings_instance: Node

const TEST_CONFIG_ROUNDTRIP: String = "user://test_settings_roundtrip.cfg"
const TEST_CONFIG_CORRUPT: String = "user://test_settings_corrupt.cfg"
const TEST_CONFIG_REMAP: String = "user://test_settings_remap.cfg"


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


func _cleanup_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _get_settings() -> Node:
	if _settings_instance != null:
		return _settings_instance
	if scene_tree != null and scene_tree.root != null and scene_tree.root.has_node("Settings"):
		_settings_instance = scene_tree.root.get_node("Settings")
		return _settings_instance
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null and main_loop.root.has_node("Settings"):
		_settings_instance = main_loop.root.get_node("Settings")
		return _settings_instance
	var SettingsScript = load("res://scripts/settings/settings.gd")
	_settings_instance = SettingsScript.new()
	_settings_instance.name = "Settings"
	if scene_tree != null and scene_tree.root != null:
		scene_tree.root.add_child(_settings_instance)
	elif main_loop is SceneTree and main_loop.root != null:
		main_loop.root.add_child(_settings_instance)
	return _settings_instance


func test_default_settings() -> void:
	var s = _get_settings()
	s.reset_to_defaults()

	_assert_eq(s.master_volume, 1.0, "Default master_volume should be 1.0")
	_assert_eq(s.music_volume, 1.0, "Default music_volume should be 1.0")
	_assert_eq(s.ambience_volume, 1.0, "Default ambience_volume should be 1.0")
	_assert_eq(s.sfx_volume, 1.0, "Default sfx_volume should be 1.0")
	_assert_eq(s.voice_volume, 1.0, "Default voice_volume should be 1.0")

	_assert_eq(s.text_scale, 1.0, "Default text_scale should be 1.0")
	_assert_true(s.subtitles_enabled, "Default subtitles_enabled should be true")
	_assert_false(s.reduced_effects, "Default reduced_effects should be false")
	_assert_false(s.assist_extended_timing, "Default assist_extended_timing should be false")
	_assert_eq(s.screen_shake, 1.0, "Default screen_shake should be 1.0")


func test_save_load_round_trip() -> void:
	var s = _get_settings()
	_cleanup_file(TEST_CONFIG_ROUNDTRIP)
	s.settings_path = TEST_CONFIG_ROUNDTRIP

	s.master_volume = 0.75
	s.music_volume = 0.6
	s.ambience_volume = 0.5
	s.sfx_volume = 0.8
	s.voice_volume = 0.9
	s.text_scale = 1.25
	s.subtitles_enabled = false
	s.reduced_effects = true
	s.assist_extended_timing = true
	s.screen_shake = 0.4

	var save_err = s.save_settings()
	_assert_eq(save_err, OK, "Saving settings should succeed")

	# Reset in memory to defaults
	s.reset_to_defaults()
	_assert_eq(s.master_volume, 1.0)
	_assert_false(s.assist_extended_timing)

	# Load from file
	var load_err = s.load_settings()
	_assert_eq(load_err, OK, "Loading settings should succeed")

	_assert_true(abs(s.master_volume - 0.75) < 0.001, "master_volume should restore to 0.75")
	_assert_true(abs(s.music_volume - 0.6) < 0.001, "music_volume should restore to 0.6")
	_assert_true(abs(s.ambience_volume - 0.5) < 0.001, "ambience_volume should restore to 0.5")
	_assert_true(abs(s.sfx_volume - 0.8) < 0.001, "sfx_volume should restore to 0.8")
	_assert_true(abs(s.voice_volume - 0.9) < 0.001, "voice_volume should restore to 0.9")

	_assert_true(abs(s.text_scale - 1.25) < 0.001, "text_scale should restore to 1.25")
	_assert_false(s.subtitles_enabled, "subtitles_enabled should restore to false")
	_assert_true(s.reduced_effects, "reduced_effects should restore to true")
	_assert_true(s.assist_extended_timing, "assist_extended_timing should restore to true")
	_assert_true(abs(s.screen_shake - 0.4) < 0.001, "screen_shake should restore to 0.4")

	s.reset_to_defaults()
	s.settings_path = s.DEFAULT_SETTINGS_PATH
	_cleanup_file(TEST_CONFIG_ROUNDTRIP)


func test_value_clamping() -> void:
	var s = _get_settings()

	s.master_volume = 1.5
	_assert_eq(s.master_volume, 1.0, "Volume above 1.0 should clamp to 1.0")

	s.master_volume = -0.5
	_assert_eq(s.master_volume, 0.0, "Volume below 0.0 should clamp to 0.0")

	s.text_scale = 3.5
	_assert_eq(s.text_scale, 2.0, "text_scale above 2.0 should clamp to 2.0")

	s.text_scale = 0.2
	_assert_eq(s.text_scale, 0.75, "text_scale below 0.75 should clamp to 0.75")

	s.screen_shake = 2.0
	_assert_eq(s.screen_shake, 1.0, "screen_shake above 1.0 should clamp to 1.0")

	s.screen_shake = -0.2
	_assert_eq(s.screen_shake, 0.0, "screen_shake below 0.0 should clamp to 0.0")

	s.reset_to_defaults()


func test_corrupt_file_handling() -> void:
	var s = _get_settings()
	_cleanup_file(TEST_CONFIG_CORRUPT)

	# Write corrupted INI data with unclosed section header to trigger parse error
	var f = FileAccess.open(TEST_CONFIG_CORRUPT, FileAccess.WRITE)
	f.store_string("[corrupted_section_without_closing_bracket\n")
	f.close()

	s.settings_path = TEST_CONFIG_CORRUPT
	s.master_volume = 0.3
	s.reduced_effects = true

	# Loading corrupt file must not crash and must fallback to defaults
	var err = s.load_settings()
	_assert_true(err != OK, "Loading corrupt file should return an error code")
	_assert_eq(s.master_volume, 1.0, "Corrupt file should cause reset to default master_volume=1.0")
	_assert_false(s.reduced_effects, "Corrupt file should cause reset to default reduced_effects=false")

	s.settings_path = s.DEFAULT_SETTINGS_PATH
	_cleanup_file(TEST_CONFIG_CORRUPT)


func test_bus_volumes_applied() -> void:
	var s = _get_settings()

	var music_idx = AudioServer.get_bus_index("Music")
	_assert_true(music_idx >= 0, "Music bus must exist")

	# Half volume
	s.music_volume = 0.5
	var expected_db = linear_to_db(0.5)
	var actual_db = AudioServer.get_bus_volume_db(music_idx)
	_assert_true(abs(actual_db - expected_db) < 0.1, "Music bus volume in dB should match linear_to_db(0.5)")
	_assert_false(AudioServer.is_bus_mute(music_idx), "Music bus should not be muted at 0.5")

	# Zero volume = mute
	s.music_volume = 0.0
	_assert_true(AudioServer.is_bus_mute(music_idx), "Music bus should be muted at 0.0 volume")

	s.reset_to_defaults()


func test_timing_window_assist() -> void:
	var s = _get_settings()

	# Assist OFF: timing window equals base ticks
	s.assist_extended_timing = false
	_assert_eq(s.get_timing_window(180), 180, "When assist is off, 180 base ticks should return 180")
	_assert_eq(s.get_timing_window(60), 60, "When assist is off, 60 base ticks should return 60")

	# Assist ON: base * 5/3 (180 -> 300)
	s.assist_extended_timing = true
	_assert_eq(s.get_timing_window(180), 300, "When assist is on, 180 base ticks should extend to 300 (ceil(180*5/3))")
	_assert_eq(s.get_timing_window(60), 100, "When assist is on, 60 base ticks should extend to 100")

	s.reset_to_defaults()


func test_remap_success() -> void:
	var s = _get_settings()

	# Remap move_up keyboard binding to Key I (physical_keycode 73)
	var new_key = InputEventKey.new()
	new_key.physical_keycode = KEY_I

	var res = s.remap_action(&"move_up", &"keyboard", new_key)
	_assert_eq(res, &"", "Remap of move_up to Key I should succeed")

	# Verify InputMap has Key I bound to move_up
	var events = InputMap.action_get_events(&"move_up")
	var has_key_i: bool = false
	for ev in events:
		if ev is InputEventKey and ev.physical_keycode == KEY_I:
			has_key_i = true
			break
	_assert_true(has_key_i, "InputMap move_up must now contain Key I")

	s.reset_action(&"move_up")


func test_remap_conflict_rejected() -> void:
	var s = _get_settings()

	# Key W is already bound to move_up. Attempting to remap interact to Key W must fail with &"conflict"
	var conflict_key = InputEventKey.new()
	conflict_key.physical_keycode = KEY_W

	var res = s.remap_action(&"interact", &"keyboard", conflict_key)
	_assert_eq(res, &"conflict", "Binding conflicting key should return &\"conflict\"")

	# Verify interact binding was not changed
	var events = InputMap.action_get_events(&"interact")
	for ev in events:
		if ev is InputEventKey:
			_assert_eq(ev.physical_keycode, KEY_E, "interact key should remain Key E")


func test_remap_allow_list_interact_confirm() -> void:
	var s = _get_settings()

	# interact and confirm are allow-listed to share South button / Space / E
	var space_key = InputEventKey.new()
	space_key.physical_keycode = KEY_SPACE

	# Remapping interact to Key_SPACE (which confirm uses) must NOT conflict due to allow-list
	var res = s.remap_action(&"interact", &"keyboard", space_key)
	_assert_eq(res, &"", "Allow-list must permit interact and confirm to share binding")

	s.reset_action(&"interact")


func test_remap_persisted_and_reapplied() -> void:
	var s = _get_settings()
	_cleanup_file(TEST_CONFIG_REMAP)
	s.settings_path = TEST_CONFIG_REMAP

	# Remap pause key to Key O (79)
	var key_o = InputEventKey.new()
	key_o.physical_keycode = KEY_O
	s.remap_action(&"pause", &"keyboard", key_o)

	s.save_settings()

	# Reset all bindings to project defaults
	s.reset_all_bindings()

	var events_reset = InputMap.action_get_events(&"pause")
	var has_key_o_reset: bool = false
	for ev in events_reset:
		if ev is InputEventKey and ev.physical_keycode == KEY_O:
			has_key_o_reset = true
	_assert_false(has_key_o_reset, "After reset_all_bindings, Key O should no longer be present")

	# Reload from settings file: should re-apply Key O
	s.load_settings()

	var events_reloaded = InputMap.action_get_events(&"pause")
	var has_key_o_reloaded: bool = false
	for ev in events_reloaded:
		if ev is InputEventKey and ev.physical_keycode == KEY_O:
			has_key_o_reloaded = true
	_assert_true(has_key_o_reloaded, "After load_settings, custom binding Key O should be restored")

	s.reset_all_bindings()
	s.settings_path = s.DEFAULT_SETTINGS_PATH
	_cleanup_file(TEST_CONFIG_REMAP)


func test_reset_action() -> void:
	var s = _get_settings()

	var key_y = InputEventKey.new()
	key_y.physical_keycode = KEY_Y
	s.remap_action(&"journal", &"keyboard", key_y)

	# Reset only journal
	s.reset_action(&"journal")

	var events = InputMap.action_get_events(&"journal")
	var has_key_j: bool = false
	for ev in events:
		if ev is InputEventKey and ev.physical_keycode == KEY_J:
			has_key_j = true
	_assert_true(has_key_j, "journal action must be restored to default Key J")


func test_joypad_device_minus_one_preserved() -> void:
	var s = _get_settings()

	# Create joypad button with explicit device = 3
	var joy_btn = InputEventJoypadButton.new()
	joy_btn.device = 3
	joy_btn.button_index = JOY_BUTTON_RIGHT_STICK

	s.remap_action(&"journal", &"joypad", joy_btn)

	var events = InputMap.action_get_events(&"journal")
	for ev in events:
		if ev is InputEventJoypadButton:
			_assert_eq(ev.device, -1, "Joypad event device must be set to -1 (All Devices)")

	s.reset_action(&"journal")


func test_echo_reset_present_and_no_conflicts() -> void:
	_assert_true(InputMap.has_action(&"echo_reset"), "InputMap must have 'echo_reset' action")

	var events = InputMap.action_get_events(&"echo_reset")
	var has_key_r: bool = false
	var has_joy_y: bool = false

	for ev in events:
		if ev is InputEventKey:
			var code = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
			if code == KEY_R:
				has_key_r = true
		elif ev is InputEventJoypadButton:
			if ev.button_index == JOY_BUTTON_Y and ev.device == -1:
				has_joy_y = true

	_assert_true(has_key_r, "echo_reset must be bound to physical Key R")
	_assert_true(has_joy_y, "echo_reset must be bound to Joypad Button Y (index 3) with device -1")


func test_unknown_action_and_invalid_event() -> void:
	var s = _get_settings()

	var key = InputEventKey.new()
	key.physical_keycode = KEY_K

	# Unknown action
	var res1 = s.remap_action(&"fake_action_123", &"keyboard", key)
	_assert_eq(res1, &"unknown_action", "Remapping unknown action must return &\"unknown_action\"")

	# Null event
	var res2 = s.remap_action(&"interact", &"keyboard", null)
	_assert_eq(res2, &"invalid_event", "Remapping null event must return &\"invalid_event\"")

	# Mismatched slot (joypad event in keyboard slot)
	var joy_btn = InputEventJoypadButton.new()
	var res3 = s.remap_action(&"interact", &"keyboard", joy_btn)
	_assert_eq(res3, &"invalid_event", "Joypad event passed to keyboard slot must return &\"invalid_event\"")
