class_name ReadableDocument
extends Interactable

## In-world readable (document, audio log, plaque). `use` records its effects in NarrativeState and
## emits `opened` for the UI. Progression object: echoes can't collect it (ADR-006).

signal opened(document: DocumentDef)

@export var document: DocumentDef


func _ready() -> void:
	progression = true
	super._ready()


func _can_use(_actor_id: StringName, interaction_id: StringName, _payload: Dictionary) -> StringName:
	if interaction_id != &"use":
		return &"unsupported"
	if document == null or not document.is_valid():
		return &"missing_target"
	return &""


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	var sess := get_session()
	if sess != null and sess.narrative_state != null:
		sess.narrative_state.read_document(document)
	opened.emit(document)
