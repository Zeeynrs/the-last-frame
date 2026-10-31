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

	var hint_reason_text = tr("UI_FB_NO_ACTIVE_PUZZLE")
	_assert_eq(hint_reason_text, "No active puzzle in this area.")

	var ch_complete_text = tr("UI_CHAPTER_COMPLETE")
	_assert_eq(ch_complete_text, "CHAPTER 1 COMPLETE")


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

	var key_hint = InputPrompts.get_action_glyph(&"hint", false)
	_assert_eq(key_hint, "[H]", "Keyboard hint glyph should be [H]")

	var key_prompt = InputPrompts.format_prompt(&"interact", "PROMPT_USE", false)
	_assert_eq(key_prompt, "[E] Use", "Keyboard formatted prompt should be '[E] Use'")

	# Joypad mode
	var joy_interact = InputPrompts.get_action_glyph(&"interact", true)
	_assert_eq(joy_interact, "[A]", "Joypad interact glyph should be [A]")

	var joy_watch = InputPrompts.get_action_glyph(&"watch", true)
	_assert_eq(joy_watch, "[LB]", "Joypad watch glyph should be [LB]")

	var joy_echo_reset = InputPrompts.get_action_glyph(&"echo_reset", true)
	_assert_eq(joy_echo_reset, "[Y]", "Joypad echo_reset glyph should be [Y]")

	var joy_hint = InputPrompts.get_action_glyph(&"hint", true)
	_assert_eq(joy_hint, "[RB]", "Joypad hint glyph should be [RB]")

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


func test_target_marker_camera_offset_conversion() -> void:
	var hud_scene = load("res://scenes/ui/HUD.tscn")
	var hud = hud_scene.instantiate() as HUD
	scene_tree.root.add_child(hud)

	var watch = PocketWatch.new()
	watch.unlocked_abilities = [&"trace"]
	watch.selected_ability = &"trace"
	hud.bind_pocket_watch(watch)

	# Create a dummy target at world position (200, 150)
	var target = Area2D.new()
	target.set_script(load("res://scripts/interaction/interactable.gd"))
	target.object_id = &"ch01.test_target"
	target.position = Vector2(200, 150)
	scene_tree.root.add_child(target)

	# Set up a camera with an offset of (50, 40)
	var camera = Camera2D.new()
	camera.position = Vector2(50, 40)
	scene_tree.root.add_child(camera)
	camera.make_current()

	await physics_frames(2)

	# Target the object
	watch.current_target = target
	hud._on_target_changed(target)
	hud._update_target_highlight_position()

	_assert_true(hud.target_highlight.visible, "Target highlight is visible with target")
	var target_screen_pos: Vector2 = target.get_global_transform_with_canvas().origin
	var expected_screen_pos: Vector2 = target_screen_pos + Vector2(0, -28)
	var actual_pos: Vector2 = hud.target_highlight.global_position
	var diff := actual_pos.distance_to(expected_screen_pos)
	_assert_true(diff <= 1.0, "Target highlight screen position matches target screen pos + offset")

	# When target is null, marker is invisible
	watch.current_target = null
	hud._on_target_changed(null)
	_assert_false(hud.target_highlight.visible, "Target highlight is hidden when target is null")

	camera.free()
	target.free()
	watch.free()
	hud.free()


func test_use_vs_watch_unsupported_feedback() -> void:
	UIFeedback.init_translations()

	var use_fb = UIFeedback.get_feedback_text(&"unsupported", &"use")
	_assert_eq(use_fb, "Nothing happens.", "use on unsupported object returns 'Nothing happens.'")

	var watch_fb = UIFeedback.get_feedback_text(&"unsupported", &"watch")
	_assert_eq(watch_fb, "The pocket watch cannot affect this object.", "watch on unsupported object returns watch text")

	var hud_scene = load("res://scenes/ui/HUD.tscn")
	var hud = hud_scene.instantiate() as HUD
	scene_tree.root.add_child(hud)

	hud.show_feedback(&"unsupported", &"use")
	_assert_eq(hud.feedback_label.text, "Nothing happens.", "HUD feedback for use shows 'Nothing happens.'")

	hud.show_feedback(&"unsupported", &"watch")
	_assert_eq(hud.feedback_label.text, "The pocket watch cannot affect this object.", "HUD feedback for watch shows watch text")

	hud.free()

