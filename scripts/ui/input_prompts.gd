class_name InputPrompts
extends RefCounted

## Dynamic input glyph and prompt resolution per ADR-015 and ISSUE-007.
## Resolves action bindings into contextual glyphs for keyboard or joypad.

static var is_joypad_mode: bool = false

const JOY_GLYPHS: Dictionary = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "LS",
	JOY_BUTTON_RIGHT_STICK: "RS",
	JOY_BUTTON_DPAD_UP: "D-Up",
	JOY_BUTTON_DPAD_DOWN: "D-Down",
	JOY_BUTTON_DPAD_LEFT: "D-Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Right",
}


static func set_joypad_mode(joypad: bool) -> void:
	is_joypad_mode = joypad


static func get_action_glyph(action: StringName, prefer_joypad: bool = false) -> String:
	var use_joy = prefer_joypad or is_joypad_mode
	if not InputMap.has_action(action):
		return "[?]"

	var events = InputMap.action_get_events(action)
	var key_glyph := ""
	var mouse_glyph := ""
	var joy_glyph := ""

	for ev in events:
		if ev is InputEventKey and key_glyph == "":
			var code = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
			if code != KEY_NONE:
				key_glyph = "[" + OS.get_keycode_string(code) + "]"
		elif ev is InputEventMouseButton and mouse_glyph == "":
			match ev.button_index:
				MOUSE_BUTTON_LEFT:
					mouse_glyph = "[LMB]"
				MOUSE_BUTTON_RIGHT:
					mouse_glyph = "[RMB]"
				MOUSE_BUTTON_MIDDLE:
					mouse_glyph = "[MMB]"
				MOUSE_BUTTON_WHEEL_UP:
					mouse_glyph = "[WheelUp]"
				MOUSE_BUTTON_WHEEL_DOWN:
					mouse_glyph = "[WheelDown]"
		elif ev is InputEventJoypadButton and joy_glyph == "":
			var label = JOY_GLYPHS.get(ev.button_index, "Btn%d" % ev.button_index)
			joy_glyph = "[" + label + "]"

	var primary_key = key_glyph if key_glyph != "" else mouse_glyph
	if use_joy:
		return joy_glyph if joy_glyph != "" else primary_key
	else:
		return primary_key if primary_key != "" else joy_glyph


static func format_prompt(action: StringName, prompt_tr_key: String = "PROMPT_USE", prefer_joypad: bool = false) -> String:
	UIFeedback.init_translations()
	var glyph = get_action_glyph(action, prefer_joypad)
	var label = String(TranslationServer.translate(StringName(prompt_tr_key)))
	return "%s %s" % [glyph, label]


static func get_movement_glyph(prefer_joypad: bool = false) -> String:
	var use_joy = prefer_joypad or is_joypad_mode
	return "[LS]" if use_joy else "[WASD]"


static func format_movement_hint(prefer_joypad: bool = false) -> String:
	UIFeedback.init_translations()
	var glyph = get_movement_glyph(prefer_joypad)
	var template = String(TranslationServer.translate(&"UI_HINT_MOVE"))
	if "%s" in template:
		return template % glyph
	return "%s %s" % [template, glyph]
