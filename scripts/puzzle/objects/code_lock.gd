class_name CodeLock
extends PuzzleObject

## CH1-SO-01 release lock (logic node, no sprite). Compares the selectors' positions with `answer`
## when its ReleaseLever is pulled. A match unlocks it for good: grid_online goes true (the
## PoweredDoor API, like SubstationGrid) and the puzzle is marked SOLVED directly, because the next
## trigger is the doorway itself. A mismatch is &"wrong_code" (the same for every wrong code, never
## per-selector feedback, ADR-020 am. Q-8) and starts a silent lock-out of `lockout_base_ticks`
## (360 = 6 s, scaled by the timing assist) during which the lever answers &"locked_out".
## The lock-out is not saved: a load clears it.

signal grid_online_changed(online: bool)

@export var selector_ids: Array[StringName] = []
@export var answer: PackedInt32Array = PackedInt32Array()
@export var lockout_base_ticks: int = 360
## Journal entry added on the unlock (spec success feedback).
@export var solved_journal_key: String = ""
@export_enum("observation", "fact", "theory") var solved_journal_category: String = "fact"

var unlocked: bool = false
var grid_online: bool = false
var lockout_until_tick: int = 0


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"  # a logic node; the lever is the input


## The lever's rule, side-effect free (the player also calls it for prompts).
func check_code() -> StringName:
	if unlocked or latched_solved:
		return &"already_open"
	if current_tick() < lockout_until_tick:
		return &"locked_out"
	return &"" if code_matches() else &"wrong_code"


func code_matches() -> bool:
	if selector_ids.size() != answer.size() or answer.is_empty():
		return false
	for i in selector_ids.size():
		var selector := resolve(selector_ids[i]) as SelectorSwitch
		if selector == null or selector.selector_position != answer[i]:
			return false
	return true


## Called by the lever after a request failed with &"wrong_code".
func start_lockout() -> void:
	lockout_until_tick = current_tick() + timing_window(lockout_base_ticks)


## Called by the lever once check_code() allowed the pull.
func accept() -> void:
	_unlock()
	var puzzles := _puzzles()
	if puzzles != null and not String(puzzle_id).is_empty():
		puzzles.mark_solved(puzzle_id)
	var sess := get_session()
	if sess != null and sess.narrative_state != null and not solved_journal_key.is_empty():
		sess.narrative_state.add_journal_entry(solved_journal_key, solved_journal_category)


func current_tick() -> int:
	var clock := _clock()
	return clock.tick if clock != null else 0


func _unlock() -> void:
	if unlocked:
		return
	unlocked = true
	grid_online = true
	grid_online_changed.emit(true)


func _apply_solved_state() -> void:
	_unlock()


func _reset_unsolved() -> void:
	pass  # the lock-out clears itself; selectors keep their positions
