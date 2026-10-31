extends "res://tests/support/base_test.gd"

## Automated unit tests for HUD feedback toast, localization resolution,
## and dynamic input prompts per ADR-015, ISSUE-006, and ISSUE-007.


func test_translations_registered_in_project_settings() -> void:
	# Verifies project.godot locale/translations registration (R2a)
	var hint_text = tr("PZ001_HINT_1")
	_assert_true(hint_text != "PZ001_HINT_1" and not hint_text.is_empty(), "PZ001_HINT_1 translates to English")

	var fb_text = tr("UI_FB_UNSUPPORTED")
	_assert_eq(fb_text, "The pocket watch cannot affect this object.", "UI_FB_UNSUPPORTED translates to English")

	var clock_text = tr("EL_CLOCK_2359")
	_assert_true(clock_text != "EL_CLOCK_2359" and not clock_text.is_empty(), "EL_CLOCK_2359 translates to English")
	_assert_eq(clock_text, "23:59. The seconds digit flickers, but it never turns over.")


func test_feedback_text_resolves_all_standard_reasons() -> void:
	UIFeedback.init_translations()

	_assert_eq(UIFeedback.get_feedback_text(&"unsupported"), "The pocket watch cannot affect this object.")
	_assert_eq(UIFeedback.get_feedback_text(&"frozen"), "Object is locked in time - unfreeze it first.")
	_assert_eq(UIFeedback.get_feedback_text(&"no_history"), "No earlier temporal state recorded for this object.")
	_assert_eq(UIFeedback.get_feedback_text(&"jammed"), "Mechanism is jammed.")
	_assert_eq(UIFeedback.get_feedback_text(&"missing_target"), "Target is no longer present.")
	_assert_eq(UIFeedback.get_feedback_text(&"echo_forbidden"), "An echo cannot claim permanent items or records.")
	_assert_eq(UIFeedback.get_feedback_text(&"already_open"), "Already open.")
	_assert_eq(UIFeedback.get_feedback_text(&"unpowered"), "No power to this mechanism.")
	_assert_eq(UIFeedback.get_feedback_text(&"invalid_graph"), "Route conflict - clear the active loop on the paired junction first.")
	_assert_eq(UIFeedback.get_feedback_text(&"critical_path_unreachable"), "Safety interlock - cannot sever main entry route.")
	_assert_eq(UIFeedback.get_feedback_text(&"echo_busy"), "Echo is already busy.")
	_assert_eq(UIFeedback.get_feedback_text(&"not_recording"), "Not currently recording an echo.")
	_assert_eq(UIFeedback.get_feedback_text(&"no_recording"), "No echo recorded to play back.")


func test_prompt_glyphs_keyboard_vs_joypad() -> void:
	# Keyboard mode
	var key_interact = InputPrompts.get_action_glyph(&"interact", false)
	_assert_eq(key_interact, "[E]", "Keyboard interact glyph should be [E]")

	var key_watch = InputPrompts.get_action_glyph(&"watch", false)
	_assert_eq(key_watch, "[Q]", "Keyboard watch glyph should be [Q]")

	var key_echo_reset = InputPrompts.get_action_glyph(&"echo_reset", false)
	_assert_eq(key_echo_reset, "[R]", "Keyboard echo_reset glyph should be [R]")

	var key_prompt = InputPrompts.format_prompt(&"interact", "PROMPT_USE", false)
	_assert_eq(key_prompt, "[E] Use", "Keyboard formatted prompt should be '[E] Use'")

	# Joypad mode
	var joy_interact = InputPrompts.get_action_glyph(&"interact", true)
	_assert_eq(joy_interact, "[A]", "Joypad interact glyph should be [A]")

	var joy_watch = InputPrompts.get_action_glyph(&"watch", true)
	_assert_eq(joy_watch, "[LB]", "Joypad watch glyph should be [LB]")

	var joy_echo_reset = InputPrompts.get_action_glyph(&"echo_reset", true)
	_assert_eq(joy_echo_reset, "[Y]", "Joypad echo_reset glyph should be [Y]")

	var joy_prompt = InputPrompts.format_prompt(&"interact", "PROMPT_USE", true)
	_assert_eq(joy_prompt, "[A] Use", "Joypad formatted prompt should be '[A] Use'")


func test_hud_feedback_toast_display_and_dismissal() -> void:
	var hud_scene = load("res://scenes/ui/HUD.tscn")
	_assert_true(hud_scene != null, "HUD.tscn should load")

	var hud = hud_scene.instantiate() as HUD
	scene_tree.root.add_child(hud)

	_assert_false(hud.feedback_panel.visible, "Feedback panel should initially be hidden")

	# Show feedback for frozen object
	hud.show_feedback(&"frozen")
	_assert_true(hud.feedback_panel.visible, "Feedback panel should be visible after show_feedback")
	_assert_eq(hud.feedback_label.text, "Object is locked in time - unfreeze it first.")

	# Advance 2.5 seconds -> toast auto-dismisses
	hud._process(2.5)
	_assert_false(hud.feedback_panel.visible, "Feedback panel should auto-hide after toast duration")

	hud.free()
