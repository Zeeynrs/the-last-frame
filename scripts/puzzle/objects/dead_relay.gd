class_name DeadRelay
extends PuzzleObject

## CH1-PZ-005 R1 decoy lever C (TLF-054): an auxiliary relay that was never wired. `use` always
## answers &"dead_relay" and changes nothing; no temporal component, so the watch is unsupported.


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"dead_relay"


func _default_feedback_keys() -> Dictionary:
	return {&"dead_relay": "PZ005_FB_DEAD_RELAY"}


func _reset_unsolved() -> void:
	pass
