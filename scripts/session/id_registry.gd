class_name IdRegistry
extends Node

## Centralized registry for stable object IDs per ADR-005.
## Validates ID schema against ^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$
## and enforces uniqueness within the session.

const ID_PATTERN: String = "^(ch\\d\\d|global)\\.[a-z0-9_]+(\\.[a-z0-9_]+)*$"

var _regex: RegEx
var _nodes_by_id: Dictionary = {}  # Dictionary[StringName, Node]


func _init() -> void:
	_regex = RegEx.new()
	_regex.compile(ID_PATTERN)


## Validate an ID string against ADR-005.
func is_valid_id(id: StringName) -> bool:
	var s: String = String(id)
	if s.is_empty():
		return false
	var match_result = _regex.search(s)
	return match_result != null and match_result.get_string() == s


## Register a node with a stable ID.
## Returns true on success, or false (with push_error) if empty, malformed, or duplicate.
func register(id: StringName, node: Node) -> bool:
	if String(id).is_empty():
		push_error("IdRegistry: Cannot register node with empty ID.")
		return false

	if not is_valid_id(id):
		push_error("IdRegistry: ID '%s' does not match ADR-005 pattern '%s'." % [id, ID_PATTERN])
		return false

	if _nodes_by_id.has(id):
		push_error("IdRegistry: Duplicate ID '%s' already registered to %s." % [id, str(_nodes_by_id[id])])
		return false

	if node == null:
		push_error("IdRegistry: Cannot register null node for ID '%s'." % id)
		return false

	_nodes_by_id[id] = node
	return true


## Unregister an ID when a node leaves the scene tree.
func unregister(id: StringName) -> bool:
	if _nodes_by_id.has(id):
		_nodes_by_id.erase(id)
		return true
	return false


## Resolve an ID to its active Node. Returns null if not found.
func resolve(id: StringName) -> Node:
	return _nodes_by_id.get(id, null)


## Check if an ID is currently registered.
func has_id(id: StringName) -> bool:
	return _nodes_by_id.has(id)


## Clear all registered IDs.
func clear() -> void:
	_nodes_by_id.clear()
