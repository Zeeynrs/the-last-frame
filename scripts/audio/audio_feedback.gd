class_name AudioFeedback
extends Node

## Central audio feedback controller for Chapter 1 per ADR-022 A5 and TLF-064.
## Manages temporal ability SFX, refusal/lock feedback, 23:59 clock ticking,
## Operator motif (VOICE dialogue), Operator sighting vanish sting (TLF-058),
## and Beat 10 street device click (TLF-059).
## Plays on existing AudioServer buses (SFX, Voice). Zero core-system modifications.

signal sound_played(sound_id: StringName, stream: AudioStream)

const BUS_SFX: StringName = &"SFX"
const BUS_VOICE: StringName = &"Voice"

const SOUND_PATHS := {
	&"trace": "res://assets/audio/sfx/sfx_ability_trace.wav",
	&"rewind": "res://assets/audio/sfx/sfx_ability_rewind.wav",
	&"freeze": "res://assets/audio/sfx/sfx_ability_freeze.wav",
	&"echo_record_start": "res://assets/audio/sfx/sfx_echo_record_start.wav",
	&"echo_record_stop": "res://assets/audio/sfx/sfx_echo_record_stop.wav",
	&"echo_play": "res://assets/audio/sfx/sfx_echo_play.wav",
	&"ability_locked": "res://assets/audio/sfx/sfx_ability_locked.wav",
	&"clock_tick": "res://assets/audio/sfx/sfx_clock_tick.wav",
	&"operator_motif": "res://assets/audio/sfx/sfx_operator_motif.wav",
	&"operator_sighting": "res://assets/audio/sfx/sfx_operator_sighting.wav",
	&"device_click": "res://assets/audio/sfx/sfx_device_click.wav",
}

const CLOCK_TICK_INTERVAL: float = 1.0
const CLOCK_PROXIMITY_RADIUS: float = 180.0

var streams: Dictionary = {}

# Test hooks
var last_played_sound: StringName = &""
var last_played_stream: AudioStream = null
var last_spatial_sound: StringName = &""
var last_spatial_stream: AudioStream = null
var play_history: Array[StringName] = []

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_player_index: int = 0
var _voice_player: AudioStreamPlayer = null
var _spatial_player: AudioStreamPlayer2D = null

var _pocket_watch_ref: PocketWatch = null
var _echo_service_ref: EchoService = null
var _dialogue_box_ref: DialogueBox = null
var _room_router_ref: RoomRouter = null
var _player_node_ref: Node2D = null

var _prev_echo_state: int = -1
var _clock_timer: float = 0.0
var _active_clock_nodes: Array = []


func _ready() -> void:
	_load_streams()
	_setup_audio_players()
	_auto_bind()


func _load_streams() -> void:
	for id in SOUND_PATHS:
		var path: String = SOUND_PATHS[id]
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is AudioStream:
				streams[id] = res


func _setup_audio_players() -> void:
	_sfx_players.clear()
	for i in range(4):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

	_voice_player = AudioStreamPlayer.new()
	_voice_player.name = "VoicePlayer"
	_voice_player.bus = BUS_VOICE
	add_child(_voice_player)

	_spatial_player = AudioStreamPlayer2D.new()
	_spatial_player.name = "SpatialPlayer"
	_spatial_player.bus = BUS_SFX
	_spatial_player.max_distance = CLOCK_PROXIMITY_RADIUS
	_spatial_player.attenuation = 1.0
	add_child(_spatial_player)


func _auto_bind() -> void:
	var root := get_parent()
	if root == null:
		return

	# Bind Player & PocketWatch
	var player_node = root.find_child("Player", true, false)
	if player_node != null and player_node is Node2D:
		_player_node_ref = player_node as Node2D
		if "pocket_watch" in player_node and player_node.pocket_watch != null:
			bind_pocket_watch(player_node.pocket_watch)

	# Bind GameSession & EchoService
	var sess = root.find_child("GameSession", true, false) as GameSession
	if sess != null and sess.echo_service != null:
		bind_echo_service(sess.echo_service)

	# Bind RoomRouter
	var router = root.find_child("RoomRouter", true, false) as RoomRouter
	if router != null:
		bind_room_router(router)

	# Bind DialogueBox if present
	var diag = _find_dialogue_box()
	if diag != null:
		bind_dialogue_box(diag)

	# Listen to new tree children for dynamic UI / cinematics
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		if not get_tree().node_added.is_connected(_on_node_added):
			get_tree().node_added.connect(_on_node_added)


func _find_dialogue_box() -> DialogueBox:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		return get_tree().root.find_child("DialogueBox", true, false) as DialogueBox
	return null


func _on_node_added(node: Node) -> void:
	if node is DialogueBox and _dialogue_box_ref == null:
		bind_dialogue_box(node as DialogueBox)
	elif node is Ch01Outro:
		bind_outro(node as Ch01Outro)


func _exit_tree() -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		if get_tree().node_added.is_connected(_on_node_added):
			get_tree().node_added.disconnect(_on_node_added)

	for p in _sfx_players:
		if p != null and is_instance_valid(p):
			p.stop()
			p.stream = null
	if _voice_player != null and is_instance_valid(_voice_player):
		_voice_player.stop()
		_voice_player.stream = null
	if _spatial_player != null and is_instance_valid(_spatial_player):
		_spatial_player.stop()
		_spatial_player.stream = null

	streams.clear()
	last_played_stream = null


func _process(delta: float) -> void:
	_update_clock_tick(delta)


func _update_clock_tick(delta: float) -> void:
	if _active_clock_nodes.is_empty():
		return

	_clock_timer += delta
	if _clock_timer < CLOCK_TICK_INTERVAL:
		return

	_clock_timer = 0.0

	var p_pos := Vector2.ZERO
	if _player_node_ref != null and is_instance_valid(_player_node_ref):
		p_pos = _player_node_ref.global_position
	elif is_inside_tree() and get_tree() != null:
		var p = get_tree().get_first_node_in_group(&"player") as Node2D
		if p != null:
			p_pos = p.global_position

	for clock in _active_clock_nodes:
		if clock != null and is_instance_valid(clock):
			if p_pos.distance_to(clock.global_position) <= CLOCK_PROXIMITY_RADIUS:
				play_spatial_sound(&"clock_tick", clock.global_position)
				break


# --- Public Binding Methods ---


func bind_pocket_watch(watch: PocketWatch) -> void:
	if _pocket_watch_ref == watch:
		return
	if _pocket_watch_ref != null:
		if _pocket_watch_ref.watch_used.is_connected(_on_watch_used):
			_pocket_watch_ref.watch_used.disconnect(_on_watch_used)
		if _pocket_watch_ref.ability_selection_refused.is_connected(_on_ability_selection_refused):
			_pocket_watch_ref.ability_selection_refused.disconnect(_on_ability_selection_refused)

	_pocket_watch_ref = watch
	if _pocket_watch_ref != null:
		if not _pocket_watch_ref.watch_used.is_connected(_on_watch_used):
			_pocket_watch_ref.watch_used.connect(_on_watch_used)
		if not _pocket_watch_ref.ability_selection_refused.is_connected(_on_ability_selection_refused):
			_pocket_watch_ref.ability_selection_refused.connect(_on_ability_selection_refused)


func bind_echo_service(echo: EchoService) -> void:
	if _echo_service_ref == echo:
		return
	if _echo_service_ref != null:
		if _echo_service_ref.state_changed.is_connected(_on_echo_state_changed):
			_echo_service_ref.state_changed.disconnect(_on_echo_state_changed)
		if _echo_service_ref.recording_auto_stopped.is_connected(_on_echo_recording_auto_stopped):
			_echo_service_ref.recording_auto_stopped.disconnect(_on_echo_recording_auto_stopped)

	_echo_service_ref = echo
	if _echo_service_ref != null:
		_prev_echo_state = _echo_service_ref.state
		if not _echo_service_ref.state_changed.is_connected(_on_echo_state_changed):
			_echo_service_ref.state_changed.connect(_on_echo_state_changed)
		if not _echo_service_ref.recording_auto_stopped.is_connected(_on_echo_recording_auto_stopped):
			_echo_service_ref.recording_auto_stopped.connect(_on_echo_recording_auto_stopped)


func bind_dialogue_box(diag: DialogueBox) -> void:
	if _dialogue_box_ref == diag:
		return
	if _dialogue_box_ref != null and _dialogue_box_ref.line_displayed.is_connected(_on_dialogue_line_displayed):
		_dialogue_box_ref.line_displayed.disconnect(_on_dialogue_line_displayed)

	_dialogue_box_ref = diag
	if _dialogue_box_ref != null:
		if not _dialogue_box_ref.line_displayed.is_connected(_on_dialogue_line_displayed):
			_dialogue_box_ref.line_displayed.connect(_on_dialogue_line_displayed)


func bind_room_router(router: RoomRouter) -> void:
	if _room_router_ref == router:
		return
	if _room_router_ref != null and _room_router_ref.room_entered.is_connected(_on_room_entered):
		_room_router_ref.room_entered.disconnect(_on_room_entered)

	_room_router_ref = router
	if _room_router_ref != null:
		if not _room_router_ref.room_entered.is_connected(_on_room_entered):
			_room_router_ref.room_entered.connect(_on_room_entered)
		if _room_router_ref.current_room != null:
			_on_room_entered(_room_router_ref.current_room_id)


func bind_outro(outro: Ch01Outro) -> void:
	if outro == null:
		return
	if not outro.device_click_played.is_connected(_on_device_click_played):
		outro.device_click_played.connect(_on_device_click_played)
	if outro.audio_click != null and outro.audio_click.stream == null:
		outro.audio_click.stream = streams.get(&"device_click")
		outro.audio_click.bus = BUS_SFX


# --- Signal Handlers ---


func _on_watch_used(ability: StringName, _target_id: StringName, result: InteractionResult) -> void:
	if result != null and result.ok:
		match ability:
			&"trace":
				play_sound(&"trace")
			&"rewind":
				play_sound(&"rewind")
			&"freeze":
				play_sound(&"freeze")
			&"echo":
				# Echo activation sounds are handled by EchoService state_changed
				pass
	else:
		# Refusal feedback
		play_sound(&"ability_locked")


func _on_ability_selection_refused(_ability: StringName, _reason: StringName) -> void:
	play_sound(&"ability_locked")


func _on_echo_state_changed(new_state: int) -> void:
	if new_state == EchoService.State.RECORDING:
		play_sound(&"echo_record_start")
	elif _prev_echo_state == EchoService.State.RECORDING:
		play_sound(&"echo_record_stop")
	elif new_state == EchoService.State.PLAYING:
		play_sound(&"echo_play")
	_prev_echo_state = new_state


func _on_echo_recording_auto_stopped(_reason: StringName) -> void:
	if _prev_echo_state == EchoService.State.RECORDING:
		play_sound(&"echo_record_stop")
		_prev_echo_state = EchoService.State.READY


func _on_dialogue_line_displayed(speaker_key: String, text_key: String) -> void:
	# Operator motif: "a faint second tick under the watch whenever the 'VOICE' speaks"
	if speaker_key == "SPK_OPERATOR":
		play_sound(&"operator_motif")

	# Examine 23:59 clock
	if text_key == "EL_CLOCK_2359":
		play_sound(&"clock_tick")


func _on_room_entered(_room_id: StringName) -> void:
	_active_clock_nodes.clear()
	_clock_timer = 0.0

	if _room_router_ref == null or _room_router_ref.current_room == null:
		return

	var room := _room_router_ref.current_room

	# 1. Connect OperatorSighting if in room (TLF-058 hook)
	var op := room.find_child("operator_sighting", true, false) as OperatorSighting
	if op != null:
		if not op.audio_sting_requested.is_connected(_on_operator_sting_requested):
			op.audio_sting_requested.connect(_on_operator_sting_requested)
		if op.audio_player != null and op.audio_player.stream == null:
			op.audio_player.stream = streams.get(&"operator_sighting")
			op.audio_player.bus = BUS_SFX

	# 2. Find digital_clock_2359 objects for ambient proximity ticking
	for child in room.get_children():
		if child is Node2D:
			var node_name := String(child.name)
			var obj_id := String(child.get("object_id")) if "object_id" in child else ""
			if node_name.contains("digital_clock_2359") or obj_id.contains("digital_clock_2359"):
				_active_clock_nodes.append(child as Node2D)


func _on_operator_sting_requested() -> void:
	play_sound(&"operator_sighting")


func _on_device_click_played() -> void:
	play_sound(&"device_click")


# --- Playback Engine ---


func _should_play_audio() -> bool:
	return DisplayServer.get_name() != "headless"


func play_sound(sound_id: StringName) -> void:
	last_played_sound = sound_id
	var stream: AudioStream = streams.get(sound_id)
	last_played_stream = stream
	play_history.append(sound_id)
	sound_played.emit(sound_id, stream)

	if stream == null or not _should_play_audio():
		return

	if sound_id == &"operator_motif":
		if _voice_player != null:
			_voice_player.stream = stream
			_voice_player.play()
	else:
		if _sfx_players.size() > 0:
			var player := _sfx_players[_sfx_player_index]
			_sfx_player_index = (_sfx_player_index + 1) % _sfx_players.size()
			player.stream = stream
			player.play()


func play_spatial_sound(sound_id: StringName, pos: Vector2) -> void:
	last_spatial_sound = sound_id
	var stream: AudioStream = streams.get(sound_id)
	last_spatial_stream = stream
	play_history.append(sound_id)
	sound_played.emit(sound_id, stream)

	if stream == null or not _should_play_audio():
		return

	if _spatial_player != null:
		_spatial_player.global_position = pos
		_spatial_player.stream = stream
		_spatial_player.play()
	else:
		play_sound(sound_id)


# --- Test Queries ---


func was_sound_played(sound_id: StringName) -> bool:
	return play_history.has(sound_id)


func get_sound_count(sound_id: StringName) -> int:
	var count := 0
	for id in play_history:
		if id == sound_id:
			count += 1
	return count


func clear_history() -> void:
	play_history.clear()
	last_played_sound = &""
	last_played_stream = null
	last_spatial_sound = &""
	last_spatial_stream = null
