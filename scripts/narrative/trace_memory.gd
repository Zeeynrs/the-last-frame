class_name TraceMemory
extends Interactable

## A residual memory the Trace ability reveals (TLF-050, CH01_EXPANSION.md 0.1): Trace becomes the
## information ability. Built on Interactable's existing _on_traced() hook (no contract change).
##
## Every trace plays `lines` as a non-blocking dialogue (sequence `trace.<object_id>`, advanced by
## confirm or after `auto_advance` seconds) and emits memory_revealed. The first trace also sets
## `flag_id` and adds the journal entry; later traces only replay the lines (or nothing, with
## `one_shot_dialogue`). "First" is the narrative flag `traced.<object_id>`, so it survives saves.
## `use` is refused (&"unsupported") unless `allow_use`, which makes `use` reveal it as well.

signal memory_revealed(object_id: StringName)

## [speaker_key, text_key] pairs, e.g. [["SPK_ELIAS", "EL_TRACE_BENCH_01"]].
@export var lines: Array = []
## Narrative flag set on the first trace (optional).
@export var flag_id: StringName = &""
## Journal entry added on the first trace (optional).
@export var journal_key: String = ""
@export_enum("observation", "fact", "theory") var journal_category: String = "observation"
## Only the first trace plays the lines.
@export var one_shot_dialogue: bool = false
## Seconds per line before the non-blocking dialogue advances by itself (0 = confirm only).
@export var auto_advance: float = 3.0
## Let `use` (interact) reveal the memory too.
@export var allow_use: bool = false


func _ready() -> void:
	traceable = true
	super._ready()


func sequence_id() -> StringName:
	return StringName("trace.%s" % object_id)


func traced_flag() -> StringName:
	return StringName("traced.%s" % object_id)


## True once the memory was revealed in this run (saved with the narrative flags).
func is_revealed() -> bool:
	var sess := get_session()
	return sess != null and sess.narrative_state != null and bool(sess.narrative_state.get_flag(traced_flag()))


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"" if allow_use else &"unsupported"


func _on_use(actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	reveal(actor_id)


func _on_traced(actor_id: StringName) -> void:
	reveal(actor_id)


func reveal(_actor_id: StringName = &"player") -> void:
	var sess := get_session()
	var narrative: NarrativeState = sess.narrative_state if sess != null else null
	var first := narrative == null or not bool(narrative.get_flag(traced_flag()))
	if narrative != null and first:
		narrative.set_flag(traced_flag())
		if not String(flag_id).is_empty():
			narrative.set_flag(flag_id)
		if not journal_key.is_empty():
			narrative.add_journal_entry(journal_key, journal_category)
	if not lines.is_empty() and (first or not one_shot_dialogue):
		var dialogue := _dialogue_box()
		if dialogue != null:
			# Not one_shot at the DialogueBox level: replays are this node's decision.
			dialogue.play_sequence(sequence_id(), lines, false, auto_advance, false)
	memory_revealed.emit(object_id)


func _dialogue_box() -> DialogueBox:
	if not is_inside_tree():
		return null
	return get_tree().root.find_child("DialogueBox", true, false) as DialogueBox
