class_name ReleaseLever
extends PuzzleObject

## CH1-SO-01 release lever: `use` submits the selectors to its CodeLock. The lock decides the reason
## (&"wrong_code", &"locked_out", &"already_open"). can_interact() must stay side-effect free (the
## player asks it for prompts), so the lock-out starts when the InteractionService reports this
## lever's &"wrong_code" failure, i.e. only for a real pull. No contract change.

@export var lock_id: StringName = &""


func _ready() -> void:
	super._ready()
	var sess := get_session()
	if sess != null and sess.interaction_service != null:
		sess.interaction_service.interaction_failed.connect(_on_interaction_failed)


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	var lock := _lock()
	return lock.check_code() if lock != null else &"missing_target"


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	_lock().accept()


func _default_feedback_keys() -> Dictionary:
	return {&"wrong_code": "SO001_FB_WRONG_CODE", &"locked_out": "SO001_FB_LOCKED_OUT"}


func _on_interaction_failed(_tick: int, _actor_id: StringName, target_id: StringName, _interaction_id: StringName, reason: StringName) -> void:
	if target_id == object_id and reason == &"wrong_code":
		var lock := _lock()
		if lock != null:
			lock.start_lockout()


func _lock() -> CodeLock:
	return resolve(lock_id) as CodeLock
