class_name EchoService
extends Node

## Temporal Echo record/playback per ADR-008 (+ amendment) and ADR-015 controls.
##
## Logic track: ordered events [rel_tick, kind, target_id, interaction_id, payload] captured from
## InteractionService signals for actor "player" only; pocket-watch abilities are never recorded.
## Presentation track: player position sampled every SAMPLE_INTERVAL ticks, used only for the ghost.
## Playback dispatches as actor "echo.0" through the same InteractionService contract, driven by
## SimClock ticks, so it is identical regardless of render frame rate or step chunking.

signal state_changed(state: int)
signal echo_event_failed(tick: int, target_id: StringName, reason: StringName)
signal recording_auto_stopped(reason: StringName)
signal ghost_moved(position: Vector2)

enum State { IDLE, RECORDING, READY, PLAYING, HOLDING }

const KIND_INTERACT: StringName = &"interact"
const KIND_TRIGGER_ENTER: StringName = &"trigger_enter"
const KIND_TRIGGER_EXIT: StringName = &"trigger_exit"
const PLAYER_ACTOR: StringName = &"player"
const SAMPLE_INTERVAL: int = 6

@export var sim_clock: SimClock
@export var interaction_service: InteractionService
## Ch1 limit (ADR-008). Shown in the HUD.
@export var max_record_ticks: int = 1200
@export var echo_actor_id: StringName = &"echo.0"

var state: int = State.IDLE

var _events: Array[Array] = []
var _samples: PackedVector2Array = PackedVector2Array()
var _record_start_tick: int = 0
var _record_length: int = 0
var _position_source: Node2D = null

var _play_start_tick: int = 0
var _next_event: int = 0
var _echo_occupied: Array[StringName] = []
var _player_occupied: Array[StringName] = []


func _ready() -> void:
	if sim_clock == null:
		sim_clock = get_node_or_null("../SimClock") as SimClock
	if interaction_service == null:
		interaction_service = get_node_or_null("../InteractionService") as InteractionService
	bind(sim_clock, interaction_service)


## Wires the service to a clock and an interaction service (scene setup or tests).
func bind(clock: SimClock, service: InteractionService) -> void:
	if sim_clock != null and sim_clock.tick_advanced.is_connected(_on_tick):
		sim_clock.tick_advanced.disconnect(_on_tick)
	if interaction_service != null:
		for pair in [[interaction_service.interaction_applied, _on_interaction_applied],
				[interaction_service.trigger_entered, _on_trigger_entered],
				[interaction_service.trigger_exited, _on_trigger_exited]]:
			if pair[0].is_connected(pair[1]):
				pair[0].disconnect(pair[1])
	sim_clock = clock
	interaction_service = service
	if sim_clock != null:
		sim_clock.tick_advanced.connect(_on_tick)
	if interaction_service != null:
		interaction_service.interaction_applied.connect(_on_interaction_applied)
		interaction_service.trigger_entered.connect(_on_trigger_entered)
		interaction_service.trigger_exited.connect(_on_trigger_exited)


# --- Controls (ADR-015 state machine) --------------------------------------------

## IDLE -> RECORDING. Triggers the player already occupies are seeded at rel_tick 0.
func start_recording(position_source: Node2D = null) -> StringName:
	if state != State.IDLE:
		return &"echo_busy"
	_events.clear()
	_samples = PackedVector2Array()
	_record_start_tick = _now()
	_record_length = 0
	_position_source = position_source
	for trigger_id in _player_occupied:
		_events.append([0, KIND_TRIGGER_ENTER, trigger_id, &"", {}])
	_sample_position()
	_set_state(State.RECORDING)
	return &""


## RECORDING -> READY.
func stop_recording() -> StringName:
	if state != State.RECORDING:
		return &"not_recording"
	_record_length = _now() - _record_start_tick
	_sample_position()
	_position_source = null
	_set_state(State.READY)
	return &""


## READY -> PLAYING; pressing again while PLAYING/HOLDING restarts playback from the start.
func start_playback() -> StringName:
	if state == State.IDLE or state == State.RECORDING:
		return &"no_recording"
	_release_echo_occupancy()
	_play_start_tick = _now()
	_next_event = 0
	_set_state(State.PLAYING)
	_dispatch_due(0)
	_emit_ghost(0)
	_finish_if_done(0)
	return &""


## Any state -> IDLE. Releases echo trigger occupancy; never touches permanent progress.
func reset_echo() -> void:
	_release_echo_occupancy()
	_events.clear()
	_samples = PackedVector2Array()
	_record_length = 0
	_position_source = null
	_set_state(State.IDLE)


## Rooms are separate scenes: a transition stops any recording (ADR-008 am.).
func notify_room_changed() -> void:
	if state == State.RECORDING:
		stop_recording()
		recording_auto_stopped.emit(&"room_changed")


# --- Queries ----------------------------------------------------------------------

func get_events() -> Array:
	return _events.duplicate(true)


func get_record_length() -> int:
	return _record_length


func get_elapsed_ticks() -> int:
	match state:
		State.RECORDING:
			return _now() - _record_start_tick
		State.PLAYING, State.HOLDING:
			return mini(_now() - _play_start_tick, _record_length)
	return 0


func get_echo_occupied_triggers() -> Array[StringName]:
	return _echo_occupied.duplicate()


## Ghost position at a playback-relative tick (linear interpolation of samples).
func get_ghost_position(rel_tick: int) -> Vector2:
	if _samples.is_empty():
		return Vector2.ZERO
	var t := clampi(rel_tick, 0, _record_length)
	if t >= _record_length:
		return _samples[_samples.size() - 1]  # final sample is taken at stop, off the 6-tick grid
	var index := t / SAMPLE_INTERVAL
	if index >= _samples.size() - 1:
		return _samples[_samples.size() - 1]
	var weight := float(t % SAMPLE_INTERVAL) / float(SAMPLE_INTERVAL)
	return _samples[index].lerp(_samples[index + 1], weight)


# --- Recording ----------------------------------------------------------------------

func _on_interaction_applied(tick: int, actor_id: StringName, target_id: StringName, interaction_id: StringName, payload: Dictionary) -> void:
	if state != State.RECORDING or actor_id != PLAYER_ACTOR:
		return
	if Interactable.is_watch_ability(interaction_id):
		return  # ADR-008 am.: echoes have no pocket watch
	_events.append([tick - _record_start_tick, KIND_INTERACT, target_id, interaction_id, payload.duplicate(true)])


func _on_trigger_entered(tick: int, actor_id: StringName, trigger_id: StringName) -> void:
	if actor_id != PLAYER_ACTOR:
		return
	if not trigger_id in _player_occupied:
		_player_occupied.append(trigger_id)
	if state == State.RECORDING:
		_events.append([tick - _record_start_tick, KIND_TRIGGER_ENTER, trigger_id, &"", {}])


func _on_trigger_exited(tick: int, actor_id: StringName, trigger_id: StringName) -> void:
	if actor_id != PLAYER_ACTOR:
		return
	_player_occupied.erase(trigger_id)
	if state == State.RECORDING:
		_events.append([tick - _record_start_tick, KIND_TRIGGER_EXIT, trigger_id, &"", {}])


# --- Tick-driven recording cap and playback -------------------------------------

func _on_tick(tick: int) -> void:
	match state:
		State.RECORDING:
			var rel := tick - _record_start_tick
			if rel % SAMPLE_INTERVAL == 0:
				_sample_position()
			if rel >= max_record_ticks:
				stop_recording()
				recording_auto_stopped.emit(&"max_length")
		State.PLAYING:
			var rel := tick - _play_start_tick
			_dispatch_due(rel)
			_emit_ghost(rel)
			_finish_if_done(rel)


func _dispatch_due(rel_tick: int) -> void:
	while _next_event < _events.size() and int(_events[_next_event][0]) <= rel_tick:
		_dispatch(_events[_next_event])
		_next_event += 1


func _dispatch(event: Array) -> void:
	var kind: StringName = event[1]
	var target_id: StringName = event[2]
	if interaction_service == null:
		return
	if not interaction_service.has_target(target_id):
		echo_event_failed.emit(_now(), target_id, &"missing_target")
		return
	match kind:
		KIND_INTERACT:
			var result := interaction_service.request(echo_actor_id, target_id, event[3], event[4])
			if not result.ok:
				echo_event_failed.emit(_now(), target_id, result.reason)
		KIND_TRIGGER_ENTER:
			if not target_id in _echo_occupied:
				_echo_occupied.append(target_id)
				interaction_service.trigger_enter(echo_actor_id, target_id)
		KIND_TRIGGER_EXIT:
			if target_id in _echo_occupied:
				_echo_occupied.erase(target_id)
				interaction_service.trigger_exit(echo_actor_id, target_id)


func _finish_if_done(rel_tick: int) -> void:
	if state == State.PLAYING and rel_tick >= _record_length and _next_event >= _events.size():
		_set_state(State.HOLDING)  # ghost keeps its final position and occupancy (ADR-008)


func _release_echo_occupancy() -> void:
	var held := _echo_occupied.duplicate()
	_echo_occupied.clear()
	if interaction_service == null:
		return
	for trigger_id in held:
		interaction_service.trigger_exit(echo_actor_id, trigger_id)


func _emit_ghost(rel_tick: int) -> void:
	if not _samples.is_empty():
		ghost_moved.emit(get_ghost_position(rel_tick))


func _sample_position() -> void:
	if _position_source != null and is_instance_valid(_position_source):
		_samples.append(_position_source.global_position)


func _set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)


func _now() -> int:
	return sim_clock.tick if sim_clock != null else 0
