class_name PlaytestLog
extends Node

## Local playtest telemetry (TLF-048, ADR-020): the yardstick for "is Chapter 1 long enough".
##
## A session service: GameSession creates it for chapter scenes (it needs the RoomRouter) when the
## ProjectSettings flag `tlf/playtest_log` is on (default: on in debug builds, off in exports).
## Nothing in gameplay depends on it; it only listens to session signals.
##
## Time is counted on SimClock ticks (tick_advanced), so it matches the simulation exactly, and as
## wall time for comparison. Pauses are counted separately and never added to room or puzzle time:
##   - document / journal / other: SimClock.is_paused (no ticks run; counted as physics frames)
##   - game: the SceneTree is paused (counted as physics frames; this node always processes)
##   - dialogue: a blocking dialogue is up (ticks run, but the player can't act)
##   - unfocused: the game window lost focus (ticks run, nobody is playing)
## Per puzzle (PuzzleDef.room_id from HintService): first entry into its room -> SOLVED, plus resets,
## echo_reset presses, hints per level and failed player interactions by reason (failures and
## echo resets go to the current room's first unsolved puzzle, the same rule as the hint button).
##
## State is saved with the game (SaveStore "playtest", save v2) so Continue keeps measuring.
## On chapter_complete it writes user://playtest/<chapter>_<timestamp>.json (headless runs:
## user://headless/playtest, the TLF-036 rule). It never touches saves/ or settings.cfg.

signal log_written(path: String)

const SETTING := "tlf/playtest_log"
const DEFAULT_DIR := "user://playtest"
const HEADLESS_DIR := "user://headless/playtest"
const DATA_VERSION := 1
## Room visits kept in the log (and the save); later visits are still summed per room.
const MAX_VISITS := 400
const PAUSE_KINDS: Array[String] = ["document", "journal", "dialogue", "game", "unfocused", "other"]
const NOT_STARTED := "not_started"
const ACTIVE := "active"
const SOLVED := "solved"
## Solved before this log started measuring it (an old save without a log): no time is claimed.
const UNTRACKED := "untracked"
const PLAYER_ACTOR: StringName = &"player"

@export var session: GameSession
@export var chapter: String = "ch01"
## Where the chapter JSON goes. Resolved in _init(); tests may point it elsewhere.
var output_dir: String = DEFAULT_DIR

var run_id: String = ""
var started_at: String = ""
## 1 for a New Game; +1 for every Continue that restored this log.
var sessions: int = 1
## False once a save without a log was loaded (some puzzles were never measured).
var complete_run: bool = true
var active_ticks: int = 0
var wall_ms: int = 0
var paused: Dictionary = {}          # kind -> ticks/frames
var rooms: Dictionary = {}           # room_id -> {visits, ticks, active_ticks, paused_ticks, wall_ms}
var visits: Array = []               # finished visits, oldest first (capped at MAX_VISITS)
var visits_dropped: int = 0
var current_visit: Dictionary = {}   # the visit in progress, or {}
var puzzles: Dictionary = {}         # puzzle_id -> see _new_puzzle()
var failures: Dictionary = {}        # reason -> count (player only)
var echo_resets: int = 0
var resets: int = 0
var hints: Dictionary = {"1": 0, "2": 0, "3": 0}
var completed: bool = false
var complete_active_ticks: int = -1
var complete_wall_ms: int = -1
var written_path: String = ""

var _last_usec: int = -1
var _unfocused: bool = false
var _watch: Node = null
var _dialogue: Node = null
var _document_viewer: Node = null
var _journal: Node = null
var _ui_lookup_cooldown: int = 0


## On when ProjectSettings `tlf/playtest_log` (with feature overrides, e.g. `.debug`) is true.
static func is_enabled() -> bool:
	return ProjectSettings.has_setting(SETTING) and bool(ProjectSettings.get_setting_with_override(SETTING))


## Output folder for a display server name and the TLF_ALLOW_REAL_USER_DATA value (TLF-036 rule).
static func resolve_output_dir(display_name: String, env_override: String) -> String:
	if display_name == "headless" and env_override != "1":
		return HEADLESS_DIR
	return DEFAULT_DIR


func _init() -> void:
	output_dir = resolve_output_dir(DisplayServer.get_name(), OS.get_environment(SaveStore.ALLOW_REAL_USER_DATA_ENV))
	process_mode = Node.PROCESS_MODE_ALWAYS
	for kind in PAUSE_KINDS:
		paused[kind] = 0
	var now := Time.get_datetime_dict_from_system()
	run_id = "%04d%02d%02d_%02d%02d%02d" % [now.year, now.month, now.day, now.hour, now.minute, now.second]
	started_at = Time.get_datetime_string_from_system()


func _ready() -> void:
	if session == null:
		session = get_parent() as GameSession
	if session == null:
		return
	if session.sim_clock != null:
		session.sim_clock.tick_advanced.connect(_on_tick)
	if session.room_router != null:
		session.room_router.room_entered.connect(_on_room_entered)
	if session.puzzle_service != null:
		session.puzzle_service.puzzle_solved.connect(_on_puzzle_solved)
		session.puzzle_service.puzzle_reset.connect(_on_puzzle_reset)
	if session.hint_service != null:
		session.hint_service.hint_shown.connect(_on_hint_shown)
	if session.interaction_service != null:
		session.interaction_service.interaction_failed.connect(_on_interaction_failed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_unfocused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_unfocused = false


func _physics_process(_delta: float) -> void:
	if completed or session == null:
		return
	_bind_pocket_watch()
	_count_wall()
	if get_tree().paused:
		_add_paused("game", 1)
	elif session.sim_clock != null and session.sim_clock.is_paused:
		_add_paused(_sim_pause_kind(), 1)
	elif Input.is_action_just_pressed(&"echo_reset") and _player_can_act():
		echo_resets += 1
		var puzzle := _current_puzzle()
		if not puzzle.is_empty():
			puzzle["echo_resets"] += 1


# --- counting ------------------------------------------------------------------------------

func _on_tick(_tick: int) -> void:
	if completed:
		return
	var kind := _running_pause_kind()
	if kind.is_empty():
		_add_active(1)
	else:
		_add_paused(kind, 1)
	# Every SimClock tick lands in exactly one visit (ticks = active + dialogue + unfocused).
	if not current_visit.is_empty():
		current_visit["ticks"] += 1
		rooms[current_visit["room"]]["ticks"] += 1
	for puzzle in _active_puzzles():
		puzzle["ticks"] += 1


func _add_active(n: int) -> void:
	active_ticks += n
	if not current_visit.is_empty():
		current_visit["active_ticks"] += n
		rooms[current_visit["room"]]["active_ticks"] += n
	for puzzle in _active_puzzles():
		puzzle["active_ticks"] += n
		if not current_visit.is_empty() and puzzle["room"] == current_visit["room"]:
			puzzle["in_room_active_ticks"] += n


func _add_paused(kind: String, n: int) -> void:
	paused[kind] = int(paused.get(kind, 0)) + n
	if not current_visit.is_empty():
		current_visit["paused_ticks"] += n
		rooms[current_visit["room"]]["paused_ticks"] += n
	for puzzle in _active_puzzles():
		puzzle["paused_ticks"] += n


func _count_wall() -> void:
	var now := Time.get_ticks_usec()
	if _last_usec >= 0:
		var ms := int((now - _last_usec) / 1000)
		wall_ms += ms
		if not current_visit.is_empty():
			current_visit["wall_ms"] += ms
			rooms[current_visit["room"]]["wall_ms"] += ms
		for puzzle in _active_puzzles():
			puzzle["wall_ms"] += ms
		_last_usec = now - (now - _last_usec) % 1000
	else:
		_last_usec = now


## Pause kinds while ticks still run.
func _running_pause_kind() -> String:
	if _unfocused:
		return "unfocused"
	var dialogue := _find_ui(&"_dialogue", "DialogueBox")
	if dialogue != null and bool(dialogue.get("is_active")) and bool(dialogue.get("is_blocking")):
		return "dialogue"
	return ""


## Why the SimClock is paused (the document viewer and journal pause it).
func _sim_pause_kind() -> String:
	var viewer := _find_ui(&"_document_viewer", "DocumentViewer")
	if viewer != null and bool(viewer.get("is_open")):
		return "document"
	var journal := _find_ui(&"_journal", "JournalScreen")
	if journal != null and bool(journal.get("is_open")):
		return "journal"
	return "other"


func _player_can_act() -> bool:
	var player: Node = session.room_router.player if session.room_router != null else null
	return player != null and player.is_physics_processing() and _running_pause_kind().is_empty()


## Cached lookup of a UI node by name (read-only: the log never changes UI state).
func _find_ui(cache: StringName, node_name: String) -> Node:
	var node: Node = get(cache)
	if node != null and is_instance_valid(node) and node.is_inside_tree():
		return node
	if _ui_lookup_cooldown > 0:
		_ui_lookup_cooldown -= 1
		return null
	node = get_tree().root.find_child(node_name, true, false)
	if node == null:
		_ui_lookup_cooldown = 30
	set(cache, node)
	return node


func _bind_pocket_watch() -> void:
	if _watch != null and is_instance_valid(_watch):
		return
	var player: Node = session.room_router.player if session.room_router != null else null
	var watch: Node = player.get("pocket_watch") if player != null else null
	if watch != null and watch.has_signal(&"watch_used"):
		_watch = watch
		watch.watch_used.connect(_on_watch_used)


# --- events --------------------------------------------------------------------------------

func _on_room_entered(room_id: StringName) -> void:
	if completed:
		return
	_close_visit(false)
	var room := String(room_id)
	if not rooms.has(room):
		rooms[room] = {"visits": 0, "ticks": 0, "active_ticks": 0, "paused_ticks": 0, "wall_ms": 0}
	rooms[room]["visits"] += 1
	current_visit = {"room": room, "visit": rooms[room]["visits"], "start_active_tick": active_ticks,
		"ticks": 0, "active_ticks": 0, "paused_ticks": 0, "wall_ms": 0}
	_sync_puzzles()
	for id in puzzles.keys():
		var puzzle: Dictionary = puzzles[id]
		if puzzle["room"] == room and puzzle["state"] == NOT_STARTED:
			puzzle["state"] = ACTIVE
			puzzle["start_active_tick"] = active_ticks


func _on_puzzle_solved(puzzle_id: StringName, _tick: int) -> void:
	if completed:
		return
	_sync_puzzles()
	var puzzle := _puzzle(String(puzzle_id))
	if puzzle["state"] == NOT_STARTED:
		# Solved without entering its room first (not on the Ch1 path): no time to claim.
		puzzle["start_active_tick"] = active_ticks
	if puzzle["state"] == NOT_STARTED or puzzle["state"] == ACTIVE:
		puzzle["state"] = SOLVED
		puzzle["solved_active_tick"] = active_ticks


func _on_puzzle_reset(puzzle_id: StringName, was_solved: bool) -> void:
	if completed:
		return
	resets += 1
	var puzzle := _puzzle(String(puzzle_id))
	if not was_solved:
		puzzle["resets"] += 1


func _on_hint_shown(puzzle_id: StringName, level: int, _text_key: String) -> void:
	if completed:
		return
	var key := str(clampi(level, 1, 3))
	hints[key] += 1
	_puzzle(String(puzzle_id))["hints"][key] += 1


func _on_interaction_failed(_tick: int, actor_id: StringName, _target_id: StringName, _interaction_id: StringName, reason: StringName) -> void:
	if actor_id == PLAYER_ACTOR:
		_count_failure(reason)


## Watch failures that never reach the InteractionService: Echo record/stop/play and "no target".
func _on_watch_used(ability: StringName, target_id: StringName, result: InteractionResult) -> void:
	if result != null and not result.ok and (ability == &"echo" or String(target_id).is_empty()):
		_count_failure(result.reason)


func _count_failure(reason: StringName) -> void:
	if completed:
		return
	var key := String(reason) if not String(reason).is_empty() else "unknown"
	failures[key] = int(failures.get(key, 0)) + 1
	var puzzle := _current_puzzle()
	if not puzzle.is_empty():
		puzzle["failures"][key] = int(puzzle["failures"].get(key, 0)) + 1


# --- puzzles -------------------------------------------------------------------------------

func _new_puzzle(room: String) -> Dictionary:
	return {"room": room, "state": NOT_STARTED, "start_active_tick": -1, "solved_active_tick": -1,
		"ticks": 0, "active_ticks": 0, "paused_ticks": 0, "in_room_active_ticks": 0, "wall_ms": 0,
		"resets": 0, "echo_resets": 0, "hints": {"1": 0, "2": 0, "3": 0}, "failures": {}}


func _puzzle(id: String) -> Dictionary:
	if not puzzles.has(id):
		puzzles[id] = _new_puzzle("")
	return puzzles[id]


## Adds the puzzles HintService knows (PuzzleDef.room_id). Already-SOLVED puzzles this log never
## saw start (an old save) are UNTRACKED.
func _sync_puzzles() -> void:
	var hint_service := session.hint_service if session != null else null
	if hint_service == null:
		return
	for def in hint_service._defs.values():
		var id := String(def.puzzle_id)
		var puzzle := _puzzle(id)
		if String(puzzle["room"]).is_empty():
			puzzle["room"] = String(def.room_id)
		if puzzle["state"] == NOT_STARTED and session.puzzle_service != null and session.puzzle_service.is_solved(def.puzzle_id):
			puzzle["state"] = UNTRACKED
			complete_run = false


func _active_puzzles() -> Array:
	return puzzles.values().filter(func(p: Dictionary) -> bool: return p["state"] == ACTIVE)


## The current room's first active puzzle (by id), or {}.
func _current_puzzle() -> Dictionary:
	if current_visit.is_empty():
		return {}
	var ids := puzzles.keys().filter(func(id) -> bool:
		return puzzles[id]["state"] == ACTIVE and puzzles[id]["room"] == current_visit["room"])
	if ids.is_empty():
		return {}
	ids.sort()
	return puzzles[ids[0]]


func _close_visit(interrupted: bool) -> void:
	if current_visit.is_empty():
		return
	var visit := current_visit
	if interrupted:
		visit["interrupted"] = true
	current_visit = {}
	if visits.size() >= MAX_VISITS:
		visits_dropped += 1
	else:
		visits.append(visit)


# --- chapter end ---------------------------------------------------------------------------

## Stops measuring and writes the JSON. Returns the written path ("" if it couldn't be written).
func finish_chapter() -> String:
	if completed:
		return written_path
	_count_wall()
	completed = true
	complete_active_ticks = active_ticks
	complete_wall_ms = wall_ms
	_close_visit(false)
	written_path = write_json()
	return written_path


func write_json() -> String:
	var dir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if dir_error != OK and not DirAccess.dir_exists_absolute(output_dir):
		push_warning("PlaytestLog: cannot create %s (%s)." % [output_dir, error_string(dir_error)])
		return ""
	var previous := _count_previous_logs()
	var path := output_dir.path_join("%s_%s.json" % [chapter, run_id])
	var n := 2
	while FileAccess.file_exists(path):
		path = output_dir.path_join("%s_%s_%d.json" % [chapter, run_id, n])
		n += 1
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("PlaytestLog: cannot write %s (%s)." % [path, error_string(FileAccess.get_open_error())])
		return ""
	var data := report()
	# Earlier chapter logs on this machine: a hint that this was not the player's first run.
	data["previous_logs"] = previous
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	log_written.emit(path)
	return path


func _count_previous_logs() -> int:
	var dir := DirAccess.open(output_dir)
	if dir == null:
		return 0
	return Array(dir.get_files()).filter(func(f: String) -> bool:
		return f.begins_with(chapter + "_") and f.ends_with(".json")).size()


## The JSON content: the saved state plus derived seconds/minutes per room and puzzle.
func report() -> Dictionary:
	var data := export_state()
	var tps := float(Engine.physics_ticks_per_second)
	data["ticks_per_second"] = Engine.physics_ticks_per_second
	data["finished_at"] = Time.get_datetime_string_from_system()
	data["engine"] = Engine.get_version_info().get("string", "")
	data["debug_build"] = OS.is_debug_build()
	var summary := {
		"active_seconds": snappedf(active_ticks / tps, 0.01),
		"paused_seconds": snappedf(total_paused() / tps, 0.01),
		"wall_seconds": snappedf(wall_ms / 1000.0, 0.01),
		"complete_active_seconds": snappedf(complete_active_ticks / tps, 0.01) if completed else -1,
		"rooms_seconds": {},
		"puzzles_seconds": {},
	}
	for room in rooms.keys():
		summary["rooms_seconds"][room] = snappedf(rooms[room]["active_ticks"] / tps, 0.01)
	for id in puzzles.keys():
		var puzzle: Dictionary = puzzles[id]
		summary["puzzles_seconds"][id] = snappedf(puzzle["active_ticks"] / tps, 0.01) if puzzle["state"] == SOLVED else -1
	data["summary"] = summary
	return data


func total_paused() -> int:
	var sum := 0
	for kind in paused.keys():
		sum += int(paused[kind])
	return sum


## Compact ASCII lines for the complete screen (translated).
func summary_lines() -> PackedStringArray:
	var tps := float(Engine.physics_ticks_per_second)
	var lines := PackedStringArray()
	lines.append(tr("UI_PLAYTEST_TOTAL") % [format_time(active_ticks / tps), format_time(total_paused() / tps)])
	var ids := puzzles.keys()
	ids.sort()
	var parts := PackedStringArray()
	for id in ids:
		var puzzle: Dictionary = puzzles[id]
		var value: String
		match puzzle["state"]:
			SOLVED:
				value = format_time(puzzle["active_ticks"] / tps)
			UNTRACKED:
				value = tr("UI_PLAYTEST_UNTRACKED")
			_:
				value = tr("UI_PLAYTEST_UNSOLVED")
		parts.append(tr("UI_PLAYTEST_PUZZLE") % [String(id).trim_prefix("CH1-"), value])
	for i in range(0, parts.size(), 3):
		lines.append("   ".join(parts.slice(i, i + 3)))
	if not written_path.is_empty():
		lines.append(tr("UI_PLAYTEST_SAVED") % written_path)
	return lines


## m:ss
static func format_time(seconds: float) -> String:
	var total := maxi(int(round(seconds)), 0)
	return "%d:%02d" % [total / 60, total % 60]


# --- save / load ---------------------------------------------------------------------------

## Plain data for SaveStore (save v2 "playtest"). Only primitives with String keys.
func export_state() -> Dictionary:
	return {
		"version": DATA_VERSION,
		"chapter": chapter,
		"run_id": run_id,
		"started_at": started_at,
		"sessions": sessions,
		"complete_run": complete_run,
		"active_ticks": active_ticks,
		"wall_ms": wall_ms,
		"paused": paused.duplicate(true),
		"rooms": rooms.duplicate(true),
		"visits": visits.duplicate(true),
		"visits_dropped": visits_dropped,
		"current_visit": current_visit.duplicate(true),
		"puzzles": puzzles.duplicate(true),
		"failures": failures.duplicate(true),
		"echo_resets": echo_resets,
		"resets": resets,
		"hints": hints.duplicate(true),
		"completed": completed,
		"complete_active_ticks": complete_active_ticks,
		"complete_wall_ms": complete_wall_ms,
	}


## Restores a saved log (Continue). An empty or unknown-version log (a v1 save) keeps this fresh
## log but marks already-solved puzzles UNTRACKED. The visit that was in progress when the save
## was written is closed as interrupted; the room entered after loading starts a new one.
func import_state(data: Dictionary) -> void:
	if data.is_empty() or int(data.get("version", -1)) != DATA_VERSION:
		complete_run = false
		_sync_puzzles()
		return
	run_id = str(data.get("run_id", run_id))
	started_at = str(data.get("started_at", started_at))
	sessions = int(data.get("sessions", 1)) + 1
	complete_run = bool(data.get("complete_run", true))
	active_ticks = int(data.get("active_ticks", 0))
	wall_ms = int(data.get("wall_ms", 0))
	for kind in PAUSE_KINDS:
		paused[kind] = int(data.get("paused", {}).get(kind, 0))
	rooms = _dict(data.get("rooms"))
	visits = _array(data.get("visits"))
	visits_dropped = int(data.get("visits_dropped", 0))
	puzzles = _dict(data.get("puzzles"))
	failures = _dict(data.get("failures"))
	echo_resets = int(data.get("echo_resets", 0))
	resets = int(data.get("resets", 0))
	var saved_hints := _dict(data.get("hints"))
	for key in hints.keys():
		hints[key] = int(saved_hints.get(key, 0))
	completed = bool(data.get("completed", false))
	complete_active_ticks = int(data.get("complete_active_ticks", -1))
	complete_wall_ms = int(data.get("complete_wall_ms", -1))
	current_visit = _dict(data.get("current_visit"))
	_close_visit(true)
	_sync_puzzles()


static func _dict(value) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


static func _array(value) -> Array:
	return (value as Array).duplicate(true) if value is Array else []
