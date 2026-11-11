extends SceneTree

## TLF-085 concrete floor recolour proof (Lead 2026-11-12: concrete_service moves from the steel ramp
## 11/12/13 to the floor ramp 01/03/04). Run it only in a scratch copy with a renamed config/name,
## windowed Forward+, one room per call, lighting off (unlit art):
##   TLF_OUT=<dir> TLF_ROOM=<room id> TLF_TAG=<before|after> [TLF_DOOR=<entry door>] [TLF_AT=x,y]
##   godot --path . --resolution 960x540 -s res://tools/capture_tlf085_concrete.gd
## Saves <room>_<tag>_unlit.png (HUD hidden; Elias at TLF_AT or the entry door spawn, door_entry_west by default) and prints, for
## every grounded caster (ShadeBaker.grounded: props standing on the floor) whose sprite is in frame:
## its base pixels (opaque sprite pixels in its lowest 6 rows) against the floor pixels in a band
## 1..6 px below and beside that base: greyscale means and contrast, the mean RGB distance between
## each base pixel and the floor pixel under it, and how many base pixels have the same colour as
## the floor pixel directly below (an index collision makes the prop melt into the floor).

var _router: RoomRouter
var _player: Player


func _initialize() -> void:
	create_timer(100.0).timeout.connect(func():
		printerr("TIMEOUT: capture_tlf085_concrete exceeded 100 s")
		quit(1))
	call_deferred("_run")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


static func _lum(c: Color) -> float:
	return 0.2126 * c.r8 + 0.7152 * c.g8 + 0.0722 * c.b8


static func _rgb(a: Color, b: Color) -> float:
	return Vector3(a.r8 - b.r8, a.g8 - b.g8, a.b8 - b.b8).length()


func _sprites_of(node: Node) -> Array:
	var root_node := node
	while root_node.get_parent() != _router.current_room and root_node.get_parent() != null:
		root_node = root_node.get_parent()
	var out: Array = []
	for s in root_node.find_children("*", "Sprite2D", true, false) + ([root_node] if root_node is Sprite2D else []):
		if (s as Sprite2D).visible and (s as Sprite2D).texture != null:
			out.append(s)
	return out


func _measure(img: Image, sprite: Sprite2D) -> Dictionary:
	var tex_img := sprite.texture.get_image()
	if tex_img.is_compressed():
		tex_img.decompress()
	var xf := sprite.get_global_transform_with_canvas()
	var rect := sprite.get_rect()
	var inv := xf.affine_inverse()
	var box := Rect2(xf * rect.position, Vector2.ZERO).expand(xf * rect.end)
	var opaque := {}
	var bottom := -1
	for y in range(maxi(int(box.position.y), 0), mini(int(ceil(box.end.y)), 540)):
		for x in range(maxi(int(box.position.x), 0), mini(int(ceil(box.end.x)), 960)):
			var t := Vector2i((inv * Vector2(x + 0.5, y + 0.5) - rect.position).floor())
			if t.x >= 0 and t.y >= 0 and t.x < tex_img.get_width() and t.y < tex_img.get_height() and tex_img.get_pixel(t.x, t.y).a > 0.5:
				opaque[Vector2i(x, y)] = true
				bottom = maxi(bottom, y)
	if opaque.is_empty():
		return {}
	var base: Array = []
	for k in opaque:
		if (k as Vector2i).y > bottom - 6:
			base.append(k)
	var floor_px := {}
	var same := 0
	var dist := 0.0
	var pairs := 0
	for k in base:
		var p: Vector2i = k
		# the first non-sprite pixel straight below this base pixel (within 6 px)
		for dy in range(1, 7):
			var q := p + Vector2i(0, dy)
			if q.y >= 540 or opaque.has(q):
				continue
			pairs += 1
			dist += _rgb(img.get_pixelv(p), img.get_pixelv(q))
			if img.get_pixelv(p) == img.get_pixelv(q):
				same += 1
			break
		for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(1, 1)]:
			for r in range(1, 7):
				var q2: Vector2i = p + d * r
				if q2.x < 0 or q2.y < 0 or q2.x >= 960 or q2.y >= 540 or opaque.has(q2):
					continue
				floor_px[q2] = true
	var lb := 0.0
	for k in base:
		lb += _lum(img.get_pixelv(k))
	var lf := 0.0
	for k in floor_px:
		lf += _lum(img.get_pixelv(k))
	return {"base": base.size(), "floor": floor_px.size(), "lum_base": lb / base.size(), "lum_floor": lf / maxf(floor_px.size(), 1),
		"rgb": dist / maxf(pairs, 1), "same": same, "pairs": pairs, "box": box}


func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "windowed Forward+ only")
	var out := OS.get_environment("TLF_OUT")
	var room_id := StringName(OS.get_environment("TLF_ROOM"))
	var tag := OS.get_environment("TLF_TAG")
	var at := OS.get_environment("TLF_AT")
	var door := OS.get_environment("TLF_DOOR")
	var save = root.get_node_or_null("SaveService")
	if save != null:
		save.save_root = "user://tlf085concrete_capture_saves"
	var settings := root.get_node_or_null("Settings")
	settings.lighting_enabled = false
	var ch01 := (load("res://scenes/chapters/ch01/Chapter01.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(ch01)
	await _frames(30)
	_router = ch01.get_node("RoomRouter") as RoomRouter
	_player = ch01.get_node("Player") as Player
	_router.enter_room(room_id, StringName(door) if not door.is_empty() else &"door_entry_west")
	await _frames(10)
	var diag := ch01.call("get_dialogue_box") as DialogueBox
	if diag != null and diag.is_active:
		diag.finish_sequence()
	_player.set_physics_process(false)
	if not at.is_empty():
		_player.global_position = Vector2(float(at.get_slice(",", 0)), float(at.get_slice(",", 1)))
	_router.camera.snap_now()
	_player.sprite.play("idle_se")
	_player.sprite.pause()
	_player.hud.hide_feedback()
	_player.hud.visible = false
	await _frames(5)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var name := "%s_%s_unlit" % [String(room_id).get_slice(".", 1), tag]
	img.save_png(out.path_join(name + ".png"))
	print("CAPTURED %s (lighting off, setting %s)" % [name, settings.lighting_enabled])
	var room := _router.current_room as Node2D
	var shape: RoomShape = room.get_meta(&"room_shape") as RoomShape if room.has_meta(&"room_shape") else null
	var seen := {}
	for g in ShadeBaker.grounded(room, shape):
		for s in _sprites_of(g["node"]):
			if seen.has(s):
				continue
			seen[s] = true
			var m := _measure(img, s)
			if m.is_empty() or m["floor"] == 0:
				continue
			var bx: Rect2 = m["box"]
			print("BOX %s: (%d, %d, %d, %d)" % [String(room.get_path_to(s)), int(bx.position.x), int(bx.position.y), int(bx.size.x), int(bx.size.y)])
			print("PROP %s %s: base %d px grey %.1f vs floor %d px grey %.1f (contrast %+.1f); base->floor below: mean RGB distance %.1f, same colour %d of %d" % [
				tag, String(room.get_path_to(s)), m["base"], m["lum_base"], m["floor"], m["lum_floor"], m["lum_base"] - m["lum_floor"],
				m["rgb"], m["same"], m["pairs"]])
	print("TLF-085 CONCRETE DONE %s %s" % [room_id, tag])
	quit(0)
