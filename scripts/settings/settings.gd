extends Node

## Settings and input remapping service per ADR-010, ADR-011, and ADR-015.
## Manages audio volumes, accessibility options, timing assist, and persistent input remapping.

signal setting_changed(key: StringName, value: Variant)

const DEFAULT_SETTINGS_PATH: String = "user://settings.cfg"
## Headless runs (tests, validate.ps1, -s probes) never touch the player's settings (ADR-011 am.,
## ISSUE-026, TLF-036). The shipped game never runs headless.
const HEADLESS_SETTINGS_PATH: String = "user://headless/settings.cfg"
## Set to "1" to let a headless run use the real DEFAULT_SETTINGS_PATH.
const ALLOW_REAL_USER_DATA_ENV: String = "TLF_ALLOW_REAL_USER_DATA"

const GAMEPLAY_ACTIONS: Array[StringName] = [
	&"move_up",
	&"move_down",
	&"move_left",
	&"move_right",
	&"interact",
	&"watch",
	&"ability_next",
	&"ability_prev",
	&"echo_reset",
	&"journal",
	&"pause",
	&"ability_wheel"
]

# Audio settings (0.0 to 1.0)
var master_volume: float = 1.0:
	set(val):
		master_volume = clampf(val, 0.0, 1.0)
		_apply_bus_volume("Master", master_volume)
		setting_changed.emit(&"master_volume", master_volume)

var music_volume: float = 1.0:
	set(val):
		music_volume = clampf(val, 0.0, 1.0)
		_apply_bus_volume("Music", music_volume)
		setting_changed.emit(&"music_volume", music_volume)

var ambience_volume: float = 1.0:
	set(val):
		ambience_volume = clampf(val, 0.0, 1.0)
		_apply_bus_volume("Ambience", ambience_volume)
		setting_changed.emit(&"ambience_volume", ambience_volume)

var sfx_volume: float = 1.0:
	set(val):
		sfx_volume = clampf(val, 0.0, 1.0)
		_apply_bus_volume("SFX", sfx_volume)
		setting_changed.emit(&"sfx_volume", sfx_volume)

var voice_volume: float = 1.0:
	set(val):
		voice_volume = clampf(val, 0.0, 1.0)
		_apply_bus_volume("Voice", voice_volume)
		setting_changed.emit(&"voice_volume", voice_volume)

# Accessibility settings
var text_scale: float = 1.0:
	set(val):
		text_scale = clampf(val, 0.75, 2.0)
		setting_changed.emit(&"text_scale", text_scale)

var subtitles_enabled: bool = true:
	set(val):
		subtitles_enabled = bool(val)
		setting_changed.emit(&"subtitles_enabled", subtitles_enabled)

var reduced_effects: bool = false:
	set(val):
		reduced_effects = bool(val)
		setting_changed.emit(&"reduced_effects", reduced_effects)

var assist_extended_timing: bool = false:
	set(val):
		assist_extended_timing = bool(val)
		setting_changed.emit(&"assist_extended_timing", assist_extended_timing)

var screen_shake: float = 1.0:
	set(val):
		screen_shake = clampf(val, 0.0, 1.0)
		setting_changed.emit(&"screen_shake", screen_shake)

var wheel_toggle_mode: bool = false:
	set(val):
		wheel_toggle_mode = bool(val)
		setting_changed.emit(&"wheel_toggle_mode", wheel_toggle_mode)

## Resolved once in _init(); an explicit assignment (tests set their own paths) still wins.
var settings_path: String = DEFAULT_SETTINGS_PATH

var _default_bindings: Dictionary = {}   # Dictionary[StringName, Array[InputEvent]]
var _custom_bindings: Dictionary = {}    # Dictionary[StringName, Dictionary[StringName, InputEvent]]


## Default settings file for a display server name and the TLF_ALLOW_REAL_USER_DATA value.
static func resolve_default_settings_path(display_name: String, env_override: String) -> String:
	if display_name == "headless" and env_override != "1":
		return HEADLESS_SETTINGS_PATH
	return DEFAULT_SETTINGS_PATH


func _init() -> void:
	settings_path = resolve_default_settings_path(DisplayServer.get_name(), OS.get_environment(ALLOW_REAL_USER_DATA_ENV))
	_cache_default_bindings()


func _ready() -> void:
	if DisplayServer.get_name() == "headless" and get_parent() == get_tree().root:
		print("Settings: headless, path = %s (%s)%s" % [settings_path, ProjectSettings.globalize_path(settings_path),
			" [%s=1]" % ALLOW_REAL_USER_DATA_ENV if OS.get_environment(ALLOW_REAL_USER_DATA_ENV) == "1" else ""])
	load_settings()


## Calculates puzzle timing windows taking accessibility assist into account.
## Base 180 ticks becomes ceil(180 * 5/3) = 300 ticks when assist is on.
func get_timing_window(base_ticks: int) -> int:
	if assist_extended_timing:
		return int(ceil(float(base_ticks) * 5.0 / 3.0))
	return base_ticks


## Resets all audio, accessibility, and input bindings to project defaults.
func reset_to_defaults() -> void:
	master_volume = 1.0
	music_volume = 1.0
	ambience_volume = 1.0
	sfx_volume = 1.0
	voice_volume = 1.0
	text_scale = 1.0
	subtitles_enabled = true
	reduced_effects = false
	assist_extended_timing = false
	screen_shake = 1.0
	wheel_toggle_mode = false

	apply_audio_volumes()
	reset_all_bindings()


## Saves settings to `settings_path` (user://settings.cfg; user://headless/settings.cfg headless).
func save_settings() -> Error:
	var config = ConfigFile.new()

	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "ambience_volume", ambience_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "voice_volume", voice_volume)

	config.set_value("accessibility", "text_scale", text_scale)
	config.set_value("accessibility", "subtitles_enabled", subtitles_enabled)
	config.set_value("accessibility", "reduced_effects", reduced_effects)
	config.set_value("accessibility", "assist_extended_timing", assist_extended_timing)
	config.set_value("accessibility", "screen_shake", screen_shake)
	config.set_value("accessibility", "wheel_toggle_mode", wheel_toggle_mode)

	# Serialize custom bindings
	for action in _custom_bindings:
		for slot in _custom_bindings[action]:
			var ev = _custom_bindings[action][slot] as InputEvent
			var serialized = _serialize_event(ev)
			if not serialized.is_empty():
				config.set_value("bindings", String(action) + "/" + String(slot), serialized)

	# user://headless/ may not exist yet; ConfigFile.save() does not create folders.
	DirAccess.make_dir_recursive_absolute(settings_path.get_base_dir())
	return config.save(settings_path)


## Loads settings from config file, applying clamp limits and falling back to defaults on error.
func load_settings() -> Error:
	var config = ConfigFile.new()
	var err = config.load(settings_path)
	if err != OK:
		if FileAccess.file_exists(settings_path):
			push_warning("Settings file '%s' exists but failed to parse (error %d). Resetting to defaults." % [settings_path, err])
		reset_to_defaults()
		return err

	master_volume = clampf(float(config.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
	ambience_volume = clampf(float(config.get_value("audio", "ambience_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0)
	voice_volume = clampf(float(config.get_value("audio", "voice_volume", 1.0)), 0.0, 1.0)

	text_scale = clampf(float(config.get_value("accessibility", "text_scale", 1.0)), 0.75, 2.0)
	subtitles_enabled = bool(config.get_value("accessibility", "subtitles_enabled", true))
	reduced_effects = bool(config.get_value("accessibility", "reduced_effects", false))
	assist_extended_timing = bool(config.get_value("accessibility", "assist_extended_timing", false))
	screen_shake = clampf(float(config.get_value("accessibility", "screen_shake", 1.0)), 0.0, 1.0)
	wheel_toggle_mode = bool(config.get_value("accessibility", "wheel_toggle_mode", false))

	apply_audio_volumes()

	if config.has_section("bindings"):
		for key in config.get_section_keys("bindings"):
			var parts = key.split("/")
			if parts.size() == 2:
				var action = StringName(parts[0])
				var slot = StringName(parts[1])
				var serialized = config.get_value("bindings", key)
				if serialized is Dictionary:
					var ev = _deserialize_event(serialized)
					if ev != null:
						remap_action(action, slot, ev)

	return OK


## Applies volume levels to corresponding AudioServer buses in dB.
func apply_audio_volumes() -> void:
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("Ambience", ambience_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_volume("Voice", voice_volume)


func _apply_bus_volume(bus_name: String, linear_vol: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		if linear_vol <= 0.0001:
			AudioServer.set_bus_mute(bus_idx, true)
			AudioServer.set_bus_volume_db(bus_idx, -80.0)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_vol))


# --- Remapping Engine ---

func _cache_default_bindings() -> void:
	_default_bindings.clear()
	for action in InputMap.get_actions():
		var ev_list = InputMap.action_get_events(action)
		var copies: Array[InputEvent] = []
		for ev in ev_list:
			copies.append(ev.duplicate(true))
		_default_bindings[action] = copies


## Remaps an action for a given slot (&"keyboard" or &"joypad").
## Returns &"" on success, or &"conflict" / &"unknown_action" / &"invalid_event".
func remap_action(action: StringName, slot: StringName, event: InputEvent) -> StringName:
	if not InputMap.has_action(action):
		return &"unknown_action"

	if event == null:
		return &"invalid_event"

	if slot == &"keyboard":
		if not (event is InputEventKey or event is InputEventMouseButton):
			return &"invalid_event"
	elif slot == &"joypad":
		if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			return &"invalid_event"
		event.device = -1
	else:
		return &"invalid_event"

	if _has_conflict(action, event):
		return &"conflict"

	# Erase existing events for this slot
	var current_events = InputMap.action_get_events(action)
	for cur_ev in current_events:
		var matches_slot = false
		if slot == &"keyboard" and (cur_ev is InputEventKey or cur_ev is InputEventMouseButton):
			matches_slot = true
		elif slot == &"joypad" and (cur_ev is InputEventJoypadButton or cur_ev is InputEventJoypadMotion):
			matches_slot = true

		if matches_slot:
			InputMap.action_erase_event(action, cur_ev)

	InputMap.action_add_event(action, event)

	if not _custom_bindings.has(action):
		_custom_bindings[action] = {}
	_custom_bindings[action][slot] = event.duplicate(true)

	setting_changed.emit(StringName("binding_" + String(action) + "_" + String(slot)), event)
	return &""


## Checks if the event conflicts with any other gameplay action.
## The allow-list permits interact and confirm to share the same button.
func _has_conflict(action: StringName, event: InputEvent) -> bool:
	for other_action in GAMEPLAY_ACTIONS:
		if other_action == action:
			continue

		# Allow-list: interact and confirm share primary button
		if (action == &"interact" and other_action == &"confirm") or (action == &"confirm" and other_action == &"interact"):
			continue

		var other_events = InputMap.action_get_events(other_action)
		for other_ev in other_events:
			if _events_conflict(event, other_ev):
				return true
	return false


func _events_conflict(ev1: InputEvent, ev2: InputEvent) -> bool:
	if ev1 is InputEventKey and ev2 is InputEventKey:
		var k1 = ev1.physical_keycode if ev1.physical_keycode != KEY_NONE else ev1.keycode
		var k2 = ev2.physical_keycode if ev2.physical_keycode != KEY_NONE else ev2.keycode
		return k1 == k2 and k1 != KEY_NONE
	elif ev1 is InputEventMouseButton and ev2 is InputEventMouseButton:
		return ev1.button_index == ev2.button_index
	elif ev1 is InputEventJoypadButton and ev2 is InputEventJoypadButton:
		return ev1.button_index == ev2.button_index
	elif ev1 is InputEventJoypadMotion and ev2 is InputEventJoypadMotion:
		var sign1 = 1 if ev1.axis_value > 0 else (-1 if ev1.axis_value < 0 else 0)
		var sign2 = 1 if ev2.axis_value > 0 else (-1 if ev2.axis_value < 0 else 0)
		return ev1.axis == ev2.axis and sign1 == sign2
	return false


## Restores the default bindings for the specified action.
func reset_action(action: StringName) -> void:
	if not _default_bindings.has(action):
		return

	InputMap.action_erase_events(action)
	for ev in _default_bindings[action]:
		InputMap.action_add_event(action, (ev as InputEvent).duplicate(true))

	_custom_bindings.erase(action)
	setting_changed.emit(StringName("binding_" + String(action) + "_reset"), null)


## Restores all actions to their initial default bindings.
func reset_all_bindings() -> void:
	for action in _default_bindings:
		InputMap.action_erase_events(action)
		for ev in _default_bindings[action]:
			InputMap.action_add_event(action, (ev as InputEvent).duplicate(true))

	_custom_bindings.clear()
	setting_changed.emit(&"bindings_reset_all", null)


# --- Serialization helpers ---

func _serialize_event(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		return {
			"type": "key",
			"physical_keycode": ev.physical_keycode,
			"keycode": ev.keycode
		}
	elif ev is InputEventMouseButton:
		return {
			"type": "mouse_button",
			"button_index": ev.button_index
		}
	elif ev is InputEventJoypadButton:
		return {
			"type": "joy_button",
			"button_index": ev.button_index
		}
	elif ev is InputEventJoypadMotion:
		return {
			"type": "joy_motion",
			"axis": ev.axis,
			"axis_value": ev.axis_value
		}
	return {}


func _deserialize_event(d: Dictionary) -> InputEvent:
	if d == null or not d.has("type"):
		return null

	match d["type"]:
		"key":
			var ev = InputEventKey.new()
			ev.device = -1
			ev.physical_keycode = int(d.get("physical_keycode", 0))
			ev.keycode = int(d.get("keycode", 0))
			return ev
		"mouse_button":
			var ev = InputEventMouseButton.new()
			ev.device = -1
			ev.button_index = int(d.get("button_index", 1))
			return ev
		"joy_button":
			var ev = InputEventJoypadButton.new()
			ev.device = -1
			ev.button_index = int(d.get("button_index", 0))
			return ev
		"joy_motion":
			var ev = InputEventJoypadMotion.new()
			ev.device = -1
			ev.axis = int(d.get("axis", 0))
			ev.axis_value = float(d.get("axis_value", 0.0))
			return ev
	return null
