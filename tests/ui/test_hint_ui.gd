extends "res://tests/support/base_test.gd"

## Automated unit tests for Hint action and HUD integration per TLF-032 / ISSUE-020.
## Verifies input binding, feedback when no puzzle active, escalation ladder (levels 1->2->3),
## cooldown behavior, and already_solved feedback.

const PUZZLE_DIR := "res://data/puzzles/ch01"


func test_hint_action_binding() -> void:
	_assert_true(InputMap.has_action(&"hint"), "InputMap has 'hint' action")

	var events = InputMap.action_get_events(&"hint")
	var has_h_key = false
	var has_joy_btn = false

	for ev in events:
		if ev is InputEventKey:
			var code = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
			if code == KEY_H:
				has_h_key = true
		elif ev is InputEventJoypadButton:
			if ev.button_index == JOY_BUTTON_RIGHT_SHOULDER and ev.device == -1:
				has_joy_btn = true

	_assert_true(has_h_key, "'hint' bound to keyboard H")
	_assert_true(has_joy_btn, "'hint' bound to Joypad Right Shoulder (device -1)")


func test_hint_hud_request_and_escalation() -> void:
	var sess_scene = load("res://scenes/session/GameSession.tscn")
	var session = sess_scene.instantiate() as GameSession
	scene_tree.root.add_child(session)

	var hud_scene = load("res://scenes/ui/HUD.tscn")
	var hud = hud_scene.instantiate() as HUD
	scene_tree.root.add_child(hud)

	# 1. When no puzzle active in current room
	session.spatial_service.set_actor_room(&"player", &"ch01.arrival_platform")
	hud.request_hint()

	_assert_true(hud.feedback_panel.visible, "feedback shown when no active puzzle")
	_assert_eq(hud.feedback_label.text, "No active puzzle in this area.", "feedback matches UI_FB_NO_ACTIVE_PUZZLE")

	# 2. Load puzzle definitions and set room to concourse_west (CH1-PZ-001)
	session.hint_service.load_defs_from(PUZZLE_DIR)
	session.spatial_service.set_actor_room(&"player", &"ch01.concourse_west")

	# Request Hint Level 1
	session.sim_clock.reset(100)
	hud.request_hint()

	_assert_true(hud.feedback_panel.visible, "hint toast shown")
	var hint1_text = tr("PZ001_HINT_1")
	_assert_eq(hud.feedback_label.text, hint1_text, "level 1 hint text displayed")
	_assert_eq(session.hint_service.get_level(&"CH1-PZ-001"), 1, "hint level is 1")

	# Immediate repeat within cooldown (tick 150 < 100 + 300) should stay at Level 1
	session.sim_clock.reset(150)
	hud.request_hint()
	_assert_eq(hud.feedback_label.text, hint1_text, "level 1 hint repeated within cooldown")
	_assert_eq(session.hint_service.get_level(&"CH1-PZ-001"), 1, "hint level still 1")

	# Request after cooldown (tick 450 >= 100 + 300) escalates to Level 2
	session.sim_clock.reset(450)
	hud.request_hint()
	var hint2_text = tr("PZ001_HINT_2")
	_assert_eq(hud.feedback_label.text, hint2_text, "level 2 hint displayed after cooldown")
	_assert_eq(session.hint_service.get_level(&"CH1-PZ-001"), 2, "hint level escalated to 2")

	# Request after second cooldown (tick 800 >= 450 + 300) escalates to Level 3
	session.sim_clock.reset(800)
	hud.request_hint()
	var hint3_text = tr("PZ001_HINT_3")
	_assert_eq(hud.feedback_label.text, hint3_text, "level 3 hint displayed after cooldown")
	_assert_eq(session.hint_service.get_level(&"CH1-PZ-001"), 3, "hint level escalated to 3 ceiling")

	# 3. Solved puzzle feedback
	session.puzzle_service.mark_solved(&"CH1-PZ-001")
	session.puzzle_service.mark_solved(&"CH1-PZ-006")  # TLF-054: the concourse also holds CH1-PZ-006 (Step 1)
	hud.request_hint()
	_assert_true(hud.feedback_panel.visible, "feedback shown when puzzle already solved")
	_assert_eq(hud.feedback_label.text, "This puzzle is already solved.", "feedback matches UI_FB_ALREADY_SOLVED")

	hud.free()
	session.free()
