extends "res://tests/support/base_test.gd"

## Automated tests for AbilityWheel UI per ADR-021, TLF-052, and ISSUE-041.
## Covers hold Z radial selection, locked slots, dead zone, toggle mode, controller LT+stick,
## SimClock pause, watch action swallowing, position stability, and overlay visibility.

var _session: GameSession = null
var _player: Player = null
var _hud: HUD = null
var _wheel: AbilityWheel = null


func _setup_fixture() -> void:
	UIFeedback.init_translations()

	var sess_scene = load("res://scenes/session/GameSession.tscn")
	_session = sess_scene.instantiate() as GameSession
	scene_tree.root.add_child(_session)

	var player_scene = load("res://scenes/player/Player.tscn")
	_player = player_scene.instantiate() as Player
	_player.name = "Player"
	_player.add_to_group(&"player")
	_player.position = Vector2(100, 100)
	_session.add_child(_player)

	var hud_scene = load("res://scenes/ui/HUD.tscn")
	_hud = hud_scene.instantiate() as HUD
	scene_tree.root.add_child(_hud)

	_hud.bind_pocket_watch(_player.pocket_watch)
	_wheel = _hud.ability_wheel
	if _wheel == null:
		_wheel = _hud.get_node_or_null("AbilityWheel") as AbilityWheel

	await physics_frames(2)


func _get_settings() -> Node:
	if scene_tree != null and scene_tree.root != null and scene_tree.root.has_node("Settings"):
		return scene_tree.root.get_node("Settings")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null and main_loop.root.has_node("Settings"):
		return main_loop.root.get_node("Settings")
	return null


func _cleanup_fixture() -> void:
	release_all_input()
	InputPrompts.set_joypad_mode(false)
	var s := _get_settings()
	if s != null:
		s.wheel_toggle_mode = false
		s.reduced_effects = false

	if _hud != null and is_instance_valid(_hud):
		_hud.free()
		_hud = null
	if _session != null and is_instance_valid(_session):
		_session.free()
		_session = null


func test_hold_z_aim_right_down_selects_freeze() -> void:
	await _setup_fixture()

	var watch := _player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]
	watch.selected_ability = &"trace"
	_wheel._seen_unlocked = [&"trace", &"rewind", &"freeze", &"echo"]

	_assert_false(_wheel.is_open, "Wheel initially closed")
	_assert_false(_session.sim_clock.is_paused, "SimClock starts unpaused")
	_assert_true(_player.is_physics_processing(), "Player starts processing")

	# 1. Hold Z
	press(&"ability_wheel")
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens on hold Z")
	_assert_true(_session.sim_clock.is_paused, "SimClock paused while wheel open")
	_assert_false(_player.is_physics_processing(), "Player input blocked while wheel open")

	# 2. Aim right-down (WASD) -> angle +45 maps to Freeze (seg 2)
	press(&"move_right")
	press(&"move_down")
	_assert_true(await until(func(): return _wheel.current_aimed_segment == 2, 60), "Aim right-down maps to Freeze (seg 2)")

	# 3. Release Z
	release(&"ability_wheel")
	_assert_true(await until(func(): return not _wheel.is_open, 30), "Wheel closes on release Z")
	release(&"move_right")
	release(&"move_down")

	_assert_eq(watch.selected_ability, &"freeze", "Freeze is selected on release")
	_assert_false(_session.sim_clock.is_paused, "SimClock resumed after wheel closes")
	_assert_true(_player.is_physics_processing(), "Player resumed after wheel closes")

	await _cleanup_fixture()


func test_aiming_locked_segment_refused_no_change() -> void:
	await _setup_fixture()

	var watch := _player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]
	watch.selected_ability = &"trace"
	_wheel._seen_unlocked = [&"trace", &"rewind", &"freeze", &"echo"]

	var refused: Array = []
	watch.ability_selection_refused.connect(func(ab, r): refused.append([ab, r]))

	# Open wheel
	press(&"ability_wheel")
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens")

	# Aim left-down -> Fast-Forward (seg 4) which is locked
	press(&"move_left")
	press(&"move_down")
	_assert_true(await until(func(): return _wheel.current_aimed_segment == 4, 60), "Aim left-down maps to Fast-Forward (seg 4)")

	# Release Z
	release(&"ability_wheel")
	_assert_true(await until(func(): return not _wheel.is_open, 30), "Wheel closes")
	release(&"move_left")
	release(&"move_down")

	# Selection unchanged
	_assert_eq(watch.selected_ability, &"trace", "Selection unchanged when aiming at locked slot")
	_assert_eq(refused.size(), 1, "ability_selection_refused emitted once")
	_assert_eq(refused[0], [&"fast_forward", &"ability_locked"], "Refused with ability_locked")

	# Verify HUD toast appeared
	_assert_true(_hud.feedback_panel.visible, "HUD feedback shown for locked ability")
	_assert_eq(_hud.feedback_label.text, "The watch can't do that yet.")

	await _cleanup_fixture()


func test_release_in_dead_zone_no_change() -> void:
	await _setup_fixture()

	var watch := _player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]
	watch.selected_ability = &"trace"
	_wheel._seen_unlocked = [&"trace", &"rewind", &"freeze", &"echo"]

	press(&"ability_wheel")
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens")
	_assert_eq(_wheel.current_aimed_segment, -1, "Initially in dead zone")

	# Release Z without aiming
	release(&"ability_wheel")
	_assert_true(await until(func(): return not _wheel.is_open, 30), "Wheel closes")

	_assert_eq(watch.selected_ability, &"trace", "Selection unchanged on dead zone release")

	await _cleanup_fixture()


func test_toggle_mode_open_confirm_cancel() -> void:
	await _setup_fixture()
	var s := _get_settings()
	if s != null:
		s.wheel_toggle_mode = true

	var watch := _player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]
	watch.selected_ability = &"trace"
	_wheel._seen_unlocked = [&"trace", &"rewind", &"freeze", &"echo"]

	# Tap Z to open
	await tap(&"ability_wheel", 2)
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens and stays open in toggle mode")

	# Aim right-up -> Rewind (seg 1)
	press(&"move_right")
	press(&"move_up")
	_assert_true(await until(func(): return _wheel.current_aimed_segment == 1, 60), "Rewind (seg 1) aimed")
	release(&"move_right")
	release(&"move_up")

	# Tap confirm -> selects Rewind and closes
	await tap(&"confirm", 2)
	_assert_true(await until(func(): return not _wheel.is_open, 30), "Wheel closes on confirm")
	_assert_eq(watch.selected_ability, &"rewind", "Rewind selected on confirm")

	# Open again with ability_wheel key
	await tap(&"ability_wheel", 2)
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens again")

	# Aim down -> Echo (seg 3)
	press(&"move_down")
	_assert_true(await until(func(): return _wheel.current_aimed_segment == 3, 60), "Echo (seg 3) aimed")
	release(&"move_down")

	# Tap ability_wheel again -> selects Echo and closes (ADR-021: press again to select)
	await tap(&"ability_wheel", 2)
	_assert_true(await until(func(): return not _wheel.is_open, 30), "Wheel closes on ability_wheel press again")
	_assert_eq(watch.selected_ability, &"echo", "Echo selected on ability_wheel press again in toggle mode")

	# Open once more to test cancel closes without change
	await tap(&"ability_wheel", 2)
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens for cancel test")

	# Aim Freeze (seg 2)
	press(&"move_right")
	press(&"move_down")
	_assert_true(await until(func(): return _wheel.current_aimed_segment == 2, 60), "Freeze (seg 2) aimed")
	release(&"move_right")
	release(&"move_down")

	# Tap cancel -> closes without change (selection remains Echo)
	await tap(&"cancel", 2)
	_assert_true(await until(func(): return not _wheel.is_open, 30), "Wheel closes on cancel")
	_assert_eq(watch.selected_ability, &"echo", "Selection remains Echo on cancel")

	await _cleanup_fixture()


func test_controller_lt_axis_and_stick_selection() -> void:
	await _setup_fixture()

	var watch := _player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]
	watch.selected_ability = &"trace"
	_wheel._seen_unlocked = [&"trace", &"rewind", &"freeze", &"echo"]

	# Controller LT pressed (axis 4 value 1.0)
	var lt_press := InputEventJoypadMotion.new()
	lt_press.device = 0
	lt_press.axis = JOY_AXIS_TRIGGER_LEFT
	lt_press.axis_value = 1.0
	Input.parse_input_event(lt_press)

	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens with LT axis motion")

	# Right stick aim down-right (X=0.8, Y=0.8) -> Freeze (seg 2)
	var stick_x := InputEventJoypadMotion.new()
	stick_x.device = 0
	stick_x.axis = JOY_AXIS_RIGHT_X
	stick_x.axis_value = 0.8
	Input.parse_input_event(stick_x)

	var stick_y := InputEventJoypadMotion.new()
	stick_y.device = 0
	stick_y.axis = JOY_AXIS_RIGHT_Y
	stick_y.axis_value = 0.8
	Input.parse_input_event(stick_y)

	_assert_true(await until(func(): return _wheel.current_aimed_segment == 2, 60), "Stick aim maps to Freeze (seg 2)")

	# Controller LT released (axis 4 value 0.0)
	var lt_release := InputEventJoypadMotion.new()
	lt_release.device = 0
	lt_release.axis = JOY_AXIS_TRIGGER_LEFT
	lt_release.axis_value = 0.0
	Input.parse_input_event(lt_release)

	_assert_true(await until(func(): return not _wheel.is_open, 30), "Wheel closes on LT release")

	# Reset stick axes
	stick_x.axis_value = 0.0
	stick_y.axis_value = 0.0
	Input.parse_input_event(stick_x)
	Input.parse_input_event(stick_y)

	_assert_eq(watch.selected_ability, &"freeze", "Freeze selected on LT release")

	await _cleanup_fixture()


func test_release_does_not_trigger_watch_action() -> void:
	await _setup_fixture()

	var watch := _player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]
	watch.selected_ability = &"trace"
	_wheel._seen_unlocked = [&"trace", &"rewind", &"freeze", &"echo"]

	var watch_used_count := 0
	watch.watch_used.connect(func(_ab, _target, _res): watch_used_count += 1)

	# Stand near an interactable target
	var target = Area2D.new()
	target.set_script(load("res://scripts/interaction/interactable.gd"))
	target.object_id = &"ch01.wheel_test_target"
	target.position = Vector2(100, 100)
	_session.add_child(target)
	await physics_frames(2)

	# Hold Z and release
	press(&"ability_wheel")
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens")

	release(&"ability_wheel")
	_assert_true(await until(func(): return not _wheel.is_open, 30), "Wheel closes")
	await physics_frames(3)

	_assert_eq(watch_used_count, 0, "Releasing Z swallowed on unblock frame; watch action never triggered")

	target.free()
	await _cleanup_fixture()


func test_segment_positions_stay_identical_after_unlock() -> void:
	await _setup_fixture()

	var watch := _player.pocket_watch
	watch.unlocked_abilities = [&"trace"]
	_wheel._seen_unlocked = [&"trace"]

	# Open with only Trace unlocked
	press(&"ability_wheel")
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens")

	var initial_positions: Array[Vector2] = []
	for i in range(6):
		initial_positions.append(_wheel._seg_nodes[i].position)

	release(&"ability_wheel")
	_assert_true(await until(func(): return not _wheel.is_open, 30), "Wheel closes")

	# Now unlock Rewind, Freeze, Echo, Fast-Forward
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo", &"fast_forward"]

	press(&"ability_wheel")
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens after unlocks")

	for i in range(6):
		var pos: Vector2 = _wheel._seg_nodes[i].position
		_assert_eq(pos, initial_positions[i], "Segment %d position is fixed and identical after unlock" % i)

	release(&"ability_wheel")
	await _cleanup_fixture()


func test_reduced_effects_prevents_pulse() -> void:
	await _setup_fixture()

	var watch := _player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind"]
	_wheel._seen_unlocked = [&"trace"]   # Rewind is new
	_wheel._pulsed_abilities.clear()

	var s := _get_settings()
	if s != null:
		s.reduced_effects = true

	press(&"ability_wheel")
	_assert_true(await until(func(): return _wheel.is_open, 30), "Wheel opens")

	# With reduced_effects = true, _pulsed_abilities must remain empty (no pulse)
	_assert_true(_wheel._pulsed_abilities.is_empty(), "reduced_effects=true prevents ability unlock pulse")
	_assert_eq(_wheel._icon_nodes[1].modulate, Color.WHITE, "Icon modulate remains clean Color.WHITE")

	release(&"ability_wheel")
	await _cleanup_fixture()


func test_modal_priority_blocks_wheel_opening() -> void:
	await _setup_fixture()

	# Open document viewer
	var doc = load("res://data/documents/ch01/doc_evac_notice.tres") as DocumentDef
	_hud.document_viewer.open_document(doc)
	_assert_true(_hud.document_viewer.is_open, "Document viewer is open")

	# Attempt to open wheel
	press(&"ability_wheel")
	await physics_frames(3)
	release(&"ability_wheel")

	_assert_false(_wheel.is_open, "Ability wheel cannot open while modal document viewer is open")

	_hud.document_viewer.close_document()
	await _cleanup_fixture()


func test_issue_041_hud_elements_hidden_during_chapter_complete() -> void:
	await _setup_fixture()

	# Show movement hint on HUD
	_hud.show_message("Move: [WASD]", 10.0)
	_assert_true(_hud.feedback_panel.visible, "Movement hint is visible on HUD")
	_assert_true(_hud.ability_panel.visible, "Ability panel is visible on HUD")

	# Instantiate ChapterCompleteOverlay
	var ovl_scene = load("res://scenes/ui/chapter_complete_overlay.tscn")
	var overlay = ovl_scene.instantiate() as CanvasLayer
	scene_tree.root.add_child(overlay)

	_hud._process(0.1)

	# ISSUE-041 verification: movement hint and HUD prompts hidden while overlay is shown
	_assert_false(_hud.feedback_panel.visible, "ISSUE-041: Feedback panel (movement hint) hidden behind overlay")
	_assert_false(_hud.ability_panel.visible, "ISSUE-041: Ability panel prompts hidden behind overlay")

	overlay.free()
	_hud._process(0.1)

	# After overlay is removed, HUD restores
	_assert_true(_hud.ability_panel.visible, "Ability panel restored when overlay removed")

	await _cleanup_fixture()
