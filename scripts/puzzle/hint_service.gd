class_name HintService
extends Node

## Optional, escalating hints per puzzle (FR-010, GDD §11, PRD §11 "subtle nudge -> explicit next action").
##
## Each request for an unsolved puzzle shows the next ladder level (1 = nudge, 2 = rule reminder,
## 3 = next action). Escalation needs `escalation_cooldown_ticks` since the last shown level; an
## earlier request re-shows the current level, so mashing the button can't skip straight to the
## answer. Level 3 is the ceiling. Hints for solved puzzles are refused. Levels used are saved.

signal hint_shown(puzzle_id: StringName, level: int, text_key: String)

@export var sim_clock: SimClock
@export var puzzle_service: PuzzleService
@export var escalation_cooldown_ticks: int = 300

var _defs: Dictionary = {}         # puzzle_id -> PuzzleDef
var _levels: Dictionary = {}       # puzzle_id -> int (0 = none shown yet)
var _last_shown_tick: Dictionary = {}


func _ready() -> void:
	if sim_clock == null:
		sim_clock = get_node_or_null("../SimClock") as SimClock
	if puzzle_service == null:
		puzzle_service = get_node_or_null("../PuzzleService") as PuzzleService


func register_def(def: PuzzleDef) -> bool:
	if def == null or not def.is_valid():
		push_error("HintService: invalid PuzzleDef '%s'." % (def.puzzle_id if def != null else &"<null>"))
		return false
	_defs[def.puzzle_id] = def
	if puzzle_service != null:
		puzzle_service.register_puzzle(def.puzzle_id)
	return true


## Loads every PuzzleDef (.tres) in a folder, e.g. res://data/puzzles/ch01. Returns how many loaded.
func load_defs_from(dir_path: String) -> int:
	var count := 0
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return 0
	for file in dir.get_files():
		var path := dir_path.path_join(file.trim_suffix(".remap"))
		if not path.ends_with(".tres"):
			continue
		var def := load(path) as PuzzleDef
		if register_def(def):
			count += 1
	return count


func get_level(puzzle_id: StringName) -> int:
	return _levels.get(puzzle_id, 0)


## Returns {ok, reason, level, text_key}. reason: unknown_puzzle | already_solved | "".
func request_hint(puzzle_id: StringName) -> Dictionary:
	var def: PuzzleDef = _defs.get(puzzle_id)
	if def == null:
		return {"ok": false, "reason": &"unknown_puzzle", "level": 0, "text_key": ""}
	if puzzle_service != null and puzzle_service.is_solved(puzzle_id):
		return {"ok": false, "reason": &"already_solved", "level": get_level(puzzle_id), "text_key": ""}
	var level := get_level(puzzle_id)
	var now := sim_clock.tick if sim_clock != null else 0
	var can_escalate := level == 0 or now - int(_last_shown_tick.get(puzzle_id, now)) >= escalation_cooldown_ticks
	if level < 3 and can_escalate:
		level += 1
		_levels[puzzle_id] = level
		_last_shown_tick[puzzle_id] = now
	var key := def.hint_keys[level - 1]
	hint_shown.emit(puzzle_id, level, key)
	return {"ok": true, "reason": &"", "level": level, "text_key": key}


## The hint button in a room: the first unsolved puzzle of that room, in play order
## (PuzzleDef.order, then puzzle id), so CH1-SO-02 comes before CH1-PZ-002 in the same room.
func request_hint_for_room(room_id: StringName) -> Dictionary:
	var ids: Array = []
	for id in _defs.keys():
		if _defs[id].room_id == room_id and not (puzzle_service != null and puzzle_service.is_solved(id)):
			ids.append(id)
	if ids.is_empty():
		return {"ok": false, "reason": &"no_active_puzzle", "level": 0, "text_key": ""}
	ids.sort_custom(func(a, b):
		if _defs[a].order != _defs[b].order:
			return _defs[a].order < _defs[b].order
		return String(a) < String(b))
	return request_hint(ids[0])


func export_state() -> Dictionary:
	var out := {}
	for id in _levels.keys():
		out[String(id)] = _levels[id]
	return out


func import_state(data: Dictionary) -> void:
	for key in data.keys():
		_levels[StringName(str(key))] = clampi(int(data[key]), 0, 3)
