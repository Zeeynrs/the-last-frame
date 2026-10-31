extends "res://tests/support/base_test.gd"

## Automated unit tests for DialogueBox and DialogueTrigger per TLF-032.
## Verifies dialogue sequencing, auto-advance, blocking/non-blocking behavior,
## one-shot flag persistence, and scene trigger integration.


func test_dialogue_box_sequencing_and_advancement() -> void:
	var diag_scene = load("res://scenes/ui/DialogueBox.tscn")
	_assert_true(diag_scene != null, "DialogueBox scene loads")
	var diag = diag_scene.instantiate() as DialogueBox
	scene_tree.root.add_child(diag)

	_assert_false(diag.is_active, "initially inactive")
	_assert_false(diag.visible, "initially hidden")

	var lines = [
		["SPK_ELIAS", "EL_B01_01"],
		["SPK_ELIAS", "EL_B01_02"],
		["SPK_ELIAS", "EL_B01_03"],
	]

	var ok = diag.play_sequence(&"test_seq_01", lines, false)
	_assert_true(ok, "play_sequence returns true")
	_assert_true(diag.is_active, "is_active is true while playing")
	_assert_true(diag.visible, "visible while playing")
	_assert_eq(diag.current_line_index, 0, "starts at line 0")
	_assert_eq(diag.speaker_label.text, "Elias", "speaker is Elias")
	_assert_eq(diag.text_label.text, "Where... is this?", "line 0 text matches")

	# Advance to line 1
	diag.advance_line()
	_assert_eq(diag.current_line_index, 1, "advanced to line 1")
	_assert_eq(diag.text_label.text, "Every clock says 23:59. None of them are moving.", "line 1 text matches")

	# Advance to line 2
	diag.advance_line()
	_assert_eq(diag.current_line_index, 2, "advanced to line 2")
	_assert_eq(diag.text_label.text, "Time doesn't stop. It waits. Where did I hear that?", "line 2 text matches")

	# Advance past last line finishes sequence
	diag.advance_line()
	_assert_false(diag.is_active, "sequence finished and inactive")
	_assert_false(diag.visible, "hidden after completion")

	diag.free()


func test_dialogue_box_auto_advance() -> void:
	var diag_scene = load("res://scenes/ui/DialogueBox.tscn")
	var diag = diag_scene.instantiate() as DialogueBox
	scene_tree.root.add_child(diag)

	var lines = [
		["SPK_OPERATOR", "OP_B05_01"],
		["SPK_ELIAS", "EL_B05_01"],
	]

	diag.play_sequence(&"test_seq_auto", lines, false, 2.0)
	_assert_eq(diag.current_line_index, 0, "starts at line 0")

	# Step 1.5 seconds - not yet advanced
	diag._process(1.5)
	_assert_eq(diag.current_line_index, 0, "still at line 0 before timeout")

	# Step 0.6 seconds - auto advances
	diag._process(0.6)
	_assert_eq(diag.current_line_index, 1, "auto-advanced to line 1")

	# Step 2.1 seconds - auto finishes
	diag._process(2.1)
	_assert_false(diag.is_active, "auto-finished after last line")

	diag.free()


func test_dialogue_box_blocking_stops_player_movement() -> void:
	var diag_scene = load("res://scenes/ui/DialogueBox.tscn")
	var diag = diag_scene.instantiate() as DialogueBox
	scene_tree.root.add_child(diag)

	# Mock player
	var player = CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group(&"player")
	scene_tree.root.add_child(player)

	player.set_physics_process(true)
	_assert_true(player.is_physics_processing(), "player initially processing physics")

	var lines = [["SPK_ELIAS", "EL_B01_01"]]
	diag.play_sequence(&"test_blocking_seq", lines, true)

	_assert_false(player.is_physics_processing(), "player physics stopped during blocking monologue")

	diag.advance_line()
	_assert_false(diag.is_active, "sequence done")
	_assert_true(player.is_physics_processing(), "player physics restored after monologue")

	player.free()
	diag.free()


func test_dialogue_one_shot_flag_and_save_load() -> void:
	var sess_scene = load("res://scenes/session/GameSession.tscn")
	var session = sess_scene.instantiate() as GameSession
	scene_tree.root.add_child(session)

	var diag_scene = load("res://scenes/ui/DialogueBox.tscn")
	var diag = diag_scene.instantiate() as DialogueBox
	scene_tree.root.add_child(diag)

	var lines = [["SPK_OPERATOR", "OP_B03_01"]]

	var ok1 = diag.play_sequence(&"ch01_test_oneshot", lines, false)
	_assert_true(ok1, "first play succeeds")
	_assert_true(session.narrative_state.get_flag(&"heard.ch01_test_oneshot"), "flag heard.ch01_test_oneshot recorded")

	diag.finish_sequence()

	# Replaying same sequence should be rejected
	var ok2 = diag.play_sequence(&"ch01_test_oneshot", lines, false)
	_assert_false(ok2, "re-play is rejected because flag exists")

	# Simulate save & load round-trip
	var exported_flags = session.narrative_state.export_flags()
	_assert_true(exported_flags.has("heard.ch01_test_oneshot"), "flag present in export")

	# Fresh session
	var new_session = sess_scene.instantiate() as GameSession
	new_session.name = "GameSession2"
	scene_tree.root.add_child(new_session)

	new_session.narrative_state.import_state(exported_flags, [])
	_assert_true(new_session.narrative_state.get_flag(&"heard.ch01_test_oneshot"), "flag preserved after import")

	session.free()
	new_session.free()
	diag.free()


class MockUseTarget extends Interactable:
	var use_count: int = 0

	func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
		return &""

	func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
		use_count += 1


func test_dialogue_box_advance_does_not_trigger_interactable() -> void:
	var orig_save_root := ""
	var ss := scene_tree.root.get_node_or_null("SaveService")
	if ss != null and "save_root" in ss:
		orig_save_root = ss.save_root
		ss.save_root = "user://tlf_test_ui_saves"

	var sess_scene = load("res://scenes/session/GameSession.tscn")
	var session = sess_scene.instantiate() as GameSession
	scene_tree.root.add_child(session)

	var diag_scene = load("res://scenes/ui/DialogueBox.tscn")
	var diag = diag_scene.instantiate() as DialogueBox
	scene_tree.root.add_child(diag)

	var player_scene = load("res://scenes/player/Player.tscn")
	var player = player_scene.instantiate() as Player
	player.position = Vector2(100, 100)
	player.add_to_group(&"player")
	scene_tree.root.add_child(player)

	# Create a mock interactable target next to player
	var interactable = MockUseTarget.new()
	interactable.object_id = &"ch01.test_dialogue_target"
	interactable.collision_layer = 4
	interactable.collision_mask = 0
	interactable.position = Vector2(100, 100)
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	interactable.add_child(col)
	scene_tree.root.add_child(interactable)

	# Let physics detect interactable
	await physics_frames(5)
	_assert_eq(player.current_target, interactable, "Player targets interactable next to them")

	# Play a 1-line blocking monologue
	var lines = [["SPK_ELIAS", "EL_B01_01"]]
	diag.play_sequence(&"test_blocking_last_line", lines, true)
	_assert_true(diag.is_active, "Dialogue is active")
	_assert_false(player.is_physics_processing(), "Player movement stopped during blocking dialogue")

	# Advance last line with interact
	await tap(&"interact")
	await physics_frames(3)

	_assert_false(diag.is_active, "Dialogue finished")
	_assert_true(player.is_physics_processing(), "Player unblocked after dialogue finished")
	_assert_eq(interactable.use_count, 0, "Interactable was NOT used when advancing dialogue with interact")

	# Clean up
	interactable.free()
	player.free()
	diag.free()
	session.free()

	if ss != null and "save_root" in ss and orig_save_root != "":
		ss.save_root = orig_save_root
	if DirAccess.dir_exists_absolute("user://tlf_test_ui_saves"):
		var d = DirAccess.open("user://tlf_test_ui_saves")
		if d != null:
			for f in d.get_files():
				d.remove(f)
		DirAccess.remove_absolute("user://tlf_test_ui_saves")

