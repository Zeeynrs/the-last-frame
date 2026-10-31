extends "res://tests/support/base_test.gd"

## SaveService (ADR-010 + TLF-019 amendment): capture/apply, atomic disk I/O, versioning, validation.
## Uses a private user:// test folder that is removed after each test.

const ROOT := "user://tlf_test_saves"
const GATE := &"ch01.test.gate"


var _owned: Array[Node] = []


func _service() -> SaveService:
	_wipe()
	var save := SaveService.new()
	save.save_root = ROOT
	_owned.append(save)
	return save


func _wipe() -> void:
	for node in _owned:
		if is_instance_valid(node):
			node.free()
	_owned.clear()
	var dir := DirAccess.open(ROOT)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(ROOT)


func _gate(s: GameSession) -> TemporalTestGate:
	var temporal := make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
		[{"arm_state": &"open", "passage_blocked": false}])
	return spawn(s, TemporalTestGate.new(), GATE, temporal) as TemporalTestGate


func _write_raw(save: SaveService, slot: int, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var file := FileAccess.open(save.slot_path(slot), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_capture_contains_every_section_and_temporal_history() -> void:
	var s := make_session()
	_gate(s)
	spawn(s, Interactable.new(), &"ch01.test.plain")
	s.puzzle_service.mark_solved(&"CH1-PZ-001")
	s.narrative_state.set_flag(&"ch01.flag.watch_acquired")
	s.narrative_state.collect_fragment(&"ch01.fragment.mira_departure")
	var data := _service().capture(s, "ch01", "ch01.cp.concourse_west")
	_assert_eq(data["save_version"], SaveService.SAVE_VERSION, "version")
	_assert_eq(data["checkpoint_id"], "ch01.cp.concourse_west", "checkpoint")
	_assert_eq(data["puzzles"], {"CH1-PZ-001": "SOLVED"}, "puzzles")
	_assert_eq(data["narrative_flags"], {"ch01.flag.watch_acquired": true}, "flags")
	_assert_eq(data["fragments"], ["ch01.fragment.mira_departure"], "fragments")
	_assert_eq(data["temporal"].keys(), [String(GATE)], "only temporal objects captured")
	_assert_eq(data["temporal"][String(GATE)]["cursor"], 1, "history cursor captured")
	free_session(s)
	_wipe()


func test_disk_round_trip_preserves_types_and_leaves_no_temp_file() -> void:
	var save := _service()
	var s := make_session()
	_gate(s)
	var data := save.capture(s, "ch01", "ch01.cp.arrival")
	_assert_eq(save.write_slot(1, data), OK, "write ok")
	_assert_false(FileAccess.file_exists(save.slot_path(1) + ".tmp"), "temp file renamed away")
	var loaded := save.read_slot(1)
	_assert_true(loaded["ok"], "read ok")
	_assert_eq(loaded["data"], data, "identical after round trip")
	var entry: Dictionary = loaded["data"]["temporal"][String(GATE)]["entries"][0]
	_assert_eq(typeof(entry["arm_state"]), TYPE_STRING_NAME, "StringName preserved")
	_assert_eq(typeof(loaded["data"]["save_version"]), TYPE_INT, "int preserved")
	_assert_eq(save.write_slot(1, data), OK, "overwrite existing slot ok")
	free_session(s)
	_wipe()


func test_full_loop_consumed_pre_history_stays_consumed_after_load() -> void:
	var save := _service()
	var a := make_session()
	var gate_a := _gate(a)
	a.interaction_service.request(&"player", GATE, &"rewind")
	a.puzzle_service.mark_solved(&"CH1-PZ-001")
	save.write_slot(2, save.capture(a, "ch01", "ch01.cp.concourse_west"))
	_assert_eq(gate_a.arm_state, &"open", "opened before save")
	free_session(a)

	var b := make_session()
	var gate_b := _gate(b)                     # fresh scene: collapsed, pre-history available
	_assert_eq(gate_b.arm_state, &"collapsed", "fresh scene starts collapsed")
	var result := save.apply(b, save.read_slot(2)["data"])
	_assert_true(result["ok"], "apply ok")
	_assert_eq(gate_b.arm_state, &"open", "restored open")
	_assert_eq(b.interaction_service.request(&"player", GATE, &"rewind").reason, &"no_history", "no second free rewind")
	_assert_true(b.puzzle_service.is_solved(&"CH1-PZ-001"), "puzzle progress restored")
	free_session(b)
	_wipe()


func test_unknown_temporal_ids_are_skipped_not_fatal() -> void:
	var s := make_session()
	var data := SaveService.default_save()
	data["temporal"] = {"ch01.test.gone": {"cursor": 0, "entries": [{"x": 1}], "is_frozen": false}}
	var result := _service().apply(s, data)
	_assert_true(result["ok"], "apply still ok")
	_assert_eq(result["skipped"], ["ch01.test.gone"], "reported as skipped")
	free_session(s)
	_wipe()


func test_missing_and_corrupt_files_fail_gracefully() -> void:
	var save := _service()
	_assert_eq(save.read_slot(9)["reason"], &"no_save", "missing file")
	_write_raw(save, 3, "{ this is not json")
	_assert_eq(save.read_slot(3)["reason"], &"corrupt", "unparseable file")
	_write_raw(save, 4, "[1, 2, 3]")
	_assert_eq(save.read_slot(4)["reason"], &"corrupt", "wrong top-level type")
	_wipe()


func test_newer_version_is_rejected() -> void:
	var save := _service()
	var data := SaveService.default_save()
	data["save_version"] = SaveService.SAVE_VERSION + 1
	_assert_eq(save.upgrade(data)["reason"], &"unsupported_version", "future save refused")
	_wipe()


func test_missing_optional_fields_get_defaults() -> void:
	var save := _service()
	var result := save.upgrade({"save_version": 1, "chapter": "ch01", "checkpoint_id": "ch01.cp.arrival"})
	_assert_true(result["ok"], "upgrade ok")
	_assert_eq(result["data"]["puzzles"], {}, "puzzles default")
	_assert_eq(result["data"]["fragments"], [], "fragments default")
	_assert_eq(result["data"]["settings_ref"], "user://settings.cfg", "settings_ref default")
	_wipe()


func test_migrations_run_in_order_up_to_current_version() -> void:
	var save := _service()
	save.current_version = 3
	save.migrations = {1: _migrate_1_to_2, 2: _migrate_2_to_3}
	var data := SaveService.default_save()
	var result := save.upgrade(data)
	_assert_true(result["ok"], "migrated")
	_assert_eq(result["data"]["save_version"], 3, "version bumped")
	_assert_eq(result["data"]["chapter"], "CH01", "migration 1 applied")
	_assert_eq(result["data"]["narrative_flags"], {"migrated": true}, "migration 2 applied")
	save.migrations.erase(2)
	_assert_eq(save.upgrade(SaveService.default_save())["reason"], &"unsupported_version", "gap in chain refused")
	_wipe()


func test_invalid_structure_is_refused_for_read_and_write() -> void:
	var save := _service()
	var bad := SaveService.default_save()
	bad["puzzles"] = "not a dictionary"
	_assert_eq(save.validate(bad)["reason"], &"invalid", "validate catches wrong type")
	_assert_eq(save.write_slot(5, bad), ERR_INVALID_DATA, "invalid data never written")
	_assert_false(save.has_slot(5), "no file created")
	_wipe()


func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	data["chapter"] = String(data["chapter"]).to_upper()
	return data


func _migrate_2_to_3(data: Dictionary) -> Dictionary:
	data["narrative_flags"]["migrated"] = true
	return data
