class_name PuzzleService
extends Node

## Puzzle progression and reset coordination per ADR-016.
##
## Each puzzle is UNSOLVED or SOLVED. SOLVED is permanent progression: it is saved (ADR-010),
## never rewound, and nothing may re-block a solved passage. Puzzle objects that take part in a
## reset register as members and implement reset_for_puzzle(puzzle_id, is_solved); the member
## decides what "reset" means for it (a solved door stays open, a gear unfreezes, ...).

signal puzzle_solved(puzzle_id: StringName, tick: int)
signal puzzle_reset(puzzle_id: StringName, was_solved: bool)

const UNSOLVED: StringName = &"UNSOLVED"
const SOLVED: StringName = &"SOLVED"

@export var sim_clock: SimClock
@export var echo_service: EchoService

var _states: Dictionary = {}    # StringName puzzle_id -> StringName state
var _members: Dictionary = {}   # StringName puzzle_id -> Array[Node]


func _ready() -> void:
	if sim_clock == null:
		sim_clock = get_node_or_null("../SimClock") as SimClock
	if echo_service == null:
		echo_service = get_node_or_null("../EchoService") as EchoService


func register_puzzle(puzzle_id: StringName) -> void:
	if not _states.has(puzzle_id):
		_states[puzzle_id] = UNSOLVED


func get_state(puzzle_id: StringName) -> StringName:
	return _states.get(puzzle_id, UNSOLVED)


func is_solved(puzzle_id: StringName) -> bool:
	return get_state(puzzle_id) == SOLVED


## Idempotent: returns true only on the UNSOLVED -> SOLVED transition.
func mark_solved(puzzle_id: StringName) -> bool:
	if is_solved(puzzle_id):
		return false
	_states[puzzle_id] = SOLVED
	puzzle_solved.emit(puzzle_id, sim_clock.tick if sim_clock != null else 0)
	return true


func register_member(puzzle_id: StringName, member: Node) -> void:
	register_puzzle(puzzle_id)
	var members: Array = _members.get(puzzle_id, [])
	if not member in members:
		members.append(member)
	_members[puzzle_id] = members


func unregister_member(puzzle_id: StringName, member: Node) -> void:
	if _members.has(puzzle_id):
		_members[puzzle_id].erase(member)


## Reset anchor behaviour (ADR-016): clears the active echo, then lets every member reset itself.
func reset_puzzle(puzzle_id: StringName) -> void:
	var was_solved := is_solved(puzzle_id)
	if echo_service != null:
		echo_service.reset_echo()
	for member in _members.get(puzzle_id, []).duplicate():
		if is_instance_valid(member) and member.has_method("reset_for_puzzle"):
			member.call("reset_for_puzzle", puzzle_id, was_solved)
	puzzle_reset.emit(puzzle_id, was_solved)


## Plain data for SaveService: {puzzle_id(String): "SOLVED"|"UNSOLVED"}.
func export_state() -> Dictionary:
	var out := {}
	for id in _states.keys():
		out[String(id)] = String(_states[id])
	return out


## Unknown/invalid values are ignored; SOLVED is never downgraded by an import.
func import_state(data: Dictionary) -> void:
	for key in data.keys():
		var value := StringName(str(data[key]))
		if value != SOLVED and value != UNSOLVED:
			push_warning("PuzzleService: ignoring invalid state '%s' for '%s'." % [value, key])
			continue
		var id := StringName(str(key))
		if value == SOLVED:
			_states[id] = SOLVED
		else:
			register_puzzle(id)
