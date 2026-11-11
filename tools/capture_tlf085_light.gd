extends SceneTree

## TLF-085 lighting proof (ADR-026 maintenance + ADR-027 round 2) for ch01.maintenance_bay. Run it only in
## a scratch copy with a renamed config/name (Chapter01 writes a playtest log and autosaves), windowed
## Forward+, one shot per call:
##   TLF_OUT=<dir> TLF_SHOT=<arrival|tech|gear|pocket|east|solved> [TLF_A=<2|3>] [TLF_ELIAS=<inner>/<outer>]
##   godot --path . --resolution 960x540 -s res://tools/capture_tlf085_light.gd
## TLF_A / TLF_ELIAS override the scene's ambient and Elias zone for the dark stress test (A 3 vs A 2).
## Per shot it saves unlit, lit, lit_hud, setting_off, lit_noshadows (shadows and fill off), and prints:
##  - shader vs LightingPass.output_index() on the unlit frame, every pixel; off-palette; setting off;
##  - untouched pixels (exempt, non-receiver, off-floor) between lit_noshadows and lit;
##  - the dark stress test per decision object and doorway in the frame: its opaque sprite pixels,
##    the share at index 00 unlit vs lit (merged into the margin), distinct indices left, and the
##    greyscale contrast between the object and a 4 px ring around its sprite box;
##  - Elias: body pixels below lift 2 (must be 0), and the floor capsule (floor pixels the Elias zone
##    lifts above the room's own light + fill);
##  - GPU time and the bake time at entry.
## solved: the gear shot with the gear locked and the fire shutter raised (puzzle after-state).

const ROOM := &"ch01.maintenance_bay"
const SHOTS := {
	"arrival": [Vector2(272, 120), "idle_se"],
	"tech": [Vector2(352, 144), "idle_ne"],
	"gear": [Vector2(480, 208), "idle_ne"],
	"solved": [Vector2(480, 208), "idle_ne"],
	"pocket": [Vector2(544, 240), "idle_se"],
	"east": [Vector2(640, 288), "idle_se"],
}
## Decision objects and doorways (node paths with sprites under them).
const OBJECTS := ["n11_hatch_tech", "hatch_01", "hatch_plate_01", "bell_plate_01", "doc_hatch_chart",
	"counterweight_gear", "fire_shutter", "reset_anchor_01", "doc_tech_log", "inner_shutter",
	"doc_inner_shutter_plate", "YSort_Walls/Archway_door_entry_west", "YSort_Walls/Archway_door_exit_east",
	"YSort_Walls/Wall_bulkhead_n0"]

var _ch01: Node2D
var _router: RoomRouter
var _player: Player
var _hud: CanvasLayer
var _settings: Node
var _palette := {}
var _out := ""


func _initialize() -> void:
	create_timer(110.0).timeout.connect(func():
		printerr("TIMEOUT: capture_tlf085_light exceeded 110 s")
		quit(1))
	call_deferred("_run")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _grab() -> Image:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _save(img: Image, name: String) -> void:
	img.save_png(_out.path_join(name + ".png"))
	print("CAPTURED %s" % name)


func _gpu_ms(frames: int = 60) -> float:
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	await _frames(10)
	var total := 0.0
	for i in frames:
		await process_frame
		total += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	return total / frames


func _key(c: Color) -> int:
	return (c.r8 << 16) | (c.g8 << 8) | c.b8


func _index(c: Color) -> int:
	var i: int = _palette.get(_key(c), -1)
	return i if i >= 0 else TlfPalette.nearest_index(c)


static func _lum(c: Color) -> float:
	return 0.2126 * c.r8 + 0.7152 * c.g8 + 0.0722 * c.b8


## Screen pixels covered by the opaque texels of `tex` drawn with `xf` (canvas transform included)
## over `rect` (the sprite's local rect).
func _sprite_pixels(tex: Texture2D, xf: Transform2D, rect: Rect2, out: Dictionary) -> void:
	if tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return
	if img.is_compressed():
		img.decompress()
	var inv := xf.affine_inverse()
	var a := xf * rect.position
	var b := xf * rect.end
	var box := Rect2(a, Vector2.ZERO).expand(b)
	for y in range(maxi(int(box.position.y), 0), mini(int(ceil(box.end.y)), 540)):
		for x in range(maxi(int(box.position.x), 0), mini(int(ceil(box.end.x)), 960)):
			var l := inv * Vector2(x + 0.5, y + 0.5) - rect.position
			var t := Vector2i(l.floor())
			if t.x < 0 or t.y < 0 or t.x >= img.get_width() or t.y >= img.get_height():
				continue
			if img.get_pixel(t.x, t.y).a > 0.5:
				out[Vector2i(x, y)] = true


func _object_pixels(path: String) -> Dictionary:
	var out := {}
	var node := _router.current_room.get_node_or_null(path)
	if node == null:
		return out
	var sprites: Array = [node] if node is Sprite2D else []
	sprites.append_array(node.find_children("*", "Sprite2D", true, false))
	for s in sprites:
		var sp := s as Sprite2D
		if sp.visible and sp.texture != null:
			_sprite_pixels(sp.texture, sp.get_global_transform_with_canvas(), sp.get_rect(), out)
	return out


func _elias_pixels() -> Dictionary:
	var out := {}
	var spr := _player.sprite
	var tex := spr.sprite_frames.get_frame_texture(spr.animation, spr.frame)
	var size := tex.get_size()
	var rect := Rect2(spr.offset - size / 2.0 if spr.centered else spr.offset, size)
	_sprite_pixels(tex, spr.get_global_transform_with_canvas(), rect, out)
	return out


func _stress(unlit: Image, lit: Image, path: String) -> String:
	var px := _object_pixels(path)
	if px.is_empty():
		return "%s: not in frame" % path
	var n := 0
	var z_unlit := 0
	var z_lit := 0
	var levels := {}
	var lum_obj := 0.0
	var box := Rect2i()
	var first := true
	for k in px:
		var p: Vector2i = k
		if p.x < 0 or p.y < 0 or p.x >= 960 or p.y >= 540:
			continue
		n += 1
		if _index(unlit.get_pixel(p.x, p.y)) == 0:
			z_unlit += 1
		var li := _index(lit.get_pixel(p.x, p.y))
		if li == 0:
			z_lit += 1
		levels[li] = true
		lum_obj += _lum(lit.get_pixel(p.x, p.y))
		box = Rect2i(p, Vector2i.ONE) if first else box.expand(p)
		first = false
	box = box.grow(1)
	var ring := box.grow(4)
	var lum_ring := 0.0
	var m := 0
	for y in range(maxi(ring.position.y, 0), mini(ring.end.y, 540)):
		for x in range(maxi(ring.position.x, 0), mini(ring.end.x, 960)):
			if box.has_point(Vector2i(x, y)):
				continue
			lum_ring += _lum(lit.get_pixel(x, y))
			m += 1
	var merged := 100.0 * (z_lit - z_unlit) / maxf(n, 1)
	return "%s: %d px; index 00 unlit %.0f%% -> lit %.0f%% (merged +%.0f pts); %d indices left; grey mean %.1f vs ring %.1f (contrast %+.1f)" % [
		path, n, 100.0 * z_unlit / n, 100.0 * z_lit / n, merged, levels.size(), lum_obj / n, lum_ring / maxf(m, 1),
		lum_obj / n - lum_ring / maxf(m, 1)]


func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "windowed Forward+ only")
	_out = OS.get_environment("TLF_OUT")
	var shot := OS.get_environment("TLF_SHOT")
	var a_override := OS.get_environment("TLF_A")
	var elias_override := OS.get_environment("TLF_ELIAS")
	if _out.is_empty() or not SHOTS.has(shot):
		printerr("set TLF_OUT and TLF_SHOT (%s)" % ", ".join(SHOTS.keys()))
		quit(2)
		return
	for i in TlfPalette.SIZE:
		_palette[_key(TlfPalette.COLORS[i])] = i
	var save = root.get_node_or_null("SaveService")
	if save != null:
		save.save_root = "user://tlf085light_capture_saves"
	_settings = root.get_node_or_null("Settings")
	_settings.lighting_enabled = true
	_ch01 = (load("res://scenes/chapters/ch01/Chapter01.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(_ch01)
	await _frames(30)
	_router = _ch01.get_node("RoomRouter") as RoomRouter
	_player = _ch01.get_node("Player") as Player
	_hud = _player.hud
	var diag := _ch01.call("get_dialogue_box") as DialogueBox
	_router.enter_room(ROOM, &"door_entry_west")
	await _frames(10)
	if diag != null and diag.is_active:
		diag.finish_sequence()
	var lighting := _router.current_room_lighting()
	if lighting == null:
		printerr("maintenance_bay has no metadata/lighting")
		quit(3)
		return
	if not a_override.is_empty():
		lighting.ambient_steps = int(a_override)
	if not elias_override.is_empty():
		lighting.elias_lift_inner = int(elias_override.get_slice("/", 0))
		lighting.elias_lift_outer = int(elias_override.get_slice("/", 1))
	var tag := shot + ("_a" + a_override if not a_override.is_empty() else "")
	var room := _router.current_room
	if shot == "solved":
		var gear := room.get_node("counterweight_gear") as CounterweightGear
		gear.gear_state = &"locked"
		var shutter := room.get_node("fire_shutter") as FireShutter
		shutter.apply_state({"shutter_state": &"raised", "hold_ticks": 0, "passage_blocked": false})
		await _frames(3)
	_router._apply_lighting()
	var pass_node := _router.lighting_pass
	print("ENTRY %s: bake %.2f ms (bake #%d), map %dx%d at %s; A %d, shadows %s, fill %d (effective %d), Elias zone %d/%d radius %s inner %.2f" % [tag,
		pass_node.bake_ms, pass_node.bake_count, pass_node.shade_image.get_width(), pass_node.shade_image.get_height(),
		pass_node.shade_origin, lighting.ambient_steps, lighting.shadows, lighting.fill_lift, lighting.effective_fill(),
		lighting.elias_lift_inner, lighting.elias_lift_outer, lighting.elias_radius, lighting.elias_inner])
	print("VALIDATE %s" % [LightingPass.validate_room(room, lighting, _router.current_room_bounds())])
	var row: Array = SHOTS[shot]
	_player.set_physics_process(false)
	_player.global_position = row[0]
	_router.camera.snap_now()
	_player.sprite.play(row[1])
	_player.sprite.pause()
	_player.sprite.frame = 0
	_hud.hide_feedback()
	_hud.visible = false
	await _frames(5)
	pass_node.apply_room(null, null, null)
	var unlit := await _grab()
	_save(unlit, "%s_unlit" % tag)
	var ms_unlit := await _gpu_ms()
	_router._apply_lighting()
	# the overrides live on the room's resource, which _apply_lighting re-reads
	var lit := await _grab()
	_save(lit, "%s_lit" % tag)
	var entries := pass_node.screen_lights()
	var ms_lit := await _gpu_ms()
	_hud.visible = true
	var hud := await _grab()
	_save(hud, "%s_lit_hud" % tag)
	_hud.visible = false
	_settings.lighting_enabled = false
	var setting_off := await _grab()
	_settings.lighting_enabled = true
	await _frames(2)
	var keep := [lighting.shadows, lighting.fill_lift]
	lighting.shadows = false
	lighting.fill_lift = 0
	_router._apply_lighting()
	var noshadows := await _grab()
	_save(noshadows, "%s_lit_noshadows" % tag)
	lighting.shadows = keep[0]
	lighting.fill_lift = keep[1]
	_router._apply_lighting()
	await _frames(3)
	# per-pixel reference check
	var body := _elias_pixels()
	var elias_c := root.get_canvas_transform() * (_player.global_position + lighting.elias_offset)
	var no_zone: Array[Dictionary] = []
	for e in entries:
		if e.get("room", true):
			no_zone.append(e)
	var r := {"mismatch": 0, "off_palette": 0, "exempt_changed": 0, "non_receiver_changed": 0, "off_floor_changed": 0,
		"body_px": 0, "body_below_2": 0, "capsule": 0, "hud_px": 0, "off_palette_outside_hud": 0}
	var t0 := Time.get_ticks_msec()
	for y in 540:
		for x in 960:
			var src := _index(unlit.get_pixel(x, y))
			var got: int = _palette.get(_key(lit.get_pixel(x, y)), -1)
			if got < 0:
				r["off_palette"] += 1
			if hud.get_pixel(x, y) != lit.get_pixel(x, y):
				r["hud_px"] += 1
			elif _palette.get(_key(hud.get_pixel(x, y)), -1) < 0:
				r["off_palette_outside_hud"] += 1
			var p := Vector2(x, y)
			if got != pass_node.output_index(p, src, entries):
				r["mismatch"] += 1
			var before := _index(noshadows.get_pixel(x, y))
			var changed := got != before
			if src >= lighting.exempt_from and changed:
				r["exempt_changed"] += 1
			if ((LightingPass.RECEIVERS >> src) & 1) == 0 and changed:
				r["non_receiver_changed"] += 1
			if not pass_node.on_floor(p) and changed:
				r["off_floor_changed"] += 1
			var key := Vector2i(x, y)
			if body.has(key):
				r["body_px"] += 1
				if LightingPass.shifted_index(src, 1, 25) != src and pass_node.lift_at(p, src, entries) < lighting.ambient_steps - 1:
					r["body_below_2"] += 1
			elif absf(x - elias_c.x) <= 24 and absf(y - elias_c.y) <= 36:
				if pass_node.output_index(p, src, entries) != pass_node.output_index(p, src, no_zone) and ((LightingPass.RECEIVERS >> src) & 1) == 1:
					r["capsule"] += 1
	r["check_ms"] = Time.get_ticks_msec() - t0
	print("ELIAS %s: feet at screen %s" % [tag, (root.get_canvas_transform() * _player.global_position).round()])
	print("CHECK %s: shader vs reference mismatches %d / 518400 px (%d ms); off-palette (no HUD) %d; off-palette outside the HUD (%d HUD px) %d; setting off == unlit %s" % [
		tag, r["mismatch"], r["check_ms"], r["off_palette"], r["hud_px"], r["off_palette_outside_hud"], setting_off.get_data() == unlit.get_data()])
	print("UNTOUCHED %s (lit without shadows/fill vs lit): exempt changed %d; non-receiver changed %d; off the floor mask changed %d" % [
		tag, r["exempt_changed"], r["non_receiver_changed"], r["off_floor_changed"]])
	print("ELIASBODY %s: body px %d, movable body px below lift A - 1 (k > 1) %d; floor capsule px (zone lifts a floor receiver beyond the room light + fill) %d" % [
		tag, r["body_px"], r["body_below_2"], r["capsule"]])
	for path in OBJECTS:
		print("STRESS %s %s" % [tag, _stress(unlit, lit, path)])
	var frame00 := 0
	for y in 540:
		for x in 960:
			if _index(lit.get_pixel(x, y)) == 0:
				frame00 += 1
	print("FRAME %s: lit pixels at index 00 %d of 518400 (%.1f%%)" % [tag, frame00, 100.0 * frame00 / 518400.0])
	print("TIMING %s: viewport GPU unlit %.3f ms, lit %.3f ms" % [tag, ms_unlit, ms_lit])
	print("TLF-085 LIGHT SHOT DONE %s" % tag)
	quit(0)
