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
	s.add_child(router)
	router.save_service.save_root = ROOT
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
	var data := SaveService.default_save()
	data["spatial"] = {"pairs": [], "actor_rooms": {"player": "ch01.nowhere"}}
	_assert_eq(rig["router"].restore_from_save(data)["reason"], &"unknown_room", "refused")
	_done(rig)
