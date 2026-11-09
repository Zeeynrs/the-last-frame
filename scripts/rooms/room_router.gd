class_name RoomRouter
extends Node

## Per-room scene loading inside a chapter (ADR-018). Session service: the GameSession and the
## player persist; exactly one room scene lives under `room_container` at a time.
##
## - Doorways: rooms contain DoorwayPresenters; their `traversed` signal moves the player to the
##   destination doorway (same room: reposition only; other room: unload + load). The player is
##   placed at the destination presenter's "Spawn" child (or the presenter itself).
## - World memory: unloading a room caches the temporal history of its objects by object_id and
##   restores it when the room is loaded again; saves include the cache.
## - The active echo is reset on every room change (an echo belongs to its room).
## - After any placement, doorway traversals are ignored for ARRIVAL_GRACE_TICKS so the player is
##   never bounced straight back through the doorway they arrived at.
## - Traversals and relocations are queued and executed by process_pending() (each physics frame),
##   never inside the presenter callback: freeing a room while one of its nodes is mid-call is unsafe.
## - Camera (ADR-023): after every placement the RoomCamera gets the room's bounds and snaps onto
##   the player on the same frame (no pan from the previous room). A room declares its floor with
##   `metadata/room_shape` (a RoomShape) on its root node; without one the bounds are the old
##   640x360 screen area, which the camera centres in the 960x540 view (dark margin around it).

signal room_entered(room_id: StringName)
signal checkpoint_reached(checkpoint_id: StringName, error: Error)

const ARRIVAL_GRACE_TICKS: int = 12
const PLAYER_ACTOR: StringName = &"player"

@export var session: GameSession
@export var room_container: Node
@export var player: Node2D
@export var chapter: String = "ch01"
@export var autosave_slot: int = 0
## Data-driven room table (ADR-013): room_id (StringName) -> PackedScene.
@export var room_scenes: Dictionary = {}
## Follow camera; created as a child on the first placement when not set.
@export var camera: RoomCamera

var save_service: SaveStore = null
var current_room_id: StringName = &""
var current_room: Node = null
var last_checkpoint_id: StringName = &""

var _room_scenes: Dictionary = {}     # room_id -> PackedScene
var _temporal_cache: Dictionary = {}  # object_id(String) -> TemporalComponent.export_history()
var _grace_until_tick: int = -1
var _pending: Array = []              # queued [room_id, door_id, anchor_id] transitions


func _ready() -> void:
	if session == null:
		session = get_parent() as GameSession
	if session != null and session.spatial_service != null:
		session.spatial_service.relocate_requested.connect(_on_relocate_requested)
	for room_id in room_scenes.keys():
		register_room(StringName(room_id), room_scenes[room_id])
	if save_service == null:
		# Prefer the SaveService autoload (ADR-011); own a SaveStore only when it is not registered.
		save_service = get_node_or_null("/root/SaveService") as SaveStore
	if save_service == null:
		save_service = SaveStore.new()
		save_service.name = "SaveService"
		add_child(save_service)


func _physics_process(_delta: float) -> void:
	process_pending()


## Executes queued transitions in order. Called every physics frame; tests call it directly.
func process_pending() -> void:
	while not _pending.is_empty():
		var request: Array = _pending.pop_front()
		enter_room(request[0], request[1], request[2])


func has_pending() -> bool:
	return not _pending.is_empty()


static func room_of(object_id: StringName) -> StringName:
	var parts := String(object_id).split(".")
	return StringName("%s.%s" % [parts[0], parts[1]]) if parts.size() >= 2 else &""


func register_room(room_id: StringName, scene: PackedScene) -> void:
	_room_scenes[room_id] = scene


func has_room(room_id: StringName) -> bool:
	return _room_scenes.has(room_id)


## Loads `room_id` (if not already current) and places the player at `door_id`'s spawn or at
## `anchor_id`. Returns false (nothing changes) for an unknown room.
func enter_room(room_id: StringName, door_id: StringName = &"", anchor_id: StringName = &"") -> bool:
	if not _room_scenes.has(room_id):
		push_error("RoomRouter: unknown room '%s'." % room_id)
		return false
	if room_id != current_room_id or current_room == null:
		_unload_current()
		current_room = _room_scenes[room_id].instantiate()
		current_room_id = room_id
		room_container.add_child(current_room)
		_restore_cache(current_room)
		_connect_doorways(current_room)
		room_entered.emit(room_id)
	if session.spatial_service != null:
		session.spatial_service.set_actor_room(PLAYER_ACTOR, room_id)
	_place_player(door_id, anchor_id)
	_sync_camera()
	return true


## Writes the autosave (cache of unloaded rooms included). Returns the write error.
func reach_checkpoint(checkpoint_id: StringName) -> Error:
	last_checkpoint_id = checkpoint_id
	var error := ERR_UNCONFIGURED
	if save_service != null:
		error = save_service.write_slot(autosave_slot, capture_save(String(checkpoint_id)))
	checkpoint_reached.emit(checkpoint_id, error)
	return error


func capture_save(checkpoint_id: String) -> Dictionary:
	var data := save_service.capture(session, chapter, checkpoint_id)
	for id in _temporal_cache.keys():
		if not data["temporal"].has(id):
			data["temporal"][id] = _temporal_cache[id].duplicate(true)
	return data


## Applies a save and respawns the player in the saved room at its checkpoint.
## Returns {ok, reason}. Temporal entries for rooms that aren't loaded go into world memory.
func restore_from_save(data: Dictionary) -> Dictionary:
	var room_id := StringName(str(data.get("spatial", {}).get("actor_rooms", {}).get(String(PLAYER_ACTOR), "")))
	if not _room_scenes.has(room_id):
		return {"ok": false, "reason": &"unknown_room"}
	_unload_current()
	_temporal_cache.clear()
	_pending.clear()
	var result := save_service.apply(session, data)
	if not result["ok"]:
		return {"ok": false, "reason": result["reason"]}
	for id in result["skipped"]:
		_temporal_cache[id] = data["temporal"][id].duplicate(true)
	enter_room(room_id)
	last_checkpoint_id = StringName(str(data.get("checkpoint_id", "")))
	var zone := _find_checkpoint(current_room, last_checkpoint_id)
	if zone != null:
		if String(zone.spawn_anchor_id).is_empty():
			_move_player_to(zone.global_position)
		else:
			_place_player(&"", zone.spawn_anchor_id)
		_sync_camera()
	return {"ok": true, "reason": &""}


## The current room's RoomShape (`metadata/room_shape` on the room root), or null.
func current_room_shape() -> RoomShape:
	if current_room == null or not current_room.has_meta(&"room_shape"):
		return null
	return current_room.get_meta(&"room_shape") as RoomShape


## Camera bounds of the current room: its shape's bounds_px(), else the old 640x360 screen area
## (RoomCamera.LEGACY_SCREEN), which the camera centres in the 960x540 view.
func current_room_bounds() -> Rect2:
	var shape := current_room_shape()
	if shape != null and shape.is_valid():
		return shape.bounds_px()
	return RoomCamera.LEGACY_SCREEN


func get_cached_ids() -> Array:
	var ids := _temporal_cache.keys()
	ids.sort()
	return ids


# --- internals ------------------------------------------------------------------------

func _unload_current() -> void:
	if current_room == null:
		return
	for node in _interactables(current_room):
		var temporal: TemporalComponent = node.get_temporal()
		if temporal != null and not String(node.object_id).is_empty():
			_temporal_cache[String(node.object_id)] = temporal.export_history()
	if session.echo_service != null:
		session.echo_service.notify_room_changed()
		session.echo_service.reset_echo()
	room_container.remove_child(current_room)  # _exit_tree unregisters IDs immediately
	current_room.free()
	current_room = null
	current_room_id = &""


func _restore_cache(room: Node) -> void:
	for node in _interactables(room):
		var key := String(node.object_id)
		var temporal: TemporalComponent = node.get_temporal()
		if temporal != null and _temporal_cache.has(key):
			temporal.import_history(_temporal_cache[key])
			_temporal_cache.erase(key)


func _connect_doorways(room: Node) -> void:
	for node in _descendants(room):
		if node is DoorwayPresenter and not node.traversed.is_connected(_on_traversed):
			node.traversed.connect(_on_traversed)


func _on_traversed(actor_id: StringName, destination: Dictionary) -> void:
	if actor_id != PLAYER_ACTOR or _now() < _grace_until_tick:
		return
	_pending.append([destination["room_id"], destination["door_id"], &""])


func _on_relocate_requested(actor_id: StringName, anchor_id: StringName) -> void:
	if actor_id != PLAYER_ACTOR:
		return
	_pending.append([room_of(anchor_id), &"", anchor_id])


func _place_player(door_id: StringName, anchor_id: StringName) -> void:
	if player == null or current_room == null:
		return
	var target: Node2D = null
	if not String(anchor_id).is_empty():
		target = session.id_registry.resolve(anchor_id) as Node2D
	elif not String(door_id).is_empty():
		for node in _descendants(current_room):
			if node is DoorwayPresenter and node.door_id == door_id:
				target = node.get_node_or_null("Spawn") as Node2D
				if target == null:
					target = node
				break
	if target != null:
		_move_player_to(target.global_position)


func _move_player_to(position: Vector2) -> void:
	player.global_position = position
	if player is CharacterBody2D:
		player.velocity = Vector2.ZERO
	_grace_until_tick = _now() + ARRIVAL_GRACE_TICKS


func _sync_camera() -> void:
	if player == null:
		return
	if camera == null:
		camera = RoomCamera.new()
		add_child(camera)
	camera.target = player
	camera.set_bounds(current_room_bounds())
	if camera.is_inside_tree() and not camera.is_current():
		camera.make_current()
	camera.snap_now()


func _find_checkpoint(room: Node, checkpoint_id: StringName) -> CheckpointZone:
	if room == null:
		return null
	for node in _descendants(room):
		if node is CheckpointZone and node.checkpoint_id == checkpoint_id:
			return node
	return null


func _interactables(root: Node) -> Array:
	return _descendants(root).filter(func(n): return n is Interactable)


func _descendants(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		out.append(node)
		stack.append_array(node.get_children())
	return out


func _now() -> int:
	return session.sim_clock.tick if session != null and session.sim_clock != null else 0
