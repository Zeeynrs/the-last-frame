extends "res://tests/support/base_test.gd"

## RoomRouter (ADR-018): room loading, doorway placement, world memory, echo reset, arrival grace,
## checkpoints/autosave, restore from save, cross-room relocation.

const ROOT := "user://tlf_test_router_saves"
const A := &"ch01.room_a"
const B := &"ch01.room_b"
const GATE := &"ch01.room_a.gate"


func _own(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_own(child, owner)


func _doorway(room: StringName, door: StringName, spawn: Vector2) -> DoorwayPresenter:
	var d := DoorwayPresenter.new()
	d.name = String(door)
	d.object_id = StringName("%s.%s" % [room, door])
	d.room_id = room
	d.door_id = door
	var marker := Marker2D.new()
	marker.name = "Spawn"
	marker.position = spawn
	d.add_child(marker)
	return d


func _room_a() -> PackedScene:
	var root := Node2D.new()
	root.name = "RoomA"
	root.add_child(_doorway(A, &"door_e", Vector2(100, 0)))
	var gate := TemporalTestGate.new()
	gate.name = "Gate"
	gate.object_id = GATE
	gate.add_child(make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
		[{"arm_state": &"open", "passage_blocked": false}]))
	root.add_child(gate)
	var anchor := SafeAnchor.new()
	anchor.name = "Anchor"
	anchor.object_id = &"ch01.room_a.anchor"
	anchor.position = Vector2(50, 50)
	root.add_child(anchor)
	var cp := CheckpointZone.new()
	cp.name = "Checkpoint"
	cp.object_id = &"ch01.room_a.checkpoint"
	cp.checkpoint_id = &"ch01.cp.room_a"
	cp.spawn_anchor_id = &"ch01.room_a.anchor"
	root.add_child(cp)
	for child in root.get_children():
		_own(child, root)
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


func _room_b() -> PackedScene:
	var root := Node2D.new()
	root.name = "RoomB"
	root.add_child(_doorway(B, &"door_w", Vector2(200, 0)))
	root.add_child(_doorway(B, &"door_n", Vector2(0, -80)))
	root.add_child(_doorway(B, &"door_s", Vector2(0, 80)))
	for child in root.get_children():
		_own(child, root)
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


## Session + router + container + player, rooms A/B, graph A:door_e<->B:door_w, B:door_n<->B:door_s.
func _rig() -> Dictionary:
	var s := make_session()
	var g := SpatialGraph.new()
	g.add_room(A, [&"door_e"])
	g.add_room(B, [&"door_w", &"door_n", &"door_s"])
	g.set_initial_pairs([[A, &"door_e", B, &"door_w"], [B, &"door_n", B, &"door_s"]])
	s.spatial_service.set_graph(g, A)
	s.spatial_service.set_relocation_anchor(B, &"ch01.room_a.anchor")
	var container := Node2D.new()
	container.name = "RoomContainer"
	s.add_child(container)
	var player := CharacterBody2D.new()
	player.name = "Player"
	s.add_child(player)
	var router := RoomRouter.new()
	router.name = "RoomRouter"
	router.session = s
	router.room_container = container
	router.player = player
	# Own store so tests never touch the SaveService autoload's real save root.
	var store := SaveStore.new()
	store.name = "SaveService"
	store.save_root = ROOT
	router.add_child(store)
	router.save_service = store
	s.add_child(router)
	s.room_router = router
	router.register_room(A, _room_a())
	router.register_room(B, _room_b())
	return {"s": s, "router": router, "player": player}


func _walk(rig: Dictionary, presenter_id: StringName) -> void:
	var s: GameSession = rig["s"]
	s.interaction_service.trigger_enter(&"player", presenter_id)
	rig["router"].process_pending()


func _done(rig: Dictionary) -> void:
	free_session(rig["s"])
	var dir := DirAccess.open(ROOT)
	if dir != null:
		for f in dir.get_files():
			dir.remove(f)
		DirAccess.remove_absolute(ROOT)


func test_enter_room_loads_scene_registers_objects_and_places_player() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	_assert_true(router.enter_room(A, &"door_e"), "enter A")
	_assert_eq(router.current_room_id, A, "current room")
	_assert_true(rig["s"].id_registry.has_id(GATE), "room objects registered")
	_assert_eq(rig["player"].global_position, Vector2(100, 0), "placed at door_e spawn")
	_assert_eq(rig["s"].spatial_service.get_actor_room(&"player"), A, "spatial actor room")
	_assert_false(router.enter_room(&"ch01.nowhere"), "unknown room refused")
	_assert_eq(router.current_room_id, A, "unchanged after refusal")
	_done(rig)


func test_doorway_moves_player_to_other_room_and_unloads_old_one() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	router.enter_room(A)
	rig["s"].sim_clock.step(20)                       # past arrival grace
	_walk(rig, &"ch01.room_a.door_e")
	_assert_eq(router.current_room_id, B, "now in B")
	_assert_false(rig["s"].id_registry.has_id(GATE), "A's objects unregistered")
	_assert_eq(rig["player"].global_position, Vector2(200, 0), "placed at B:door_w spawn")
	_done(rig)


func test_same_room_loop_repositions_without_reload() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	router.enter_room(B)
	var instance := router.current_room
	rig["s"].sim_clock.step(20)
	_walk(rig, &"ch01.room_b.door_n")
	_assert_true(router.current_room == instance, "same instance (no reload)")
	_assert_eq(rig["player"].global_position, Vector2(0, 80), "placed at door_s spawn")
	_done(rig)


func test_arrival_grace_ignores_immediate_traversal() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	router.enter_room(A, &"door_e")
	_walk(rig, &"ch01.room_a.door_e")                 # same tick as arrival
	_assert_eq(router.current_room_id, A, "bounce-back ignored during grace")
	rig["s"].interaction_service.trigger_exit(&"player", &"ch01.room_a.door_e")
	rig["s"].sim_clock.step(RoomRouter.ARRIVAL_GRACE_TICKS)
	_walk(rig, &"ch01.room_a.door_e")
	_assert_eq(router.current_room_id, B, "traversal works after grace")
	_done(rig)


func test_world_memory_keeps_consumed_rewind_across_rooms() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var s: GameSession = rig["s"]
	router.enter_room(A)
	_assert_true(s.interaction_service.request(&"player", GATE, &"rewind").ok, "rewind gate")
	s.sim_clock.step(20)
	_walk(rig, &"ch01.room_a.door_e")
	_assert_eq(router.get_cached_ids(), [String(GATE)], "gate history cached on unload")
	s.sim_clock.step(20)
	_walk(rig, &"ch01.room_b.door_w")
	var gate := s.id_registry.resolve(GATE) as TemporalTestGate
	_assert_eq(gate.arm_state, &"open", "gate still open after returning")
	_assert_eq(s.interaction_service.request(&"player", GATE, &"rewind").reason, &"no_history", "rewind not refunded")
	_assert_eq(router.get_cached_ids(), [], "cache consumed on load")
	_done(rig)


func test_room_change_resets_echo() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var s: GameSession = rig["s"]
	router.enter_room(A)
	s.echo_service.start_recording()
	s.sim_clock.step(20)
	_walk(rig, &"ch01.room_a.door_e")
	_assert_eq(s.echo_service.state, EchoService.State.IDLE, "echo reset on room change")
	_done(rig)


func test_checkpoint_autosave_and_restore_into_fresh_session() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var s: GameSession = rig["s"]
	router.enter_room(A)
	s.interaction_service.request(&"player", GATE, &"rewind")
	s.sim_clock.step(20)
	_walk(rig, &"ch01.room_a.door_e")                 # gate cached, now in B
	s.puzzle_service.mark_solved(&"CH1-PZ-001")
	_assert_eq(router.reach_checkpoint(&"ch01.cp.room_b_test"), OK, "autosave written")
	var saved := router.save_service.read_slot(0)
	_assert_true(saved["ok"], "autosave readable")
	_assert_true(saved["data"]["temporal"].has(String(GATE)), "unloaded room state included in save")
	free_session(s)

	var rig2 := _rig()
	var r2: RoomRouter = rig2["router"]
	_assert_true(r2.restore_from_save(saved["data"])["ok"], "restore ok")
	_assert_eq(r2.current_room_id, B, "respawned in saved room")
	_assert_true(rig2["s"].puzzle_service.is_solved(&"CH1-PZ-001"), "progress restored")
	_assert_eq(r2.get_cached_ids(), [String(GATE)], "A's state parked in world memory")
	rig2["s"].sim_clock.step(20)
	_walk(rig2, &"ch01.room_b.door_w")
	_assert_eq(rig2["s"].interaction_service.request(&"player", GATE, &"rewind").reason, &"no_history", "consumed rewind survives save/load")
	_done(rig2)


func test_restore_places_player_at_checkpoint_spawn_anchor() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	router.enter_room(A, &"door_e")
	rig["s"].interaction_service.trigger_enter(&"player", &"ch01.room_a.checkpoint")
	_assert_eq(router.last_checkpoint_id, &"ch01.cp.room_a", "checkpoint zone reached")
	var data: Dictionary = router.save_service.read_slot(0)["data"]
	rig["player"].global_position = Vector2(999, 999)
	_assert_true(router.restore_from_save(data)["ok"], "restore ok")
	_assert_eq(rig["player"].global_position, Vector2(50, 50), "spawned at the checkpoint's anchor")
	_done(rig)


func test_relocation_to_anchor_in_another_room_loads_that_room() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var s: GameSession = rig["s"]
	router.enter_room(B)
	# Seal B off from A: A:door_e loops to itself, B's west door pairs with nothing but... B loops.
	var result := s.spatial_service.graph.apply([[A, &"door_e", A, &"door_e"], [B, &"door_w", B, &"door_w"]])
	_assert_eq(result["reason"], &"", "graph change accepted (no critical pairs registered)")
	_assert_true(router.has_pending(), "relocation queued")
	router.process_pending()
	_assert_eq(router.current_room_id, A, "moved to the anchor's room")
	_assert_eq(rig["player"].global_position, Vector2(50, 50), "at the anchor")
	_done(rig)


func test_restore_with_unknown_room_is_refused() -> void:
	var rig := _rig()
	var data := SaveStore.default_save()
	data["spatial"] = {"pairs": [], "actor_rooms": {"player": "ch01.nowhere"}}
	_assert_eq(rig["router"].restore_from_save(data)["reason"], &"unknown_room", "refused")
	_done(rig)


# --- camera (ADR-023, TLF-065; Review Focus 2 and 3) ---------------------------------------------

const BIG := &"ch01.room_big"
const SMALL := &"ch01.room_small"
const BIG_GATE := &"ch01.room_big.gate"
## 64 x 16 tiles: 1312 x 720 px of bounds, larger than the 960 x 540 view both ways.
const BIG_W := 64
const BIG_H := 16


## A 64 x 16 room (scrolls both ways) with a door far east, a checkpoint and its anchor far west,
## and a rewindable gate; a 14 x 10 room (fits the screen) with a door west.
func _shaped_room(room: StringName, shape: RoomShape, door: StringName, door_tile: Vector2, extra: bool) -> PackedScene:
	var root := Node2D.new()
	root.name = String(room).get_slice(".", 1).to_pascal_case()
	root.set_meta(&"room_shape", shape)
	var doorway := _doorway(room, door, Vector2.ZERO)
	doorway.position = RoomShape.tile_to_px(door_tile)
	root.add_child(doorway)
	if extra:
		var anchor := SafeAnchor.new()
		anchor.name = "Anchor"
		anchor.object_id = StringName("%s.anchor" % room)
		anchor.position = RoomShape.tile_to_px(Vector2(2.5, 9.5))
		root.add_child(anchor)
		var cp := CheckpointZone.new()
		cp.name = "Checkpoint"
		cp.object_id = StringName("%s.checkpoint" % room)
		cp.checkpoint_id = &"ch01.cp.room_big"
		cp.spawn_anchor_id = anchor.object_id
		cp.position = anchor.position
		root.add_child(cp)
		var gate := TemporalTestGate.new()
		gate.name = "Gate"
		gate.object_id = BIG_GATE
		gate.position = RoomShape.tile_to_px(Vector2(20.5, 6.5))
		gate.add_child(make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
			[{"arm_state": &"open", "passage_blocked": false}]))
		root.add_child(gate)
	for child in root.get_children():
		_own(child, root)
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


func _camera_rig() -> Dictionary:
	var rig := _rig()
	var s: GameSession = rig["s"]
	var router: RoomRouter = rig["router"]
	var g := SpatialGraph.new()
	g.add_room(BIG, [&"door_e"])
	g.add_room(SMALL, [&"door_w"])
	g.set_initial_pairs([[BIG, &"door_e", SMALL, &"door_w"]])
	s.spatial_service.set_graph(g, BIG)
	router.register_room(BIG, _shaped_room(BIG, RoomShape.rectangle(BIG_W, BIG_H), &"door_e", Vector2(BIG_W - 0.5, 6.5), true))
	router.register_room(SMALL, _shaped_room(SMALL, RoomShape.rectangle(14, 10), &"door_w", Vector2(0.5, 5.5), false))
	return rig


## Review Focus 2: going through a door between rooms of different sizes, the camera is on the
## new room's correct spot on the first frame, inside the new bounds, with no pan from the old room.
func test_transition_camera_correct_on_first_frame() -> void:
	var rig := _camera_rig()
	var router: RoomRouter = rig["router"]
	var player: Node2D = rig["player"]
	router.enter_room(BIG, &"door_e")
	var camera := router.camera
	_assert_true(camera != null and camera.is_current(), "the router made its camera current")
	var big_centre := camera.get_screen_center_position()
	_assert_eq(big_centre, camera.centre_for(player.global_position), "big room: on the player at the east door")
	_assert_true(big_centre.x > camera.bounds.position.x + RoomCamera.view_size().x * 0.5, "big room: scrolled east (%s)" % big_centre)
	rig["s"].sim_clock.step(20)
	_walk(rig, &"ch01.room_big.door_e")               # same call stack: no frame in between
	_assert_eq(router.current_room_id, SMALL, "now in the small room")
	_assert_eq(camera.bounds, RoomShape.rectangle(14, 10).bounds_px(), "small room bounds handed over")
	# 14 x 10 bounds (144, 0, 416, 272), worked by hand: centred in the 960 x 540 view at once.
	_assert_eq(camera.get_screen_center_position(), Vector2(352, 136), "small room: centred on its bounds at once")
	_assert_eq(camera.get_viewport().get_canvas_transform().origin, Vector2(128, 134),
		"first frame draws the small room in the middle of the view (dark margin around it)")
	rig["s"].sim_clock.step(20)
	_walk(rig, &"ch01.room_small.door_w")
	_assert_eq(router.current_room_id, BIG, "back in the big room")
	_assert_eq(camera.get_screen_center_position(), big_centre, "big room: back on the east door spot at once")
	_assert_true(camera.bounds.encloses(Rect2(camera.get_screen_center_position() - RoomCamera.view_size() * 0.5, RoomCamera.view_size())),
		"big room: the first frame is inside its bounds")
	await physics_frames(2)
	_assert_eq(camera.get_screen_center_position(), big_centre, "and stays there (no pan afterwards)")
	_done(rig)


## Review Focus 3: a save at a checkpoint in a large room and a load into a fresh session put the
## player and the camera back together on the first frame; the echo is gone and every restored
## object, the player and the anchor are inside the room's collision shape.
func test_save_load_restores_camera_with_player() -> void:
	var rig := _camera_rig()
	var router: RoomRouter = rig["router"]
	var s: GameSession = rig["s"]
	router.enter_room(BIG, &"door_e")
	_assert_true(s.interaction_service.request(&"player", BIG_GATE, &"rewind").ok, "gate rewound before the save")
	s.echo_service.start_recording()
	s.interaction_service.trigger_enter(&"player", &"ch01.room_big.checkpoint")
	_assert_eq(router.last_checkpoint_id, &"ch01.cp.room_big", "checkpoint reached in the big room")
	var data: Dictionary = router.save_service.read_slot(0)["data"]
	free_session(s)

	var rig2 := _camera_rig()
	var r2: RoomRouter = rig2["router"]
	var player: Node2D = rig2["player"]
	player.global_position = Vector2(9999, 9999)
	_assert_true(r2.restore_from_save(data)["ok"], "restore ok")
	var shape := RoomShape.rectangle(BIG_W, BIG_H)
	var anchor_px := RoomShape.tile_to_px(Vector2(2.5, 9.5))
	_assert_eq(player.global_position, anchor_px, "player at the checkpoint anchor")
	var camera := r2.camera
	_assert_eq(camera.get_screen_center_position(), camera.centre_for(anchor_px), "camera on the player on the first frame")
	_assert_eq(camera.get_screen_center_position().x, shape.bounds_px().position.x + RoomCamera.view_size().x * 0.5,
		"camera at the west clamp, with the player")
	_assert_eq(camera.bounds, shape.bounds_px(), "the big room's bounds")
	var poly := shape.perimeter_polygon_px()
	_assert_true(Geometry2D.is_point_in_polygon(player.global_position, poly), "player inside the collision shape")
	for node in r2.current_room.find_children("*", "Node2D", true, false):
		_assert_true(Geometry2D.is_point_in_polygon(node.global_position, poly), "%s inside the collision shape" % node.name)
	_assert_eq(rig2["s"].echo_service.state, EchoService.State.IDLE, "no echo after the load")
	_assert_eq(rig2["s"].interaction_service.request(&"player", BIG_GATE, &"rewind").reason, &"no_history", "the used Rewind stays used")
	await physics_frames(2)
	_assert_eq(camera.get_screen_center_position(), camera.centre_for(anchor_px), "camera still with the player")
	_done(rig2)


## TLF-071: a room scene written by build_room_from_shape.py (metadata/room_shape on its root) gives
## the router its real bounds; without it the router falls back to the old 640 x 360 screen area.
## At 960 x 540 (ADR-023 addendum 3) this 704 x 368 room fits the view, so the camera centres it.
func test_builder_written_room_gives_the_camera_its_bounds() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var player: Node2D = rig["player"]
	var scene := load("res://tests/rooms/fixtures/builder_l_room.tscn") as PackedScene
	router.register_room(A, scene)
	player.global_position = RoomShape.tile_to_px(Vector2(24.5, 4.5))   # far east, by the E door
	_assert_true(router.enter_room(A), "entered the builder-written room")
	var shape := router.current_room_shape()
	_assert_true(shape != null, "the router reads the room's RoomShape")
	_assert_eq(router.current_room_bounds(), Rect2(48, 0, 704, 368), "its bounds, not the old 640 x 360 screen area")
	var camera := router.camera
	_assert_eq(camera.bounds, shape.bounds_px(), "handed to the camera")
	var centre := camera.get_screen_center_position()
	_assert_eq(centre, camera.centre_for(player.global_position), "camera from the player's position")
	_assert_eq(centre, Vector2(400, 184), "centred on the bounds (48 + 704 / 2, 0 + 368 / 2), not on the player")
	_assert_true(camera.view_rect().encloses(camera.bounds), "the whole room is on screen")
	_done(rig)
