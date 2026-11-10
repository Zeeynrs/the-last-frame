class_name ConduitProp
extends PuzzleObject

## CH1-PZ-001 R1 fallen conduit (TLF-054; the "DependentRewindable" dependency of the ledger):
## REWIND only. It starts `fallen` across the turnstile arm with one pre-arrival entry, `mounted`,
## so one Rewind lifts it and a second answers &"no_history". While it is fallen it pins the gate
## that names it in `pinned_by`. Latched mounted after SOLVED; reset (unsolved) drops it again.

const POS_FALLEN := Vector2(328, 184)
const POS_MOUNTED := Vector2(144, 160)

var conduit_state: StringName = &"fallen"


func _ready() -> void:
	super._ready()
	_update_position()


func capture_state() -> Dictionary:
	return {"conduit_state": conduit_state}


func apply_state(state: Dictionary) -> void:
	conduit_state = StringName(state["conduit_state"])
	_update_position()


func is_pinning() -> bool:
	return conduit_state == &"fallen"


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"


func _apply_solved_state() -> void:
	conduit_state = &"mounted"
	_update_position()


func _update_position() -> void:
	position = POS_MOUNTED if conduit_state == &"mounted" else POS_FALLEN
