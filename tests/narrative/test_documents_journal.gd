extends "res://tests/support/base_test.gd"

## DocumentDef / ReadableDocument / NarrativeState journal (PRD §11, ADR-013).


func _doc() -> DocumentDef:
	var d := DocumentDef.new()
	d.document_id = &"ch01.waiting_lounge.audio_mira_01"
	d.kind = DocumentDef.Kind.AUDIO_LOG
	d.title_key = "DOC_MIRA_01_TITLE"
	d.body_key = "DOC_MIRA_01_BODY"
	d.flag_id = &"ch01.flag.mira_trace_seen"
	d.fragment_id = &"ch01.fragment.mira_departure"
	d.journal_entry_key = "JRN_CH1_MIRA_PLEA"
	d.journal_category = "fact"
	return d


func _reader(s: GameSession) -> ReadableDocument:
	var r := ReadableDocument.new()
	r.document = _doc()
	return spawn(s, r, &"ch01.waiting_lounge.audio_mira_01") as ReadableDocument


func test_reading_applies_flag_fragment_and_journal_once() -> void:
	var s := make_session()
	var reader := _reader(s)
	var opened: Array = []
	reader.opened.connect(func(d): opened.append(d.document_id))
	_assert_true(s.interaction_service.request(&"player", reader.object_id, &"use").ok, "read ok")
	_assert_true(s.interaction_service.request(&"player", reader.object_id, &"use").ok, "re-read ok")
	var n := s.narrative_state
	_assert_true(n.get_flag(&"read.ch01.waiting_lounge.audio_mira_01"), "read flag")
	_assert_true(n.get_flag(&"ch01.flag.mira_trace_seen"), "story flag")
	_assert_eq(n.export_fragments(), ["ch01.fragment.mira_departure"], "fragment once")
	_assert_eq(n.get_journal(), [{"key": "JRN_CH1_MIRA_PLEA", "category": "fact"}], "journal entry once")
	_assert_eq(opened.size(), 2, "UI notified on every read")
	free_session(s)


func test_echo_cannot_read_documents() -> void:
	var s := make_session()
	var reader := _reader(s)
	_assert_eq(s.interaction_service.request(&"echo.0", reader.object_id, &"use").reason, &"echo_forbidden", "progression object")
	_assert_eq(s.narrative_state.export_fragments(), [], "nothing collected")
	free_session(s)


func test_journal_categories_and_promotion() -> void:
	var s := make_session()
	var n := s.narrative_state
	_assert_true(n.add_journal_entry("JRN_OPERATOR_KNOWS", "theory"), "theory added")
	_assert_false(n.add_journal_entry("JRN_OPERATOR_KNOWS", "theory"), "duplicate ignored")
	_assert_true(n.add_journal_entry("JRN_OPERATOR_KNOWS", "fact"), "promoted to fact")
	_assert_false(n.add_journal_entry("JRN_BAD", "gossip"), "unknown category rejected")
	_assert_eq(n.get_journal(), [{"key": "JRN_OPERATOR_KNOWS", "category": "fact"}], "single promoted entry")
	free_session(s)


func test_journal_survives_save_and_load() -> void:
	var s := make_session()
	_reader(s)
	s.interaction_service.request(&"player", &"ch01.waiting_lounge.audio_mira_01", &"use")
	s.narrative_state.add_journal_entry("JRN_EXTRA", "observation")
	var save := SaveService.new()
	var data := save.capture(s, "ch01", "")
	free_session(s)
	var s2 := make_session()
	_assert_true(save.apply(s2, save.upgrade(data)["data"])["ok"], "apply ok")
	_assert_eq(s2.narrative_state.get_journal().size(), 2, "journal restored")
	_assert_true(s2.narrative_state.has_fragment(&"ch01.fragment.mira_departure"), "fragment restored")
	save.free()
	free_session(s2)


func test_invalid_document_is_refused() -> void:
	var s := make_session()
	var r := ReadableDocument.new()
	r.document = DocumentDef.new()
	spawn(s, r, &"ch01.test.blank_doc")
	_assert_eq(s.interaction_service.request(&"player", r.object_id, &"use").reason, &"missing_target", "empty def refused")
	free_session(s)
