class_name TraceBench
extends DialogueTrigger

## TraceBench (TLF-076 / ADR-025 V6)
## The waiting lounge bench:
## - First Trace: behaves identically to DialogueTrigger (plays EL_B06_01 dialogue,
##   records journal entry JRN_CH1_TWO_SILHOUETTES, sets heard.ch01_b06_bench).
## - Second Trace (after journal entry exists or sequence was heard): transitions
##   to the side-view pilot scene `ch01.side_mira_memory` at its start anchor.

const MEMORY_ROOM := &"ch01.side_mira_memory"
const MEMORY_ANCHOR := &"ch01.side_mira_memory.anchor"
const BENCH_ANCHOR := &"ch01.waiting_lounge.safe_anchor_center"
const SILHOUETTES_JOURNAL := "JRN_CH1_TWO_SILHOUETTES"


func _has_silhouettes_journal() -> bool:
	var sess := get_session()
	if sess == null:
		sess = _find_session_in_tree()
	if sess != null and sess.narrative_state != null:
		for entry in sess.narrative_state.get_journal():
			if entry.get("key") == SILHOUETTES_JOURNAL:
				return true
	return false


func _can_watch(_actor_id: StringName, ability: StringName, _payload: Dictionary) -> StringName:
	if traceable and ability == &"trace":
		return &""
	return &"unsupported"


func _on_watch(_actor_id: StringName, ability: StringName, _payload: Dictionary) -> void:
	if traceable and ability == &"trace":
		traced.emit(0)
		trigger()


func _on_traced(_actor_id: StringName) -> void:
	if traceable:
		trigger()


func trigger() -> bool:
	if _is_already_triggered() or _has_silhouettes_journal():
		var sess := get_session()
		if sess == null:
			sess = _find_session_in_tree()
		if sess != null and sess.room_router != null:
			if sess.narrative_state != null:
				sess.narrative_state.set_flag(&"mira_memory.return_target", BENCH_ANCHOR)
			return sess.room_router.enter_room(MEMORY_ROOM, &"", MEMORY_ANCHOR)
		return false
	return super.trigger()
