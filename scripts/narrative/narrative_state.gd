class_name NarrativeState
extends Node

## Session narrative flags and collected memory fragments (ADR-011 session service).
## Minimal for TLF-019: enough for save/load; dialogue and journal build on it later.

signal flag_changed(flag_id: StringName, value: Variant)
signal fragment_collected(fragment_id: StringName)

var _flags: Dictionary = {}
var _fragments: Array[StringName] = []


func set_flag(flag_id: StringName, value: Variant = true) -> void:
	if _flags.get(flag_id) == value:
		return
	_flags[flag_id] = value
	flag_changed.emit(flag_id, value)


func get_flag(flag_id: StringName, default: Variant = false) -> Variant:
	return _flags.get(flag_id, default)


## Returns false if already collected.
func collect_fragment(fragment_id: StringName) -> bool:
	if fragment_id in _fragments:
		return false
	_fragments.append(fragment_id)
	fragment_collected.emit(fragment_id)
	return true


func has_fragment(fragment_id: StringName) -> bool:
	return fragment_id in _fragments


func export_flags() -> Dictionary:
	var out := {}
	for key in _flags.keys():
		out[String(key)] = _flags[key]
	return out


func export_fragments() -> Array:
	var out: Array = []
	for id in _fragments:
		out.append(String(id))
	return out


func import_state(flags: Dictionary, fragments: Array) -> void:
	_flags.clear()
	for key in flags.keys():
		_flags[StringName(str(key))] = flags[key]
	_fragments.clear()
	for id in fragments:
		var fragment := StringName(str(id))
		if not fragment in _fragments:
			_fragments.append(fragment)
