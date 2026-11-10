class_name TraceBench
extends DialogueTrigger

## TraceBench (TLF-076 / ADR-025 V6)
## The waiting lounge bench:
## - Use: plays EL_B06_01 dialogue, records journal entry JRN_CH1_TWO_SILHOUETTES,
##   and marks sequence heard (untouched main behavior).
## - Trace before Beat 06 is heard: silent / does nothing (preserves main behavior).
## - Trace after Beat 06 is heard: enters side-view memory scene ch01.side_mira_memory.

const MEMORY_ROOM := &"ch01.side_mira_memory"
const MEMORY_ANCHOR := &"ch01.side_mira_memory.anchor"
const BENCH_ANCHOR := "ch01.waiting_lounge.safe_anchor_center"
const RETURN_FLAG := &"ch01.flag.mira_memory_return"
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


func _can_use_ability(_actor_id: StringName, ability_id: StringName, _payload: Dictionary) -> StringName:
	if traceable and ability_id == ABILITY_TRACE:
		return &""
	return &"unsupported"


func _on_traced(_actor_id: StringName) -> void:
	if not traceable:
		return
	if _is_already_triggered() or _has_silhouettes_journal():
		_enter_memory()


func _enter_memory() -> void:
	var sess := get_session()
	if sess == null:
		sess = _find_session_in_tree()
	if sess == null or sess.room_router == null:
		return

	# Finish/close lounge dialogue if active so it does not carry over
	var diag := _find_dialogue_box()
	if diag != null and diag.is_active:
		diag.finish_sequence()

	if sess.narrative_state != null:
		sess.narrative_state.set_flag(RETURN_FLAG, BENCH_ANCHOR)

	sess.room_router.enter_room.call_deferred(MEMORY_ROOM, &"", MEMORY_ANCHOR)
