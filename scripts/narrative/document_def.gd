class_name DocumentDef
extends Resource

## Readable content (ADR-013): documents, audio logs, plaques, terminals. Text by translation key.
## Reading one can set a narrative flag, collect a memory fragment and add a journal entry.

enum Kind { DOCUMENT, AUDIO_LOG, PLAQUE, TERMINAL }

@export var document_id: StringName = &""
@export var kind: Kind = Kind.DOCUMENT
@export var title_key: String = ""
@export var body_key: String = ""
## Optional effects of reading.
@export var flag_id: StringName = &""
@export var fragment_id: StringName = &""
@export var journal_entry_key: String = ""
## PRD §11: the journal separates observations, confirmed facts and unresolved theories.
@export_enum("observation", "fact", "theory") var journal_category: String = "observation"


func is_valid() -> bool:
	return not String(document_id).is_empty() and not title_key.is_empty() and not body_key.is_empty()
