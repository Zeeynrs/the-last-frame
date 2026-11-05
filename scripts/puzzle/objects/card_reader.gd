class_name CardReader
extends PuzzleObject

## CH1-PZ-003 R1 staff-pass reader (TLF-054). `use` without the pass flag is &"no_pass"; with it the
## reader goes online for good (the grid API a PoweredDoor listens to). Re-deriving it is cheap: a
## reloaded room before SOLVED needs one more `use` (the pass flag is saved); after SOLVED the
## barrier is latched by its own puzzle_id.

signal grid_online_changed(online: bool)

@export var pass_flag: StringName = &"ch01.flag.transit_pass"

var grid_online: bool = false


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	if grid_online or latched_solved:
		return &"already_open"
	var sess := get_session()
	var has_pass := sess != null and sess.narrative_state != null and bool(sess.narrative_state.get_flag(pass_flag))
	return &"" if has_pass else &"no_pass"


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	_go_online()


func _default_feedback_keys() -> Dictionary:
	return {&"no_pass": "PZ003_FB_NO_PASS"}


func _go_online() -> void:
	if grid_online:
		return
	grid_online = true
	grid_online_changed.emit(true)


func _apply_solved_state() -> void:
	_go_online()


func _reset_unsolved() -> void:
	pass  # a swiped pass stays valid
