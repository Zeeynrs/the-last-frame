extends "res://tests/support/base_test.gd"

## RoomCamera (ADR-023 R1, TLF-065): whole-pixel follow camera clamped to the room bounds.
## Review Focus 1 (clamp edge and door: no jitter, no off-bounds frame, no black strip) is here;
## Review Focus 2 and 3 (room transition, save/load) are in test_room_router.gd.

## 40 x 12 tiles: (40+12)*16 = 832 px wide, 416 + margins tall, so the camera scrolls both ways.
const LARGE_W := 40
const LARGE_H := 12


func _rig(bounds: Rect2) -> Dictionary:
	var target := Node2D.new()
	target.name = "Target"
	_tree().root.add_child(target)
	var camera := RoomCamera.new()
	camera.target = target
	camera.set_bounds(bounds)
	_tree().root.add_child(camera)
	camera.make_current()
	camera.snap_now()
	return {"camera": camera, "target": target}


func _done(rig: Dictionary) -> void:
	rig["camera"].free()
	rig["target"].free()


func _whole(v: Vector2) -> bool:
	return v.x == roundf(v.x) and v.y == roundf(v.y)


## The view the viewport actually shows (canvas transform), in world coordinates.
func _shown(camera: RoomCamera) -> Rect2:
	var view := RoomCamera.view_size()
	return Rect2(camera.get_screen_center_position() - view * 0.5, view)


func test_position_is_whole_pixel_every_frame() -> void:
	var bounds := RoomShape.rectangle(LARGE_W, LARGE_H).bounds_px()
	var rig := _rig(bounds)
	var camera: RoomCamera = rig["camera"]
	var target: Node2D = rig["target"]
	target.position = bounds.get_center() + Vector2(-200.3, -40.7)
	var not_whole := 0
	var outside := 0
	var moved := 0
	var last := camera.get_screen_center_position()
	for i in 240:
		target.position += Vector2(1.37, 0.41)   # a diagonal walk at fractional speed
		await physics_frames(1)
		var centre := camera.get_screen_center_position()
		if not (_whole(camera.position) and _whole(centre)):
			not_whole += 1
		if not bounds.encloses(_shown(camera)):
			outside += 1
		if centre != last:
			moved += 1
		last = centre
	_assert_eq(not_whole, 0, "camera position and screen centre are whole pixels on every frame")
	_assert_eq(outside, 0, "the view never leaves the bounds")
	_assert_true(moved > 100, "the camera followed the walk (%d moves)" % moved)
	_done(rig)


func test_clamps_to_bounds() -> void:
	var bounds := RoomShape.rectangle(LARGE_W, LARGE_H).bounds_px()
	var rig := _rig(bounds)
	var camera: RoomCamera = rig["camera"]
	var target: Node2D = rig["target"]
	var view := RoomCamera.view_size()
	for corner in [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y),
			bounds.position - Vector2(500, 500), bounds.end + Vector2(500, 500)]:
		target.position = corner
		camera.snap_now()
		var shown := _shown(camera)
		_assert_true(bounds.encloses(shown), "target at %s: view %s inside bounds %s" % [corner, shown, bounds])
		var touches_x := is_equal_approx(shown.position.x, ceilf(bounds.position.x)) or is_equal_approx(shown.end.x, floorf(bounds.end.x))
		var touches_y := is_equal_approx(shown.position.y, ceilf(bounds.position.y)) or is_equal_approx(shown.end.y, floorf(bounds.end.y))
		_assert_true(touches_x and touches_y, "target at %s: the view rests on the bounds edges" % corner)
	target.position = bounds.get_center()
	camera.snap_now()
	_assert_eq(camera.get_screen_center_position(), bounds.get_center().round(), "centred on a target in the middle")
	_assert_eq(view, Vector2(640, 360), "the view is the 640 x 360 internal canvas")
	_done(rig)


## A room that fits the screen keeps today's fixed view: camera at (320, 180), no canvas transform.
## A small room off that spot is shown whole and does not move either.
func test_room_smaller_than_screen_is_fixed() -> void:
	var legacy := RoomShape.rectangle(14, 10).bounds_px()
	var rig := _rig(legacy)
	var camera: RoomCamera = rig["camera"]
	var target: Node2D = rig["target"]
	for p in [Vector2(160, 144), Vector2(544, 176), Vector2(384, 256), Vector2(320, 64), Vector2(352, 160)]:
		target.position = p
		await physics_frames(1)
		_assert_eq(camera.get_screen_center_position(), Vector2(320, 180), "14 x 10 room, target at %s: fixed at (320, 180)" % p)
	_assert_eq(camera.get_viewport().get_canvas_transform(), Transform2D.IDENTITY, "same canvas transform as without a camera")
	camera.set_bounds(Rect2(Vector2(420, 260), Vector2(300, 150)))   # small, partly right of / below the legacy screen
	var first := Vector2.INF
	for p in [Vector2(430, 270), Vector2(700, 400), Vector2(560, 330)]:
		target.position = p
		await physics_frames(1)
		var centre := camera.get_screen_center_position()
		if first == Vector2.INF:
			first = centre
		_assert_eq(centre, first, "small room, target at %s: the camera does not move" % p)
		_assert_true(_shown(camera).encloses(camera.bounds), "small room: all of it is on screen")
	_done(rig)


func test_snap_now_on_room_entry_same_frame() -> void:
	var bounds := RoomShape.rectangle(LARGE_W, LARGE_H).bounds_px()
	var rig := _rig(bounds)
	var camera: RoomCamera = rig["camera"]
	var target: Node2D = rig["target"]
	target.position = bounds.position + Vector2(100, 100)
	camera.snap_now()
	await physics_frames(2)
	var before := camera.get_screen_center_position()
	target.position = bounds.end - Vector2(100, 100)    # teleport (door / respawn)
	camera.snap_now()
	var after := camera.get_screen_center_position()
	_assert_true(after != before, "the camera moved")
	_assert_eq(after, camera.centre_for(target.position), "on the target's clamped position on the same frame, no pan")
	_assert_eq(camera.get_viewport().get_canvas_transform().origin, -(after - RoomCamera.view_size() * 0.5),
		"the viewport already draws from there")
	_done(rig)


## Review Focus 1: standing exactly on a clamp edge, or shuffling at a door on the room edge, never
## makes the camera jitter, and no frame shows anything outside the bounds (no black strip).
func test_clamp_edge_and_door_no_jitter_no_off_bounds_frame() -> void:
	var bounds := RoomShape.rectangle(LARGE_W, LARGE_H).bounds_px()
	var rig := _rig(bounds)
	var camera: RoomCamera = rig["camera"]
	var target: Node2D = rig["target"]
	var view := RoomCamera.view_size()
	# The x where the camera starts to clamp on the west side, and a door spot on the east edge.
	var edge_x := bounds.position.x + view.x * 0.5
	var door := Vector2(bounds.end.x - 20, bounds.get_center().y)
	for spot in [Vector2(edge_x, bounds.get_center().y), Vector2(ceilf(edge_x), bounds.get_center().y), door]:
		var centres := {}
		var outside := 0
		for i in 60:
			target.position = spot + Vector2(0.45 * sin(i * 1.7), 0.45 * cos(i * 2.3))   # sub-pixel shuffle
			await physics_frames(1)
			centres[camera.get_screen_center_position()] = true
			if not bounds.encloses(_shown(camera)):
				outside += 1
		_assert_true(centres.size() <= 2, "at %s the camera holds still (%d positions: %s)" % [spot, centres.size(), centres.keys()])
		_assert_eq(outside, 0, "at %s no frame shows outside the bounds" % spot)
	# Walking steadily across the clamp edge: the centre never steps backwards and never jumps.
	target.position = Vector2(edge_x - 30, bounds.get_center().y)
	await physics_frames(1)
	var last := camera.get_screen_center_position().x
	var backwards := 0
	var jumps := 0
	for i in 120:
		target.position.x += 0.5
		await physics_frames(1)
		var x := camera.get_screen_center_position().x
		if x < last:
			backwards += 1
		if x - last > 1.0:
			jumps += 1
		last = x
	_assert_eq(backwards, 0, "no step backwards while walking across the edge")
	_assert_eq(jumps, 0, "at most one pixel per frame at 0.5 px per frame")
	_done(rig)
