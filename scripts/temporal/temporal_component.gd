class_name TemporalComponent
extends Node

## Opt-in temporal behaviour for its parent object per ADR-007 (+ amendments 1 and 2).
##
## The parent must implement:
##   capture_state() -> Dictionary      # exactly the keys listed in state_fields
##   apply_state(state: Dictionary)     # restore those keys
## and may implement:
##   advance(ticks: int)                # for FAST_FORWARD
##
## History is a list of full snapshots plus a cursor pointing at the snapshot the
## parent currently embodies. The parent calls commit_history() on discrete
## transitions only; per-tick counters are captured inside snapshots but never
## commit on their own. is_frozen is owned here and is never part of a snapshot.

signal rewound(cursor: int)
signal freeze_changed(is_frozen: bool)
signal history_committed(cursor: int)

const CAP_REWIND: int = 1
const CAP_FREEZE: int = 2
const CAP_FAST_FORWARD: int = 4

const ABILITY_REWIND: StringName = &"rewind"
const ABILITY_FREEZE: StringName = &"freeze"
const ABILITY_FAST_FORWARD: StringName = &"fast_forward"

@export_flags("Rewind", "Freeze", "Fast Forward") var capabilities: int = 0
@export var schema_version: int = 1
@export var state_fields: PackedStringArray = PackedStringArray()
## Pre-arrival states, oldest first. Each entry must contain exactly state_fields.
@export var initial_history: Array[Dictionary] = []
@export var history_capacity: int = 32
@export var fast_forward_ticks: int = 120

var is_frozen: bool = false

var _history: Array[Dictionary] = []
var _cursor: int = -1
var _initial_state: Dictionary = {}
var _initialized: bool = false


func _ready() -> void:
	if "is_frozen" in state_fields:
		push_error("TemporalComponent on '%s': 'is_frozen' must not be in state_fields (ADR-007 am.2)." % _parent_name())
	# The parent finishes its own _ready after its children, so seed history once it is ready.
	var parent := get_parent()
	if parent != null and not parent.is_node_ready():
		parent.ready.connect(initialize_history, CONNECT_ONE_SHOT)
	else:
		initialize_history()


## Seeds history from initial_history followed by the parent's current state.
func initialize_history() -> void:
	_history.clear()
	for entry in initial_history:
		if _is_valid_snapshot(entry, "initial_history"):
			_history.append(entry.duplicate(true))
	_initial_state = _capture()
	_history.append(_initial_state.duplicate(true))
	_trim_to_capacity()
	_cursor = _history.size() - 1
	_initialized = true


func has_capability(cap: int) -> bool:
	return (capabilities & cap) != 0


func supports_ability(ability_id: StringName) -> bool:
	match ability_id:
		ABILITY_REWIND:
			return has_capability(CAP_REWIND)
		ABILITY_FREEZE:
			return has_capability(CAP_FREEZE)
		ABILITY_FAST_FORWARD:
			return has_capability(CAP_FAST_FORWARD)
	return false


## Records the parent's current state as a new discrete history entry.
## Entries after the cursor (a rewound-away future) are dropped first.
func commit_history() -> bool:
	_ensure_initialized()
	var snapshot := _capture()
	if not _is_valid_snapshot(snapshot, "capture_state()"):
		return false
	if _cursor < _history.size() - 1:
		_history.resize(_cursor + 1)
	_history.append(snapshot)
	_trim_to_capacity()
	_cursor = _history.size() - 1
	history_committed.emit(_cursor)
	return true


## Steps one entry back. Returns &"" on success or a failure reason.
func rewind() -> StringName:
	_ensure_initialized()
	if not has_capability(CAP_REWIND):
		return &"unsupported"
	if is_frozen:
		return &"frozen"
	if _cursor <= 0:
		return &"no_history"
	_cursor -= 1
	_apply(_history[_cursor])
	rewound.emit(_cursor)
	return &""


## Freeze is a toggle (ADR-007 am.2).
func toggle_freeze() -> StringName:
	if not has_capability(CAP_FREEZE):
		return &"unsupported"
	set_frozen(not is_frozen)
	return &""


func set_frozen(value: bool) -> void:
	if is_frozen == value:
		return
	is_frozen = value
	freeze_changed.emit(is_frozen)


func fast_forward() -> StringName:
	if not has_capability(CAP_FAST_FORWARD):
		return &"unsupported"
	if is_frozen:
		return &"frozen"
	var parent := get_parent()
	if parent == null or not parent.has_method("advance"):
		return &"unsupported"
	parent.call("advance", fast_forward_ticks)
	return &""


func can_rewind() -> bool:
	_ensure_initialized()
	return has_capability(CAP_REWIND) and not is_frozen and _cursor > 0


## Restores the tick-0 state, rebuilds history from initial_history and unfreezes.
func reset_to_initial() -> void:
	_ensure_initialized()
	set_frozen(false)
	_apply(_initial_state)
	_history.clear()
	for entry in initial_history:
		if _is_valid_snapshot(entry, "initial_history"):
			_history.append(entry.duplicate(true))
	_history.append(_initial_state.duplicate(true))
	_trim_to_capacity()
	_cursor = _history.size() - 1


func get_history_cursor() -> int:
	return _cursor


func get_history_size() -> int:
	return _history.size()


func get_history_entry(index: int) -> Dictionary:
	if index < 0 or index >= _history.size():
		return {}
	return _history[index].duplicate(true)


## Plain-data form for SaveService (ADR-010): no Node references.
func export_history() -> Dictionary:
	_ensure_initialized()
	return {
		"schema_version": schema_version,
		"cursor": _cursor,
		"entries": _history.duplicate(true),
		"is_frozen": is_frozen,
	}


## Restores history saved by export_history(); applies the snapshot at the cursor.
func import_history(data: Dictionary) -> bool:
	var entries = data.get("entries", [])
	if not (entries is Array) or entries.is_empty():
		push_error("TemporalComponent on '%s': import_history() got no entries." % _parent_name())
		return false
	var restored: Array[Dictionary] = []
	for entry in entries:
		if not (entry is Dictionary) or not _is_valid_snapshot(entry, "import_history"):
			return false
		restored.append(entry.duplicate(true))
	_history = restored
	_cursor = clampi(int(data.get("cursor", _history.size() - 1)), 0, _history.size() - 1)
	_initialized = true
	_apply(_history[_cursor])
	set_frozen(bool(data.get("is_frozen", false)))
	return true


func _ensure_initialized() -> void:
	if not _initialized:
		initialize_history()


func _capture() -> Dictionary:
	var parent := get_parent()
	if parent == null or not parent.has_method("capture_state"):
		if not state_fields.is_empty():
			push_error("TemporalComponent on '%s': parent lacks capture_state()." % _parent_name())
		return {}
	var state = parent.call("capture_state")
	return state.duplicate(true) if state is Dictionary else {}


func _apply(snapshot: Dictionary) -> void:
	var parent := get_parent()
	if parent != null and parent.has_method("apply_state"):
		parent.call("apply_state", snapshot.duplicate(true))


func _is_valid_snapshot(snapshot: Dictionary, source: String) -> bool:
	var ok := snapshot.size() == state_fields.size()
	if ok:
		for field in state_fields:
			if not snapshot.has(field):
				ok = false
				break
	if not ok:
		push_error("TemporalComponent on '%s': %s keys %s do not match state_fields %s." % [_parent_name(), source, snapshot.keys(), state_fields])
	return ok


func _trim_to_capacity() -> void:
	var capacity := maxi(history_capacity, 1)
	while _history.size() > capacity:
		_history.pop_front()
		_cursor = maxi(_cursor - 1, 0)


func _parent_name() -> String:
	var parent := get_parent()
	return String(parent.name) if parent != null else "<no parent>"
