class_name NarrativeState
extends Node

## Session narrative flags and collected memory fragments (ADR-011 session service).
## Flags, memory fragments and the journal (observation / fact / theory, PRD §11).

signal flag_changed(flag_id: StringName, value: Variant)
signal fragment_collected(fragment_id: StringName)
signal journal_entry_added(entry_key: String, category: String)
signal document_read(document: DocumentDef)

const JOURNAL_CATEGORIES: Array[String] = ["observation", "fact", "theory"]

var _flags: Dictionary = {}
var _fragments: Array[StringName] = []
var _journal: Array[Dictionary] = []   # [{"key": String, "category": String}] in discovery order


func set_flag(flag_id: StringName, value: Variant = true) -> void:
	if _flags.get(flag_id) == value:
		return
	_flags[flag_id] = value
	flag_changed.emit(flag_id, value)


func get_flag(flag_id: StringName, default: Variant = false) -> Variant:
	return _flags.get(flag_id, default)


## Returns false if already collected.
func collect_fragment(fragment_id: StringName) -> bool:
	if fragment_id in _fragments:
		return false
	_fragments.append(fragment_id)
	fragment_collected.emit(fragment_id)
	return true


func has_fragment(fragment_id: StringName) -> bool:
	return fragment_id in _fragments


## Journal entry (PRD §11). Duplicate keys are ignored; an entry may be promoted later
## (e.g. theory -> fact) by adding it again with a different category.
func add_journal_entry(entry_key: String, category: String = "observation") -> bool:
	if entry_key.is_empty() or not category in JOURNAL_CATEGORIES:
		return false
	for entry in _journal:
		if entry["key"] == entry_key:
			if entry["category"] == category:
				return false
			entry["category"] = category
			journal_entry_added.emit(entry_key, category)
			return true
	_journal.append({"key": entry_key, "category": category})
	journal_entry_added.emit(entry_key, category)
	return true


func get_journal() -> Array[Dictionary]:
	return _journal.duplicate(true)


## Applies a document's effects (flag, fragment, journal) and announces it.
func read_document(document: DocumentDef) -> void:
	if document == null:
		return
	set_flag(StringName("read.%s" % document.document_id))
	if not String(document.flag_id).is_empty():
		set_flag(document.flag_id)
	if not String(document.fragment_id).is_empty():
		collect_fragment(document.fragment_id)
	if not document.journal_entry_key.is_empty():
		add_journal_entry(document.journal_entry_key, document.journal_category)
	document_read.emit(document)


func export_journal() -> Array:
	return _journal.duplicate(true)


func import_journal(entries: Array) -> void:
	_journal.clear()
	for entry in entries:
		if entry is Dictionary and String(entry.get("category", "")) in JOURNAL_CATEGORIES:
			_journal.append({"key": String(entry.get("key", "")), "category": String(entry["category"])})


func export_flags() -> Dictionary:
	var out := {}
	for key in _flags.keys():
		out[String(key)] = _flags[key]
	return out


func export_fragments() -> Array:
	var out: Array = []
	for id in _fragments:
		out.append(String(id))
	return out


func import_state(flags: Dictionary, fragments: Array) -> void:
	_flags.clear()
	for key in flags.keys():
		_flags[StringName(str(key))] = flags[key]
	_fragments.clear()
	for id in fragments:
		var fragment := StringName(str(id))
		if not fragment in _fragments:
			_fragments.append(fragment)
