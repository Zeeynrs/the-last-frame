extends "res://tests/support/ch01_real_input.gd"

## TLF-079 (Appendix D P0, D-P0-01): the HUD readout of a history dial's current value. While a
## concourse dial is the watch or interact target the readout line shows the dial's existing label
## (label_key(), re-read on index_changed); it hides on blur and while a blocking dialogue is
## open, never covers the feedback line or a non-blocking dialogue line, and wraps a long value
## inside its panel. The value text is only ever the
## dial's own label key; the readout has no wording of its own and no "correct" styling.

const R2 := &"ch01.concourse_west"
const CONCOURSE_PATH := "res://scenes/chapters/ch01/rooms/concourse_west.tscn"
const TEXT_CSV := "res://localization/ch01_text.csv"
const DIALS: Array = [&"dial_line", &"dial_platform", &"dial_time"]
const VIEW := Rect2(0, 0, 960, 540)
## The feedback line's slot: 320 px wide, bottom edge 28 px above the bottom of the view.
const FEEDBACK_BOTTOM := 540.0 - 28.0


func _init() -> void:
	timeout_frames = 3600


func _dial(name: StringName) -> HistoryDial:
	return resolve(StringName("ch01.concourse_west." + String(name))) as HistoryDial


func _readout_text(hud: HUD) -> String:
	return hud.readout_label.text if hud.readout_panel.visible else ""


## The label_keys of the three dials in concourse_west.tscn, read from the packed scene.
static func _scene_label_keys() -> Dictionary:
	var keys := {}
	var state := (load(CONCOURSE_PATH) as PackedScene).get_state()
	for i in state.get_node_count():
		if not DIALS.has(state.get_node_name(i)):
			continue
		for p in state.get_node_property_count(i):
			if state.get_node_property_name(i, p) == &"label_keys":
				keys[state.get_node_name(i)] = state.get_node_property_value(i, p)
	return keys


static func _csv_keys() -> Dictionary:
	var keys := {}
	var file := FileAccess.open(TEXT_CSV, FileAccess.READ)
	while file != null and not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2 and not row[0].is_empty():
			keys[row[0]] = row[1]
	return keys


## The HUD updates the readout in _process: wait for idle frames (several physics ticks can fall
## into one idle frame).
func idle_frames(n: int) -> void:
	for i in n:
		await _tree().process_frame


## Standalone HUD with a pocket watch whose current_target is set by the test.
func _standalone_hud() -> Array:
	var hud := (load("res://scenes/ui/HUD.tscn") as PackedScene).instantiate() as HUD
	_tree().root.add_child(hud)
	var watch := PocketWatch.new()
	watch.unlocked_abilities = [&"rewind"]
	watch.selected_ability = &"rewind"
	hud.bind_pocket_watch(watch)
	return [hud, watch]


## Real input: the readout appears when a dial becomes the target, shows its current value,
## changes on the same index_changed signal a Rewind emits (5 -> 4), follows the target from dial to
## dial and disappears when Elias walks away.
func test_readout_follows_focus_and_rewind() -> void:
	if not await start_at(R2, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], [FLAG_REWIND]):
		stop()
		return
	var hud := player.hud
	_assert_false(hud.readout_panel.visible, "no readout at the west door")
	if not await walk_to(player, "concourse -> through the turnstile", Vector2(352, 208)):
		stop()
		return
	_assert_false(hud.readout_panel.visible, "no readout past the turnstile")
	if not await select_ability(&"rewind"):
		stop()
		return

	var line := _dial(&"dial_line")
	if not await walk_to(player, "concourse -> dial_line", Vector2(544, 200), func() -> bool: return player.pocket_watch.current_target == line):
		stop()
		return
	await physics_frames(1)
	await idle_frames(1)
	_assert_eq(line.index, 5, "dial_line starts at index 5")
	_assert_eq(_readout_text(hud), tr("PZ006_LINE_5"), "focus on dial_line: readout shows its current value")
	_assert_eq(_readout_text(hud), "HILL ROAD", "index 5 is HILL ROAD")

	# The HUD is bound to index_changed: its text is already the new value when the signal reaches
	# a listener connected after it, before any further frame.
	var seen: Array = []
	var probe := func(i: int) -> void: seen.append([i, hud.readout_label.text, hud.readout_panel.visible])
	line.index_changed.connect(probe)
	if not await use_watch(&"rewind", line, func() -> bool: return line.index == 4, "dial_line steps back to 4"):
		line.index_changed.disconnect(probe)
		stop()
		return
	line.index_changed.disconnect(probe)
	_assert_eq(seen, [[4, "HOLLOW QUAY", true]], "readout updated on index_changed (5 -> 4)")
	await physics_frames(2)
	await idle_frames(1)
	_assert_eq(_readout_text(hud), "HOLLOW QUAY", "after the Rewind the readout shows index 4")

	for row in [[&"dial_platform", Vector2(576, 216), "PLAT 5"], [&"dial_time", Vector2(608, 232), "23:57"]]:
		var dial := _dial(row[0])
		if not await walk_to(player, "concourse -> %s" % row[0], row[1], func() -> bool: return player.pocket_watch.current_target == dial):
			stop()
			return
		await physics_frames(1)
		await idle_frames(1)
		_assert_eq(_readout_text(hud), tr(dial.label_key()), "%s focused: readout is its label" % row[0])
		_assert_eq(_readout_text(hud), row[2], "%s value at index 5" % row[0])

	if not await walk_to(player, "concourse -> away from the dials", Vector2(352, 208)):
		stop()
		return
	await physics_frames(1)
	await idle_frames(1)
	_assert_false(hud.readout_panel.visible, "blur: the readout disappears")
	_assert_eq(line.index, 4, "dial_line keeps index 4")
	stop()


## Real input: a refusal on a focused dial (Rewind at index 0: no_history) shows on the feedback
## line below the readout. Within the feedback line's 2 s, Elias walks to the next dial and Rewinds
## it: the readout changes and the feedback line keeps its text and place.
func test_readout_does_not_hide_feedback() -> void:
	if not await start_at(R2, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], [FLAG_REWIND]):
		stop()
		return
	var hud := player.hud
	var platform := _dial(&"dial_platform")
	var line := _dial(&"dial_line")
	if not await walk_to(player, "concourse -> through the turnstile", Vector2(352, 208)):
		stop()
		return
	if not await select_ability(&"rewind"):
		stop()
		return
	if not await walk_to(player, "concourse -> dial_platform", Vector2(576, 216), func() -> bool: return player.pocket_watch.current_target == platform):
		stop()
		return
	while platform.index > 0:
		var before := platform.index
		await tap(&"watch")
		if not _assert_true(await until(func() -> bool: return platform.index == before - 1, 10), "dial_platform %d -> %d" % [before, before - 1]):
			stop()
			return
	await tap(&"watch")
	await physics_frames(2)
	await idle_frames(1)
	var refusal := last_refusal(platform)
	_assert_true(not refusal.is_empty() and refusal[2] == &"no_history", "Rewind at index 0 refused: no_history (%s)" % [refusal])
	var refusal_text := UIFeedback.get_feedback_text(&"no_history", &"watch")
	_assert_true(hud.feedback_panel.visible, "the refusal is on the feedback line")
	_assert_eq(hud.feedback_label.text, refusal_text, "feedback text is the refusal")
	_assert_eq(_readout_text(hud), "PLAT 6", "the readout stays up with the feedback line (index 0)")
	_check_stacked(hud, "no_history")

	var start_frame := Engine.get_physics_frames()
	if not await walk_to(player, "concourse -> dial_line", Vector2(544, 200), func() -> bool: return player.pocket_watch.current_target == line):
		stop()
		return
	await idle_frames(1)
	_assert_eq(_readout_text(hud), "HILL ROAD", "the readout follows the new target")
	await tap(&"watch")
	_assert_true(await until(func() -> bool: return line.index == 4, 10), "Rewind 5 -> 4 while the feedback line is up")
	await idle_frames(1)
	_assert_true(Engine.get_physics_frames() - start_frame < 100, "still inside the feedback line's 2 s")
	_assert_eq(_readout_text(hud), "HOLLOW QUAY", "readout follows the Rewind")
	_assert_true(hud.feedback_panel.visible, "the feedback line is still up")
	_assert_eq(hud.feedback_label.text, refusal_text, "the readout did not overwrite the feedback text")
	_check_stacked(hud, "after Rewind")
	stop()


## The readout's bottom edge sits above the feedback line's top edge, both inside the view.
func _check_stacked(hud: HUD, label: String) -> void:
	var fb := hud.feedback_panel.get_global_rect()
	var ro := hud.readout_panel.get_global_rect()
	_assert_eq(fb.end.y, FEEDBACK_BOTTOM, "%s: feedback line in its slot" % label)
	_assert_true(ro.end.y <= fb.position.y, "%s: readout %s above feedback %s" % [label, ro, fb])
	_assert_false(ro.intersects(fb), "%s: readout and feedback do not overlap" % label)
	_assert_true(VIEW.encloses(ro) and VIEW.encloses(fb), "%s: both inside the view" % label)


## Every label key of the three dials exists in ch01_text.csv and translates; every value, and a
## long one, fits inside the readout panel (wrapping upwards) above the feedback line, including
## when a long feedback line wraps to two lines.
func test_label_keys_exist_and_long_values_wrap() -> void:
	var keys := _scene_label_keys()
	var csv := _csv_keys()
	_assert_eq(keys.size(), 3, "three dials in concourse_west.tscn")
	var pair := _standalone_hud()
	var hud: HUD = pair[0]
	var watch: PocketWatch = pair[1]
	var session := make_session()
	var dial := spawn(session, HistoryDial.new(), &"ch01.tlf079_test.dial") as HistoryDial
	await idle_frames(2)
	_assert_false(hud.readout_panel.visible, "no target: no readout")

	for name in DIALS:
		var list: PackedStringArray = keys.get(name, PackedStringArray())
		_assert_eq(list.size(), 6, "%s has six entries" % name)
		dial.label_keys = list
		dial.apply_state({"index": 5})
		watch.current_target = dial
		for i in range(5, -1, -1):
			_assert_true(csv.has(list[i]), "%s is in ch01_text.csv" % list[i])
			_assert_true(tr(list[i]) != list[i] and not tr(list[i]).is_empty(), "%s translates" % list[i])
			dial.apply_state({"index": i})
			await idle_frames(1)
			_assert_eq(_readout_text(hud), csv.get(list[i], "?"), "%s index %d shows %s" % [name, i, list[i]])
			_check_fits(hud, "%s[%d]" % [name, i])

	# A long value (an existing long text key) wraps inside the panel and grows it upwards; a
	# short one shrinks it back to one line.
	var one_line := hud.readout_panel.get_global_rect()
	dial.label_keys = PackedStringArray(["PZ006_LINE_2", "JRN_PZ006_SOLVED"])
	dial.apply_state({"index": 1})
	await idle_frames(2)
	var tall := hud.readout_panel.get_global_rect()
	_assert_true(hud.readout_label.get_line_count() > 1, "the long value wraps (%d lines)" % hud.readout_label.get_line_count())
	_assert_true(tall.size.y > one_line.size.y and tall.end.y == one_line.end.y, "the panel grows upwards: %s -> %s" % [one_line, tall])
	_check_fits(hud, "long value")
	hud.show_feedback(&"invalid_graph", &"watch")
	await idle_frames(3)
	_assert_true(hud.feedback_label.get_line_count() > 1, "the long feedback line wraps")
	_check_fits(hud, "long value + long feedback")
	hud.hide_feedback()
	dial.apply_state({"index": 0})
	await idle_frames(2)
	_assert_eq(_readout_text(hud), "ORCHARD GATE", "back to a short value")
	_assert_eq(hud.readout_panel.get_global_rect(), one_line, "the panel shrinks back to one line in its slot")

	# A non-blocking dialogue line (device voices, Beat 01 while Elias walks): the readout moves
	# above the dialogue panel. A blocking one hides it. It comes back in its slot afterwards.
	hud.dialogue_box.play_sequence(&"tlf079_voice", [["SPK_ELIAS", "EL_B01_01"]], false)
	await idle_frames(2)
	var dialogue_rect := hud.dialogue_box.panel.get_global_rect()
	_assert_true(hud.readout_panel.visible, "non-blocking dialogue: readout still shown")
	_assert_true(hud.readout_panel.get_global_rect().end.y <= dialogue_rect.position.y,
		"non-blocking dialogue: readout %s above the dialogue panel %s" % [hud.readout_panel.get_global_rect(), dialogue_rect])
	_check_fits(hud, "above the dialogue line")
	hud.dialogue_box.finish_sequence()
	hud.dialogue_box.play_sequence(&"tlf079_beat", [["SPK_ELIAS", "EL_B01_01"]], true)
	await idle_frames(2)
	_assert_false(hud.readout_panel.visible, "blocking dialogue: readout hidden")
	hud.dialogue_box.finish_sequence()
	await idle_frames(2)
	_assert_true(hud.readout_panel.visible, "dialogue closed: readout back")
	_assert_eq(hud.readout_panel.get_global_rect(), one_line, "dialogue closed: readout back in its slot")
	watch.current_target = null
	await idle_frames(1)
	_assert_false(hud.readout_panel.visible, "blur: readout hidden")
	_assert_false(dial.index_changed.is_connected(hud._on_readout_index_changed), "blur: unbound from the dial")

	free_session(session)
	watch.free()
	hud.free()


func _check_fits(hud: HUD, label: String) -> void:
	var panel := hud.readout_panel.get_global_rect()
	var text := hud.readout_label.get_global_rect()
	_assert_true(VIEW.encloses(panel), "%s: readout panel %s inside the view" % [label, panel])
	_assert_true(panel.encloses(text), "%s: value %s inside its panel %s" % [label, text, panel])
	_assert_true(text.size.y >= hud.readout_label.get_line_count() * hud.readout_label.get_line_height() - 0.5,
		"%s: every line shown" % label)
	_assert_eq(panel.size.x, 320.0, "%s: panel keeps its 320 px width" % label)
	if hud.feedback_panel.visible:
		_assert_true(panel.end.y <= hud.feedback_panel.get_global_rect().position.y, "%s: above the feedback line" % label)
	else:
		_assert_true(panel.end.y <= FEEDBACK_BOTTOM - 32.0, "%s: above the feedback line's slot" % label)
