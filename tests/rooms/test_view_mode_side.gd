extends "res://tests/support/base_test.gd"

## TLF-074 (ADR-025): view-mode plumbing and the side-view movement/camera rule, with the real
## Player scene and the side fixture room `tests/rooms/fixtures/side_room_fixture.tscn` (1440 px
## wide, floor line y 394, door W, anchor + checkpoint at x 200, Rewind gate at x 560, Freeze gear
## at x 700, traceable silhouette at x 840, echo plate at x 1000), linked to a small iso room.

const ROOT := "user://tlf_test_view_mode_saves"
const ISO_ROOM := &"ch01.room_iso"
const SIDE := &"ch01.room_side"
const FIXTURE := "res://tests/rooms/fixtures/side_room_fixture.tscn"
const FLOOR_Y := 394.0


func _own(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_own(child, owner)


func _iso_room() -> PackedScene:
	var root := Node2D.new()
	root.name = "RoomIso"
	var d := DoorwayPresenter.new()
	d.name = "door_e"
	d.object_id = &"ch01.room_iso.door_e"
	d.room_id = ISO_ROOM
	d.door_id = &"door_e"
	d.position = Vector2(400, 200)
	var marker := Marker2D.new()
	marker.name = "Spawn"
	marker.position = Vector2(-40, 0)
	d.add_child(marker)
	root.add_child(d)
	_own(d, root)
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


## Session + router + the real Player scene; graph iso:door_e <-> side:door_w.
func _rig() -> Dictionary:
	var s := make_session()
	var g := SpatialGraph.new()
	g.add_room(ISO_ROOM, [&"door_e"])
	g.add_room(SIDE, [&"door_w"])
	g.set_initial_pairs([[ISO_ROOM, &"door_e", SIDE, &"door_w"]])
	s.spatial_service.set_graph(g, ISO_ROOM)
	var container := Node2D.new()
	container.name = "RoomContainer"
	s.add_child(container)
	var player := (load("res://scenes/player/Player.tscn") as PackedScene).instantiate() as Player
	s.add_child(player)
	var router := RoomRouter.new()
	router.name = "RoomRouter"
	router.session = s
	router.room_container = container
	router.player = player
	var store := SaveStore.new()   # own save root: never the real saves
	store.name = "SaveService"
	store.save_root = ROOT
	router.add_child(store)
	router.save_service = store
	s.add_child(router)
	s.room_router = router
	router.register_room(ISO_ROOM, _iso_room())
	router.register_room(SIDE, load(FIXTURE) as PackedScene)
	var modes: Array[StringName] = []
	router.view_mode_changed.connect(func(mode: StringName) -> void: modes.append(mode))
	return {"s": s, "router": router, "player": player, "modes": modes}


func _walk(rig: Dictionary, presenter_id: StringName) -> void:
	rig["s"].sim_clock.step(20)   # past the arrival grace
	rig["s"].interaction_service.trigger_enter(&"player", presenter_id)
	rig["router"].process_pending()


func _done(rig: Dictionary) -> void:
	free_session(rig["s"])
	var dir := DirAccess.open(ROOT)
	if dir != null:
		for f in dir.get_files():
			dir.remove(f)
		DirAccess.remove_absolute(ROOT)


func _hold(action: StringName, frames: int) -> void:
	press(action)
	await until(func() -> bool: return Input.is_action_pressed(action), 30)
	await physics_frames(frames)
	release(action)
	await until(func() -> bool: return not Input.is_action_pressed(action), 30)
	await physics_frames(1)


# --- mode switch -----------------------------------------------------------------------------

func test_mode_switch_both_ways_without_leaks() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var player: Player = rig["player"]
	_assert_true(router.enter_room(ISO_ROOM, &"door_e"), "entered the iso room")
	_assert_eq(router.current_view_mode(), ViewMode.ISO, "no metadata/view_mode: iso")
	_assert_eq(player.sprite.sprite_frames, Player.ISO_FRAMES, "iso SpriteFrames")
	_assert_false(router.camera.horizontal_only, "iso camera follows both ways")
	await physics_frames(2)
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)

	for round in 3:
		_walk(rig, &"ch01.room_iso.door_e")
		_assert_eq(router.current_room_id, SIDE, "round %d: in the side room" % round)
		_assert_eq(router.current_view_mode(), ViewMode.SIDE, "round %d: side mode" % round)
		_assert_eq(player.view_mode, ViewMode.SIDE, "round %d: the player is in side mode" % round)
		_assert_eq(player.sprite.sprite_frames, Player.SIDE_FRAMES, "round %d: side SpriteFrames" % round)
		_assert_true(player.facing_direction in ["e", "w"], "round %d: faces e or w (%s)" % [round, player.facing_direction])
		_assert_eq(player.sprite.animation, StringName("idle_" + player.facing_direction), "round %d: side idle" % round)
		_assert_eq(player.global_position, Vector2(72, FLOOR_Y), "round %d: door spawn (72, 364) put on the floor line" % round)
		_assert_true(router.camera.horizontal_only, "round %d: camera horizontal only" % round)
		_assert_eq(router.camera.bounds, Rect2(0, 0, 1440, 540), "round %d: camera bounds = the side scene" % round)
		_assert_eq(DepthSort.apply(router.current_room), 0, "round %d: DepthSort skips the side room" % round)
		_walk(rig, &"ch01.room_side.door_w")
		_assert_eq(router.current_room_id, ISO_ROOM, "round %d: back in the iso room" % round)
		_assert_eq(player.view_mode, ViewMode.ISO, "round %d: the player is back in iso mode" % round)
		_assert_eq(player.sprite.sprite_frames, Player.ISO_FRAMES, "round %d: iso SpriteFrames again" % round)
		_assert_true(player.sprite.sprite_frames.has_animation(player.sprite.animation), "round %d: a valid iso animation" % round)
		_assert_false(router.camera.horizontal_only, "round %d: camera follows both ways again" % round)
		await physics_frames(2)

	_assert_eq(rig["modes"], [ViewMode.SIDE, ViewMode.ISO, ViewMode.SIDE, ViewMode.ISO, ViewMode.SIDE, ViewMode.ISO],
		"view_mode_changed on every change, both ways")
	_assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, "no orphan nodes left by 3 round trips")
	_done(rig)


func test_unknown_or_reserved_mode_is_iso() -> void:
	var room := Node2D.new()
	_assert_eq(ViewMode.of(room), ViewMode.ISO, "no metadata: iso")
	room.set_meta(&"view_mode", &"topdown")
	_assert_eq(ViewMode.of(room), ViewMode.ISO, "topdown is reserved: iso")
	room.set_meta(&"view_mode", &"side")
	_assert_eq(ViewMode.of(room), ViewMode.SIDE, "side")
	_assert_eq(ViewMode.side_view_of(room).floor_y, FLOOR_Y, "a side room without metadata/side_view: default floor line 394")
	room.free()


# --- side movement and facing ----------------------------------------------------------------

func test_side_movement_and_facing() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var player: Player = rig["player"]
	router.enter_room(SIDE, &"", &"ch01.room_side.anchor")
	_assert_eq(player.global_position, Vector2(200, FLOOR_Y), "at the anchor on the floor line")
	await physics_frames(2)

	await _hold(&"move_up", 20)
	await _hold(&"move_down", 20)
	_assert_eq(player.global_position, Vector2(200, FLOOR_Y), "up / down alone do not move Elias")

	press(&"move_right")
	await until(func() -> bool: return Input.is_action_pressed(&"move_right"), 30)
	await physics_frames(10)
	_assert_eq(player.facing_direction, "e", "walking right faces e")
	_assert_eq(player.sprite.animation, &"walk_e", "walk_e plays")
	release(&"move_right")
	await physics_frames(2)
	var x_right := player.global_position.x
	_assert_true(x_right > 200.0 + 15.0, "walked right (x %.1f)" % x_right)
	_assert_eq(player.global_position.y, FLOOR_Y, "feet on the floor line")
	_assert_eq(player.sprite.animation, &"idle_e", "idle_e when stopped")

	# Diagonal input: only the horizontal part counts, at full speed.
	var start_x := player.global_position.x
	press(&"move_right")
	press(&"move_up")
	await until(func() -> bool: return Input.is_action_pressed(&"move_up"), 30)
	var x0 := player.global_position.x
	await physics_frames(30)
	var dx := player.global_position.x - x0
	release(&"move_up")
	release(&"move_right")
	await physics_frames(2)
	_assert_true(player.global_position.x > start_x, "right+up moves right")
	_assert_true(absf(dx - 30.0 * player.walk_speed / 60.0) <= player.walk_speed / 60.0 + 0.01,
		"right+up moves at walk_speed (%.2f px in 30 frames)" % dx)
	_assert_eq(player.global_position.y, FLOOR_Y, "and never leaves the floor line")

	press(&"move_left")
	await until(func() -> bool: return Input.is_action_pressed(&"move_left"), 30)
	await physics_frames(5)
	_assert_eq(player.facing_direction, "w", "walking left faces w")
	_assert_eq(player.sprite.animation, &"walk_w", "walk_w plays")
	release(&"move_left")
	await physics_frames(2)
	_assert_eq(player.sprite.animation, &"idle_w", "idle_w when stopped")

	# The walkable range ends 16 px from the scene edge (east: the west end has the door).
	player.global_position = Vector2(1410, FLOOR_Y)
	await _hold(&"move_right", 30)
	_assert_eq(player.global_position, Vector2(1424, FLOOR_Y), "stops at walk_max_x (1440 - 16)")
	_done(rig)


# --- camera ----------------------------------------------------------------------------------

func test_side_camera_horizontal_clamp_and_fixed() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var player: Player = rig["player"]
	router.enter_room(SIDE, &"", &"ch01.room_side.anchor")
	var cam := router.camera
	_assert_eq(cam.get_screen_center_position(), Vector2(480, 270), "x 200: clamped to the west edge (480, 270) on entry")
	for p in [Vector2(700, FLOOR_Y), Vector2(1400, FLOOR_Y), Vector2(700, 100), Vector2(963.4, FLOOR_Y)]:
		player.global_position = p
		await physics_frames(1)
		var c := cam.get_screen_center_position()
		_assert_eq(c.y, 270.0, "target %s: y fixed at 270 (no vertical follow)" % p)
		_assert_eq(c, c.round(), "target %s: whole pixels" % p)
		_assert_true(c.x >= 480.0 and c.x <= 960.0, "target %s: x clamped to [480, 960] (%s)" % [p, c])
		_assert_true(cam.bounds.encloses(cam.view_rect()), "target %s: view inside the 1440 x 540 scene" % p)
	player.global_position = Vector2(700, FLOOR_Y)
	await physics_frames(1)
	_assert_eq(cam.get_screen_center_position(), Vector2(700, 270), "middle of the scene: follows x")
	_done(rig)

	# A side scene as wide as the screen: fixed camera.
	var camera := RoomCamera.new()
	var target := Node2D.new()
	_tree().root.add_child(target)
	camera.target = target
	camera.horizontal_only = true
	camera.set_bounds(SideView.new().bounds_px())
	_tree().root.add_child(camera)
	camera.make_current()
	for x in [16.0, 300.0, 944.0]:
		target.position = Vector2(x, FLOOR_Y)
		camera.snap_now()
		_assert_eq(camera.get_screen_center_position(), Vector2(480, 270), "960 px scene, x %d: fixed (480, 270)" % x)
	camera.free()
	target.free()


# --- abilities -------------------------------------------------------------------------------

## Each ability once through the pocket watch, targeted from Elias's spot on the floor line.
func test_each_ability_in_the_side_room() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var player: Player = rig["player"]
	var s: GameSession = rig["s"]
	router.enter_room(SIDE, &"", &"ch01.room_side.anchor")
	var watch := player.pocket_watch
	await physics_frames(2)

	var cases := [[&"trace", Vector2(800, FLOOR_Y), &"ch01.room_side.silhouette"],
		[&"rewind", Vector2(520, FLOOR_Y), &"ch01.room_side.gate"],
		[&"freeze", Vector2(660, FLOOR_Y), &"ch01.room_side.gear"]]
	for c in cases:
		player.global_position = c[1]
		watch.set_selected_ability(c[0])
		await physics_frames(2)
		_assert_true(watch.current_target != null and watch.current_target.object_id == c[2],
			"%s: targets %s from x %d on the floor line" % [c[0], c[2], c[1].x])
		var res := watch.activate_watch()
		_assert_true(res.ok, "%s works in side view (%s)" % [c[0], res.reason])
	_assert_true((router.current_room.get_node("Gear") as Interactable).get_temporal().is_frozen, "the gear is frozen")

	# A refusal uses an existing reason key: the gate has no earlier state left to rewind to.
	player.global_position = Vector2(520, FLOOR_Y)
	watch.set_selected_ability(&"rewind")
	await physics_frames(2)
	var refused := watch.activate_watch()
	_assert_false(refused.ok, "a second Rewind is refused")
	_assert_true(UIFeedback.REASON_TO_KEY.has(refused.reason), "with an existing reason key (%s)" % refused.reason)

	# Echo: record a walk onto the plate, play it back; the echo holds the plate.
	player.global_position = Vector2(900, FLOOR_Y)
	watch.set_selected_ability(&"echo")
	_assert_true(watch.activate_watch().ok, "echo: start recording")
	s.interaction_service.trigger_enter(&"player", &"ch01.room_side.plate")
	s.sim_clock.step(30)
	_assert_true(watch.activate_watch().ok, "echo: stop recording")
	s.interaction_service.trigger_exit(&"player", &"ch01.room_side.plate")
	_assert_true(watch.activate_watch().ok, "echo: play back")
	s.sim_clock.step(40)
	_assert_true(&"ch01.room_side.plate" in s.echo_service.get_echo_occupied_triggers(), "the echo stands on the plate")
	_done(rig)


## Echo samples and the ghost stay on the floor line; Rewind and Freeze leave Elias on it.
func test_echo_and_rewind_positions_on_the_floor_line() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var player: Player = rig["player"]
	var s: GameSession = rig["s"]
	router.enter_room(SIDE, &"", &"ch01.room_side.anchor")
	await physics_frames(2)
	var watch := player.pocket_watch
	watch.set_selected_ability(&"echo")
	_assert_true(watch.activate_watch().ok, "recording")
	press(&"move_right")
	press(&"move_down")   # pushing down while walking must not leave the line
	await until(func() -> bool: return Input.is_action_pressed(&"move_down"), 30)
	await physics_frames(60)
	release(&"move_down")
	release(&"move_right")
	await physics_frames(2)
	_assert_true(watch.activate_watch().ok, "stopped")
	var length := s.echo_service.get_record_length()
	_assert_true(length > 30, "a walk of %d ticks was recorded" % length)
	var off_line := 0
	var xs: Array[float] = []
	for t in range(0, length + 1, 3):
		var p := s.echo_service.get_ghost_position(t)
		xs.append(p.x)
		if p.y != FLOOR_Y:
			off_line += 1
	_assert_eq(off_line, 0, "every recorded echo position is on the floor line")
	_assert_true(xs.back() > xs.front() + 50.0, "the echo walks right (%.1f -> %.1f)" % [xs.front(), xs.back()])
	_assert_true(watch.activate_watch().ok, "play back")
	await physics_frames(3)
	var ghost := watch._ghost_node
	_assert_true(ghost != null and ghost.visible, "the ghost is shown")
	_assert_eq(ghost.global_position.y, FLOOR_Y, "the ghost walks on the floor line")

	player.global_position = Vector2(520, FLOOR_Y)
	watch.set_selected_ability(&"rewind")
	await physics_frames(2)
	_assert_true(watch.activate_watch().ok, "Rewind the gate")
	await physics_frames(2)
	_assert_eq(player.global_position, Vector2(520, FLOOR_Y), "Rewind leaves Elias where he stood on the floor line")
	_assert_eq((router.current_room.get_node("Gate") as Node2D).global_position, Vector2(560, FLOOR_Y), "the gate stays on the floor line")
	_done(rig)


# --- save / load -----------------------------------------------------------------------------

## The saved room id decides the mode: a load into the side room restores the mode, the sprites
## and the camera together with the player, on the first frame.
func test_save_load_in_the_side_room() -> void:
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	router.enter_room(SIDE, &"", &"ch01.room_side.anchor")
	rig["s"].interaction_service.trigger_enter(&"player", &"ch01.room_side.checkpoint")
	_assert_eq(router.last_checkpoint_id, &"ch01.cp.room_side", "checkpoint reached in the side room")
	var data: Dictionary = router.save_service.read_slot(0)["data"]
	free_session(rig["s"])

	var rig2 := _rig()
	var r2: RoomRouter = rig2["router"]
	var player: Player = rig2["player"]
	r2.enter_room(ISO_ROOM, &"door_e")
	_assert_eq(player.view_mode, ViewMode.ISO, "a fresh session starts in the iso room")
	player.global_position = Vector2(9999, 9999)
	_assert_true(r2.restore_from_save(data)["ok"], "restore ok")
	_assert_eq(r2.current_room_id, SIDE, "back in the side room")
	_assert_eq(player.view_mode, ViewMode.SIDE, "side mode restored")
	_assert_eq(player.sprite.sprite_frames, Player.SIDE_FRAMES, "side sprites restored")
	_assert_eq(player.global_position, Vector2(200, FLOOR_Y), "at the checkpoint anchor on the floor line")
	_assert_true(r2.camera.horizontal_only, "camera in horizontal-only mode")
	_assert_eq(r2.camera.bounds, Rect2(0, 0, 1440, 540), "camera bounds = the side scene")
	_assert_eq(r2.camera.get_screen_center_position(), Vector2(480, 270), "camera with the player on the first frame")
	_assert_eq(rig2["modes"].back(), ViewMode.SIDE, "view_mode_changed announced the side mode")
	await physics_frames(2)
	_assert_eq(player.global_position, Vector2(200, FLOOR_Y), "still on the floor line after physics frames")
	_done(rig2)
	var dir := DirAccess.open(ROOT)
	_assert_true(dir == null or dir.get_files().is_empty(), "test saves cleaned up")


# --- side SpriteFrames (TLF-075 sheet, ASSET_METADATA 13.1) ----------------------------------

func test_side_sprite_frames_and_reach_gesture() -> void:
	var frames := Player.SIDE_FRAMES
	var expected := {&"idle_e": [0, 2, true], &"walk_e": [2, 6, true], &"interact_e": [8, 3, false],
		&"idle_w": [11, 2, true], &"walk_w": [13, 6, true], &"interact_w": [19, 3, false]}
	_assert_eq(Array(frames.get_animation_names()).size(), 6, "six animations")
	for anim in expected:
		var first: int = expected[anim][0]
		var count: int = expected[anim][1]
		_assert_eq(frames.get_frame_count(anim), count, "%s: %d frames" % [anim, count])
		_assert_eq(frames.get_animation_loop(anim), expected[anim][2], "%s loops: %s" % [anim, expected[anim][2]])
		for k in count:
			var tex := frames.get_frame_texture(anim, k) as AtlasTexture
			_assert_true(tex.atlas.resource_path.ends_with("ch01_char_elias_side_sheet.png"), "%s/%d from the side sheet" % [anim, k])
			_assert_eq(tex.region, Rect2((first + k) * 32, 0, 32, 48), "%s/%d is cell %d" % [anim, k, first + k])

	# A successful watch use in side view plays the reach gesture, then idles again.
	var rig := _rig()
	var router: RoomRouter = rig["router"]
	var player: Player = rig["player"]
	router.enter_room(SIDE, &"", &"ch01.room_side.anchor")
	player.global_position = Vector2(800, FLOOR_Y)
	player.pocket_watch.set_selected_ability(&"trace")
	await physics_frames(2)
	await tap(&"watch")
	_assert_eq(player.sprite.animation, &"interact_e", "Trace through real input plays interact_e")
	await until(func() -> bool: return not player.sprite.is_playing() or player.sprite.animation != &"interact_e", 60)
	await physics_frames(2)
	_assert_eq(player.sprite.animation, &"idle_e", "back to idle_e after the gesture")
	_done(rig)
