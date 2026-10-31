class_name TemporalComponent
extends Node

## Temporal component per ADR-007 (including Amendments 1 and 2).
## Manages discrete snapshot history, rewind, and freeze state.

signal freeze_changed(is_frozen: bool)
signal history_committed(cursor: int, total_snapshots: int)
signal rewound(cursor: int, snapshot: Dictionary)

enum Capability {
	NONE = 0,
	REWIND = 1 << 0,
	FREEZE = 1 << 1,
	FAST_FORWARD = 1 << 2,
}

const CAPACITY: int = 32

@export_flags("Rewind", "Freeze", "FastForward") var capabilities: int = 0
@export var schema_version: int = 1
@export var state_fields: PackedStringArray = []
@export var initial_history: Array[Dictionary] = []:
	set(val):
		initial_history = []
		for entry in val:
			if entry is Dictionary:
				initial_history.append(entry)

var is_frozen: bool = false
var _cursor: int = -1
var _history: Array[Dictionary] = []


func _ready() -> void:
	init_history()


## Initializes history from initial_history and tick-0 parent state.
func init_history() -> void:
	_history.clear()
	var parent = get_parent()
	if parent == null or not parent.has_method("capture_state") or not parent.has_method("apply_state"):
		push_error("TemporalComponent on '%s' requires parent to implement capture_state() and apply_state()." % [parent.name if parent else "null"])
		return

	# 1. Seed with initial_history entries (oldest first)
	for entry in initial_history:
		if validate_snapshot(entry):
			_history.append(entry.duplicate(true))

	# 2. Append tick-0 state from parent
	var current = parent.capture_state()
	if validate_snapshot(current):
		_history.append(current.duplicate(true))

	# Enforce ring capacity limit (32)
	while _history.size() > CAPACITY:
		_history.pop_front()

	_cursor = _history.size() - 1


## Validates that snapshot contains exactly state_fields.
func validate_snapshot(snapshot: Dictionary) -> bool:
	if snapshot == null:
		push_error("TemporalComponent snapshot cannot be null.")
		return false

	if snapshot.size() != state_fields.size():
		push_error("Snapshot field count (%d) does not match state_fields size (%d)." % [snapshot.size(), state_fields.size()])
		return false

	for field in state_fields:
		if not snapshot.has(field):
			push_error("Snapshot missing required state field: '%s'." % field)
			return false

	return true


## Commits a new snapshot to history. Called by parent ONLY on discrete state transitions (ADR-007 Am. 2).
func commit_history() -> bool:
	var parent = get_parent()
	if parent == null or not parent.has_method("capture_state"):
		return false

	var snapshot = parent.capture_state()
	if not validate_snapshot(snapshot):
		return false

	# Drop all entries after cursor
	if _cursor >= 0 and _cursor < _history.size() - 1:
		_history = _history.slice(0, _cursor + 1)

	_history.append(snapshot.duplicate(true))

	# Evict oldest entry if capacity exceeded
	while _history.size() > CAPACITY:
		_history.pop_front()

	_cursor = _history.size() - 1
	history_committed.emit(_cursor, _history.size())
	return true


## Rewinds one snapshot in history.
## Returns &"" on success, or failure reason (&"unsupported", &"frozen", &"no_history").
func rewind() -> StringName:
	if not supports_ability(&"rewind"):
		return &"unsupported"

	if is_frozen:
		return &"frozen"

	if _cursor <= 0:
		return &"no_history"

	_cursor -= 1
	var snapshot = _history[_cursor]
	var parent = get_parent()
	if parent != null and parent.has_method("apply_state"):
		parent.apply_state(snapshot.duplicate(true))

	rewound.emit(_cursor, snapshot)
	return &""


## Toggles freeze state. Returns &"" on success, or &"unsupported".
func toggle_freeze() -> StringName:
	if not supports_ability(&"freeze"):
		return &"unsupported"

	is_frozen = not is_frozen
	freeze_changed.emit(is_frozen)
	return &""


## Checks whether this component declares support for the given ability.
func supports_ability(ability: StringName) -> bool:
	match ability:
		&"rewind":
			return (capabilities & Capability.REWIND) != 0
		&"freeze":
			return (capabilities & Capability.FREEZE) != 0
		&"fast_forward":
			return (capabilities & Capability.FAST_FORWARD) != 0
		_:
			return false


func get_history_cursor() -> int:
	return _cursor


func set_history_cursor(new_cursor: int) -> void:
	if new_cursor >= 0 and new_cursor < _history.size():
		_cursor = new_cursor
		var parent = get_parent()
		if parent != null and parent.has_method("apply_state"):
			parent.apply_state(_history[_cursor].duplicate(true))


func get_history() -> Array[Dictionary]:
	return _history.duplicate(true)
