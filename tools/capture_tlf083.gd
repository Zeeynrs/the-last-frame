extends SceneTree

## TLF-083 Part 1 proof (ADR-026). Run it in a renamed scratch copy, never in a worktree (Chapter01
## writes a playtest log and an autosave):  godot --path . -s tools/capture_tlf083.gd
## Lights Arrival Platform at RUNTIME ONLY (no scene file changes): A 2, the 23:59 clock 2/1, a gate
## helper 1/0 and the departure-board information region (index 24 only), the Elias zone 2/1.
## At the spawn and at the gate it saves lit / unlit / setting-off frames and checks every pixel of
## the shader output against LightingPass.output_index() (the GDScript reference), the palette, that
## the setting restores the unlit frame exactly, and the GPU time with and without the pass.

const OUT := "res://docs/handoffs/TLF-083"
const BOARD_FACE := [Vector2(64, 148), Vector2(223, 71), Vector2(223, 100), Vector2(64, 177)]

var _ch01: Node2D
var _router: RoomRouter
var _player: Player
var _hud: CanvasLayer
var _settings: Node
var _palette := {}


func _initialize() -> void:
	var timer := create_timer(110.0)
	timer.timeout.connect(func():
		printerr("TIMEOUT: capture_tlf083 exceeded 110 s")
		quit(1))
	call_deferred("_run")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _grab() -> Image:
	await _frames(3)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _save(img: Image, name: String) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT).path_join(name + ".png"))
	print("CAPTURED %s" % name)


func _gpu_ms(frames: int = 120) -> float:
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	await _frames(10)
	var total := 0.0
	for i in frames:
		await process_frame
		total += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	return total / frames


func _light(name: String, pos: Vector2, radius: Vector2, lift_in: int, lift_out: int) -> RoomLight:
	var l := RoomLight.new()
	l.name = name
	l.position = pos
	l.radius = radius
	l.lift_inner = lift_in
	l.lift_outer = lift_out
	return l


func _light_the_room() -> void:
	var room := _router.current_room
	room.set_meta(&"lighting", RoomLighting.new())
	room.add_child(_light("ClockLight", Vector2(592, 160), Vector2(40, 28), 2, 1))
	room.add_child(_light("GateHelper", Vector2(720, 326), Vector2(64, 32), 1, 0))
	var board := RoomLight.new()
	board.name = "BoardInfo"
	board.shape = RoomLight.Shape.QUAD
	board.quad = PackedVector2Array(BOARD_FACE)
	board.only_indices = PackedInt32Array([24])
	board.lift_inner = 2
	room.add_child(board)
	var bounds := _router.current_room_bounds()
	print("VALIDATE %s" % [LightingPass.validate_room(room, room.get_meta(&"lighting"), bounds)])
	_router._apply_lighting()


func _key(c: Color) -> int:
	return (c.r8 << 16) | (c.g8 << 8) | c.b8


## Every pixel of `lit` against the reference applied to `unlit`; returns [mismatches, off-palette,
## glyphs kept on the board, dado/other 24 darkened outside it, floor darkened inside the board quad].
func _check(unlit: Image, lit: Image, pass_node: LightingPass) -> Array:
	var entries := pass_node.screen_lights()
	var mismatches := 0
	var off_palette := 0
	var kept_24_inside := 0
	var dark_24_outside := 0
	var dark_other_inside := 0
	var xf := root.get_canvas_transform()
	var face: PackedVector2Array = []
	for p in BOARD_FACE:
		face.append((xf * p).round())
	var box := Rect2(face[0], Vector2.ZERO)
	for p in face:
		box = box.expand(p)
	for y in unlit.get_height():
		for x in unlit.get_width():
			var src := _palette.get(_key(unlit.get_pixel(x, y)), -1) as int
			if src < 0:
				src = TlfPalette.nearest_index(unlit.get_pixel(x, y))
			var got := _palette.get(_key(lit.get_pixel(x, y)), -1) as int
			if got < 0:
				off_palette += 1
			var want := pass_node.output_index(Vector2(x, y), src, entries)
			if got != want:
				mismatches += 1
			var centre := Vector2(x, y) + Vector2(0.5, 0.5)
			var inside := box.has_point(centre) and Geometry2D.is_point_in_polygon(centre, face)
			if src == 24 and inside and got == 24:
				kept_24_inside += 1
			if src == 24 and not inside and got != 24:
				dark_24_outside += 1
			if src != 24 and src < 25 and inside and got != src:
				dark_other_inside += 1
	return [mismatches, off_palette, kept_24_inside, dark_24_outside, dark_other_inside]


## Sol b71c0a9: Elias idle / walk / turn under the zone. 8 facings x (idle 0, walk 1, 3, 5), each a
## 96 x 96 native crop centred on him while he steps 4 px per column across the gate floor; the same
## sheet unlit, and a greyscale copy of the lit one.
func _motion_sheets(pass_node: LightingPass) -> void:
	var dirs := ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
	var cols := [["idle_", 0], ["walk_", 1], ["walk_", 3], ["walk_", 5]]
	var lit_sheet := Image.create(96 * cols.size(), 96 * dirs.size(), false, Image.FORMAT_RGBA8)
	var unlit_sheet := Image.create(96 * cols.size(), 96 * dirs.size(), false, Image.FORMAT_RGBA8)
	_hud.visible = false
	for r in dirs.size():
		for c in cols.size():
			var anim: String = cols[c][0] + dirs[r]
			if not _player.sprite.sprite_frames.has_animation(anim):
				continue
			_player.global_position = Vector2(600 + c * 4, 250 + r * 2)
			_router.camera.snap_now()
			_player.sprite.play(anim)
			_player.sprite.pause()
			_player.sprite.frame = cols[c][1]
			var at := (root.get_canvas_transform() * _player.global_position).round()
			var rect := Rect2i(int(at.x) - 48, int(at.y) - 72, 96, 96)
			_router._apply_lighting()
			var lit := await _grab()
			lit.convert(Image.FORMAT_RGBA8)
			lit_sheet.blit_rect(lit, rect, Vector2i(c * 96, r * 96))
			pass_node.apply_room(null, null, null)
			var unlit := await _grab()
			unlit.convert(Image.FORMAT_RGBA8)
			unlit_sheet.blit_rect(unlit, rect, Vector2i(c * 96, r * 96))
	_router._apply_lighting()
	_save(lit_sheet, "elias_motion_lit")
	_save(unlit_sheet, "elias_motion_unlit")
	var grey := lit_sheet.duplicate()
	for y in grey.get_height():
		for x in grey.get_width():
			var col: Color = grey.get_pixel(x, y)
			var l: float = 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b
			grey.set_pixel(x, y, Color(l, l, l, 1.0))
	_save(grey, "elias_motion_lit_greyscale")
	_hud.visible = true


func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "windowed Forward+ only")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for i in TlfPalette.SIZE:
		_palette[_key(TlfPalette.COLORS[i])] = i
	var save = root.get_node_or_null("SaveService")
	if save != null:
		save.save_root = "user://tlf083_capture_saves"
	_settings = root.get_node_or_null("Settings")
	_settings.lighting_enabled = true
	_ch01 = (load("res://scenes/chapters/ch01/Chapter01.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(_ch01)
	await _frames(30)
	_router = _ch01.get_node("RoomRouter") as RoomRouter
	_player = _ch01.get_node("Player") as Player
	_hud = _player.hud
	var diag := _ch01.call("get_dialogue_box") as DialogueBox
	if diag != null and diag.is_active:
		diag.finish_sequence()
	_light_the_room()
	var pass_node := _router.lighting_pass
	print("PASS layer %d, HUD layer %d, lights %d, visible %s" % [pass_node.layer, _hud.layer, pass_node.lights.size(), pass_node.visible])

	for row in [["spawn", Vector2(160, 224), "idle_s"], ["gate", Vector2(656, 264), "idle_se"]]:
		_player.global_position = row[1]
		_router.camera.snap_now()
		_player.set_physics_process(false)
		_player.sprite.play(row[2])
		_player.sprite.pause()
		_player.sprite.frame = 0
		_hud.hide_feedback()
		await _frames(5)
		_hud.visible = true
		_save(await _grab(), "%s_lit" % row[0])
		_hud.visible = false
		var lit := await _grab()
		_save(lit, "%s_lit_nohud" % row[0])
		_settings.lighting_enabled = false
		var setting_off := await _grab()
		_save(setting_off, "%s_setting_off_nohud" % row[0])
		var ms_off := await _gpu_ms()
		_settings.lighting_enabled = true
		var ms_on := await _gpu_ms()
		pass_node.apply_room(null, null, null)
		var unlit := await _grab()
		_save(unlit, "%s_unlit_nohud" % row[0])
		_router._apply_lighting()
		await _frames(2)
		var same := setting_off.get_data() == unlit.get_data()
		var r := _check(unlit, lit, pass_node)
		print("CHECK %s: shader vs reference mismatches %d / %d px; off-palette %d; board glyphs kept %d; 24 darkened outside the board %d; other indices darkened inside the board %d; setting off == unlit %s" % [
			row[0], r[0], lit.get_width() * lit.get_height(), r[1], r[2], r[3], r[4], same])
		print("TIMING %s: viewport GPU %.3f ms with the pass, %.3f ms without (setting off), delta %.3f ms" % [row[0], ms_on, ms_off, ms_on - ms_off])
		_hud.visible = true
	await _motion_sheets(pass_node)
	print("ALL TLF-083 PROOFS CAPTURED")
	quit(0)
