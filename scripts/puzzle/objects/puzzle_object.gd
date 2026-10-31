class_name PuzzleObject
extends Interactable

## Base for objects that belong to a puzzle (ADR-016).
## - Registers as a PuzzleService member, so reset anchors reach it.
## - Latches once its puzzle is SOLVED (now, on the solve signal, or when loaded from a save),
##   so nothing re-blocks a solved passage.
## - Optional "Blocker" child (StaticBody2D) gets its collision toggled by set_passage_blocked().
## Subclasses override _apply_solved_state() and _reset_unsolved().

signal passage_changed(blocked: bool)

@export var puzzle_id: StringName = &""
## Where the player is sent if a reset or closing mechanism would trap them (ADR-016).
@export var safe_anchor_id: StringName = &""

var latched_solved: bool = false


func _ready() -> void:
	super._ready()
	var puzzles := _puzzles()
	if puzzles == null or String(puzzle_id).is_empty():
		return
	puzzles.register_member(puzzle_id, self)
	puzzles.puzzle_solved.connect(_on_puzzle_solved)
	var clock := _clock()
	if clock != null:
		clock.tick_advanced.connect(_on_tick)
	if puzzles.is_solved(puzzle_id):
		_latch()


func _exit_tree() -> void:
	var puzzles := _puzzles()
	if puzzles != null and not String(puzzle_id).is_empty():
		puzzles.unregister_member(puzzle_id, self)
	super._exit_tree()


## PuzzleService reset anchor callback.
func reset_for_puzzle(_puzzle_id: StringName, is_solved: bool) -> void:
	if is_solved:
		_latch()
	else:
		_reset_unsolved()


# --- for subclasses ---------------------------------------------------------------

## Called once per SimClock tick (only while the puzzle isn't latched).
func _puzzle_tick(_tick: int) -> void:
	pass


## Final, permanent state after SOLVED (e.g. passage open).
func _apply_solved_state() -> void:
	pass


## Back to the tick-0 state. Default: the TemporalComponent's reset_to_initial().
func _reset_unsolved() -> void:
	var temporal := get_temporal()
	if temporal != null:
		temporal.reset_to_initial()


func set_passage_blocked(blocked: bool) -> void:
	var blocker := get_node_or_null("Blocker") as CollisionObject2D
	if blocker != null:
		for child in blocker.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", not blocked)
	passage_changed.emit(blocked)


func is_frozen() -> bool:
	var temporal := get_temporal()
	return temporal != null and temporal.is_frozen


## Base ticks scaled by the accessibility assist (Settings.get_timing_window, TLF-017).
func timing_window(base_ticks: int) -> int:
	var settings := get_node_or_null("/root/Settings")
	return settings.get_timing_window(base_ticks) if settings != null else base_ticks


func resolve(object_id: StringName) -> Node:
	var sess := get_session()
	if sess == null or sess.id_registry == null or String(object_id).is_empty():
		return null
	return sess.id_registry.resolve(object_id)


## True when the player is inside the TriggerZone `zone_id`.
func player_in_zone(zone_id: StringName) -> bool:
	var zone := resolve(zone_id) as TriggerZone
	return zone != null and &"player" in zone.occupants


func relocate_player_to_safety() -> void:
	var sess := get_session()
	if sess != null and sess.spatial_service != null and not String(safe_anchor_id).is_empty():
		sess.spatial_service.request_relocation(&"player", safe_anchor_id)


# --- internals ----------------------------------------------------------------------

func _latch() -> void:
	if latched_solved:
		return
	latched_solved = true
	_apply_solved_state()


func _on_puzzle_solved(solved_id: StringName, _tick: int) -> void:
	if solved_id == puzzle_id:
		_latch()


func _on_tick(tick: int) -> void:
	if not latched_solved:
		_puzzle_tick(tick)


func _puzzles() -> PuzzleService:
	var sess := get_session()
	return sess.puzzle_service if sess != null else null


func _clock() -> SimClock:
	var sess := get_session()
	return sess.sim_clock if sess != null else null
