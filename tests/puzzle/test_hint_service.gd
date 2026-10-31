extends "res://tests/support/base_test.gd"

## HintService (FR-010) + Ch1 PuzzleDef data integrity.

const PZ := &"CH1-PZ-T01"


func _def(id: StringName = PZ, room: StringName = &"ch01.test_room") -> PuzzleDef:
	var def := PuzzleDef.new()
	def.puzzle_id = id
	def.room_id = room
	def.title_key = "T_TITLE"
	def.hint_keys = PackedStringArray(["T_HINT_1", "T_HINT_2", "T_HINT_3"])
	return def


func test_hints_escalate_after_cooldown_and_stop_at_level_three() -> void:
	var s := make_session()
	var hints := s.hint_service
	hints.register_def(_def())
	_assert_eq(hints.request_hint(PZ)["text_key"], "T_HINT_1", "first request: nudge")
	_assert_eq(hints.request_hint(PZ)["level"], 1, "within cooldown: same level re-shown")
	s.sim_clock.step(hints.escalation_cooldown_ticks)
	_assert_eq(hints.request_hint(PZ)["text_key"], "T_HINT_2", "after cooldown: rule reminder")
	s.sim_clock.step(hints.escalation_cooldown_ticks)
	_assert_eq(hints.request_hint(PZ)["text_key"], "T_HINT_3", "then next action")
	s.sim_clock.step(hints.escalation_cooldown_ticks)
	_assert_eq(hints.request_hint(PZ)["level"], 3, "ceiling at 3")
	free_session(s)


func test_hints_refused_for_unknown_or_solved_puzzles() -> void:
	var s := make_session()
	s.hint_service.register_def(_def())
	_assert_eq(s.hint_service.request_hint(&"CH1-PZ-NOPE")["reason"], &"unknown_puzzle", "unknown")
	s.puzzle_service.mark_solved(PZ)
	_assert_eq(s.hint_service.request_hint(PZ)["reason"], &"already_solved", "solved")
	free_session(s)


func test_room_hint_targets_first_unsolved_puzzle() -> void:
	var s := make_session()
	s.hint_service.register_def(_def(&"CH1-PZ-T02"))
	s.hint_service.register_def(_def(&"CH1-PZ-T01"))
	s.hint_service.register_def(_def(&"CH1-PZ-T09", &"ch01.other_room"))
	_assert_eq(s.hint_service.request_hint_for_room(&"ch01.test_room")["level"], 1, "hint shown")
	_assert_eq(s.hint_service.get_level(&"CH1-PZ-T01"), 1, "lowest id first")
	s.puzzle_service.mark_solved(&"CH1-PZ-T01")
	s.hint_service.request_hint_for_room(&"ch01.test_room")
	_assert_eq(s.hint_service.get_level(&"CH1-PZ-T02"), 1, "moves on to the next unsolved")
	s.puzzle_service.mark_solved(&"CH1-PZ-T02")
	_assert_eq(s.hint_service.request_hint_for_room(&"ch01.test_room")["reason"], &"no_active_puzzle", "room done")
	free_session(s)


func test_invalid_defs_are_rejected() -> void:
	var s := make_session()
	var bad := _def()
	bad.hint_keys = PackedStringArray(["only_one"])
	_assert_false(s.hint_service.register_def(bad), "needs exactly 3 hints")
	_assert_false(s.hint_service.register_def(null), "null rejected")
	free_session(s)


func test_hint_levels_survive_save_and_load() -> void:
	var s := make_session()
	s.hint_service.register_def(_def())
	s.hint_service.request_hint(PZ)
	s.sim_clock.step(400)
	s.hint_service.request_hint(PZ)
	var save := SaveStore.new()
	var data := save.capture(s, "ch01", "")
	free_session(s)
	var s2 := make_session()
	s2.hint_service.register_def(_def())
	_assert_true(save.apply(s2, save.upgrade(data)["data"])["ok"], "apply ok")
	_assert_eq(s2.hint_service.get_level(PZ), 2, "level restored, no free reset to level 1")
	save.free()
	free_session(s2)


func test_ch01_puzzle_data_is_complete_and_translated() -> void:
	var s := make_session()
	_assert_eq(s.hint_service.load_defs_from("res://data/puzzles/ch01"), 5, "five Ch1 PuzzleDefs load")
	var csv := {}
	var file := FileAccess.open("res://localization/ch01_puzzles.csv", FileAccess.READ)
	var header := file.get_csv_line()
	_assert_eq(Array(header), ["keys", "en"], "csv header")
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2:
			csv[row[0]] = row[1]
	var rooms := {}
	for n in range(1, 6):
		var def := load("res://data/puzzles/ch01/CH1-PZ-00%d.tres" % n) as PuzzleDef
		_assert_true(def.is_valid(), "%s valid" % def.puzzle_id)
		rooms[def.room_id] = true
		for key in [def.title_key] + Array(def.hint_keys):
			_assert_true(String(csv.get(key, "")).length() > 10, "%s has English text" % key)
	_assert_eq(rooms.size(), 5, "each puzzle in its own room")
	# The translation Godot generates on import must return the exact CSV text (commas, apostrophes).
	var translation := load("res://localization/ch01_puzzles.en.translation") as Translation
	_assert_true(translation != null, "generated translation loads")
	if translation != null:
		for key in ["PZ001_HINT_1", "PZ001_HINT_2", "PZ004_HINT_3"]:
			_assert_eq(translation.get_message(key), csv[key], "%s round-trips through import" % key)
	free_session(s)
