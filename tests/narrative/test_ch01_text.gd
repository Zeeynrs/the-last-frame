extends "res://tests/support/base_test.gd"

## Chapter 1 text data (TLF-024): ASCII-only (TLF Pixel Mono covers ASCII 32-126), length limits,
## spec feedback keys present, DocumentDefs wired to existing keys, multi-line pages survive import.

const TEXT_CSV := "res://localization/ch01_text.csv"
const PUZZLE_CSV := "res://localization/ch01_puzzles.csv"


func _read_csv(path: String) -> Dictionary:
	var out := {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return out
	file.get_csv_line()  # header
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2 and not row[0].is_empty():
			out[row[0]] = row[1]
	return out


func test_text_is_ascii_and_within_limits() -> void:
	for path in [TEXT_CSV, PUZZLE_CSV]:
		var rows := _read_csv(path)
		_assert_true(rows.size() > 0, "%s readable" % path)
		for key in rows.keys():
			var text: String = rows[key]
			var ascii := true
			for i in text.length():
				var c := text.unicode_at(i)
				if c > 126 or (c < 32 and c != 10):
					ascii = false
			_assert_true(ascii, "%s is ASCII-only (pixel font)" % key)
			if key.contains("_FB_"):
				_assert_true(text.length() <= 80, "%s <= 80 chars" % key)
			if key.begins_with("OP_") or key.begins_with("EL_"):
				_assert_true(text.length() <= 120, "%s <= 120 chars" % key)
			if key.begins_with("DOC_") and key.contains("_BODY_"):
				var lines := text.split("\n")
				_assert_true(lines.size() <= 6, "%s <= 6 lines" % key)
				for line in lines:
					_assert_true(line.length() <= 48, "%s line <= 48 chars" % key)


func test_every_feedback_key_in_the_specs_has_text() -> void:
	var rows := _read_csv(TEXT_CSV)
	var regex := RegEx.create_from_string("PZ00[1-5]_FB_[A-Z_]+")
	var found := 0
	for n in range(1, 6):
		var spec := FileAccess.get_file_as_string("res://design/ch01/puzzles/CH1-PZ-00%d.md" % n)
		for m in regex.search_all(spec):
			found += 1
			_assert_true(rows.has(m.get_string()), "%s has text" % m.get_string())
	_assert_true(found >= 17, "spec keys scanned (%d)" % found)


func test_documents_reference_existing_keys_and_load() -> void:
	var rows := _read_csv(TEXT_CSV)
	var dir := DirAccess.open("res://data/documents/ch01")
	var count := 0
	for file in dir.get_files():
		if not file.ends_with(".tres"):
			continue
		var doc := load("res://data/documents/ch01/" + file) as DocumentDef
		count += 1
		_assert_true(doc.is_valid(), "%s valid" % file)
		for key in [doc.title_key, doc.body_key, doc.journal_entry_key]:
			if not key.is_empty():
				_assert_true(rows.has(key), "%s: %s has text" % [file, key])
		_assert_true(doc.journal_category in NarrativeState.JOURNAL_CATEGORIES, "%s category" % file)
	_assert_eq(count, 5, "five Ch1 documents")


func test_revelation_document_applies_its_effects() -> void:
	var s := make_session()
	var reader := ReadableDocument.new()
	reader.document = load("res://data/documents/ch01/dispatch_terminal.tres")
	spawn(s, reader, &"ch01.station_atrium.dispatch_terminal")
	_assert_true(s.interaction_service.request(&"player", reader.object_id, &"use").ok, "read")
	_assert_true(s.narrative_state.get_flag(&"ch01.flag.ledger_2359_revealed"), "revelation flag")
	_assert_eq(s.narrative_state.get_journal(), [{"key": "JRN_CH1_SEAL_ELIAS", "category": "fact"}], "journal fact")
	free_session(s)


func test_multiline_pages_survive_godot_import() -> void:
	var rows := _read_csv(TEXT_CSV)
	var translation := load("res://localization/ch01_text.en.translation") as Translation
	_assert_true(translation != null, "generated translation loads")
	if translation != null:
		for key in ["DOC_DISPATCH_BODY_2", "DOC_MIRA_01_BODY_1", "OP_B03_03"]:
			_assert_eq(translation.get_message(key), rows[key], "%s round-trips (incl. line breaks)" % key)
		_assert_eq(String(translation.get_message("DOC_DISPATCH_BODY_2")).split("\n").size(), 6, "6 lines kept")
