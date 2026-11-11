extends SceneTree

## TLF-084 Part 2 proof (ADR-027 D.7) for ch01.concourse_west. Run it only in a scratch copy with a
## renamed config/name (Chapter01 writes a playtest log and autosaves), windowed Forward+:
##   TLF_OUT=<dir> TLF_SHOT=<arrival|gate|dials|east|side|bake> [TLF_VARIANT=<clear15|clear10>]
##   godot --path . --resolution 960x540 -s res://tools/capture_tlf084.gd
## The room's lighting, shadows and fill come from its scene. Per shot it saves (HUD hidden unless
## named): unlit, lit_adr026 (the TLF-083 look: shadows off, no fill), lit_shadows (ADR-027) and
## lit_shadows_hud, setting_off; and prints:
##  - shader output vs LightingPass.output_index() on the unlit frame, every pixel;
##  - off-palette pixels (no HUD) and outside the HUD (HUD frame); setting off == unlit (bytes);
##  - lit_adr026 vs lit_shadows: information pixels, exempt (>= 25) pixels and non-receiver pixels
##    changed (all must be 0), floor pixels lifted (fill) and darkened (shade), Elias pixels changed;
##  - viewport GPU time unlit / ADR-026 / ADR-027, and the room's bake time at entry.
## Variants (fill rule comparison, scratch only; the room ships fill_mode ADD): clear15 = fill_mode
## CLEAR with fill_clear 1.5 (a dark surround out to 1.5 pool radii), clear10 = CLEAR with 1.0.
## TLF_SHOT=side lights the side-view Mira memory at runtime (A 1, shadows, fill 1, one RoomLight);
## TLF_SHOT=bake enters every ch01 room and times ShadeBaker.bake() (first call and 20 more).
## Greyscale copies and x2 crops are made afterwards from the saved PNGs (tools outside Godot).

const ROOM := &"ch01.concourse_west"
const SHOTS := {
	"arrival": [Vector2(224, 144), "idle_se"],
	"gate": [Vector2(298, 198), "idle_e"],
	"dials": [Vector2(576, 216), "idle_ne"],
	"east": [Vector2(608, 336), "idle_se"],
	"side": [Vector2(420, 394), "idle_e"],
	"bake": [],
}
const INFO_IDX := [2, 3, 14, 15, 23, 24]
const ROOMS := [&"ch01.arrival_platform", &"ch01.concourse_west", &"ch01.maintenance_bay", &"ch01.security_crossing",
	&"ch01.waiting_lounge", &"ch01.signal_control", &"ch01.upper_vestibule", &"ch01.vestibule_niche",
	&"ch01.station_atrium", &"ch01.street_exit", &"ch01.side_mira_memory"]

var _ch01: Node2D
var _router: RoomRouter
var _player: Player
var _hud: CanvasLayer
var _settings: Node
var _palette := {}
var _out := ""


func _initialize() -> void:
	create_timer(110.0).timeout.connect(func():
		printerr("TIMEOUT: capture_tlf084 exceeded 110 s")
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


func _gpu_ms(frames: int = 90) -> float:
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
	return _palette.get(_key(c), -1) as int


func _quad_screen(name: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	var light := _router.current_room.get_node_or_null("Lighting/" + name) as RoomLight
	if light == null:
		return out
	var xf := root.get_canvas_transform()
	for q in light.quad:
		out.append((xf * (light.global_transform * q)).round())
	return out


func _check(unlit: Image, shadows: Image, hud: Image, adr026: Image, elias: Image, pass_node: LightingPass,
		entries: Array[Dictionary]) -> Dictionary:
	var dials := _quad_screen("DialsInfo")
	var validator := _quad_screen("ValidatorInfo")
	var r := {"mismatch": 0, "off_palette": 0, "off_palette_outside_hud": 0, "hud_px": 0, "info_px": 0, "info_changed": 0,
		"exempt_changed": 0, "non_receiver_changed": 0, "floor_lifted": 0, "floor_darkened": 0, "elias_px": 0,
		"elias_darkened": 0, "elias_lifted": 0, "shade_px": 0}
	var t0 := Time.get_ticks_msec()
	for y in unlit.get_height():
		for x in unlit.get_width():
			var src := _index(unlit.get_pixel(x, y))
			if src < 0:
				src = TlfPalette.nearest_index(unlit.get_pixel(x, y))
			var got := _index(shadows.get_pixel(x, y))
			if got < 0:
				r["off_palette"] += 1
			if hud.get_pixel(x, y) != shadows.get_pixel(x, y):
				r["hud_px"] += 1
			elif _index(hud.get_pixel(x, y)) < 0:
				r["off_palette_outside_hud"] += 1
			var p := Vector2(x, y)
			if got != pass_node.output_index(p, src, entries):
				r["mismatch"] += 1
			if pass_node.shade_at(p, src, entries) > 0:
				r["shade_px"] += 1
			var before := _index(adr026.get_pixel(x, y))
			var changed := got != before
			if src >= pass_node.lighting.exempt_from and changed:
				r["exempt_changed"] += 1
			if ((LightingPass.RECEIVERS >> src) & 1) == 0 and changed:
				r["non_receiver_changed"] += 1
			if changed and src < 6:
				if got > before:
					r["floor_lifted"] += 1
				else:
					r["floor_darkened"] += 1
			if elias.get_pixel(x, y) != shadows.get_pixel(x, y):
				r["elias_px"] += 1
				if changed:
					r["elias_darkened" if got < before else "elias_lifted"] += 1
			if src in INFO_IDX and not dials.is_empty():
				var centre := p + Vector2(0.5, 0.5)
				if Geometry2D.is_point_in_polygon(centre, dials) or Geometry2D.is_point_in_polygon(centre, validator):
					r["info_px"] += 1
					if changed:
						r["info_changed"] += 1
	r["check_ms"] = Time.get_ticks_msec() - t0
	return r


func _apply_variant(variant: String, _room: Node, lighting: RoomLighting) -> Dictionary:
	var saved := {"fill_clear": lighting.fill_clear, "fill_mode": lighting.fill_mode}
	if variant.begins_with("clear"):
		lighting.fill_mode = RoomLighting.FillMode.CLEAR
		lighting.fill_clear = 1.5 if variant == "clear15" else 1.0
	return saved


func _restore_variant(saved: Dictionary, _room: Node, lighting: RoomLighting) -> void:
	lighting.fill_clear = saved["fill_clear"]
	lighting.fill_mode = saved["fill_mode"]


func _bake_all() -> void:
	for id in ROOMS:
		_router.enter_room(id)
		await _frames(4)
		var room := _router.current_room as Node2D
		var first := ShadeBaker.bake(room)
		var times: Array[float] = []
		for i in 20:
			times.append(ShadeBaker.bake(room)["ms"])
		times.sort()
		print("BAKE %s: first %.2f ms, median %.2f ms, max %.2f ms of 20 more; %d polygons, %d ellipses, map %dx%d" % [id,
			first["ms"], times[10], times[19], first["polys"], first["ellipses"], first["image"].get_width(), first["image"].get_height()])


func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "windowed Forward+ only")
	_out = OS.get_environment("TLF_OUT")
	var shot := OS.get_environment("TLF_SHOT")
	var variant := OS.get_environment("TLF_VARIANT")
	if _out.is_empty() or not SHOTS.has(shot):
		printerr("set TLF_OUT and TLF_SHOT (%s)" % ", ".join(SHOTS.keys()))
		quit(2)
		return
	for i in TlfPalette.SIZE:
		_palette[_key(TlfPalette.COLORS[i])] = i
	var save = root.get_node_or_null("SaveService")
	if save != null:
		save.save_root = "user://tlf084p2_capture_saves"
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
	if shot == "bake":
		await _bake_all()
		print("TLF-084 P2 SHOT DONE bake")
		quit(0)
		return
	var tag := shot + ("_" + variant if not variant.is_empty() else "")
	if shot == "side":
		_router.enter_room(&"ch01.side_mira_memory")
		await _frames(10)
		var side_lit := RoomLighting.new()
		side_lit.ambient_steps = 1
		side_lit.shadows = true
		side_lit.fill_lift = 1
		_router.current_room.set_meta(&"lighting", side_lit)
		var mira := RoomLight.new()
		mira.name = "MiraFocal"
		mira.position = Vector2(780, 360)
		mira.radius = Vector2(56, 48)
		mira.lift_inner = 1
		mira.lift_outer = 0
		_router.current_room.add_child(mira)
		_router._apply_lighting()
	else:
		_router.enter_room(ROOM, &"door_entry_west")
		await _frames(10)
	if diag != null and diag.is_active:
		diag.finish_sequence()
	var pass_node := _router.lighting_pass
	var room := _router.current_room
	var lighting := _router.current_room_lighting()
	print("ENTRY %s: bake at room entry %.2f ms (bake #%d), map %dx%d at %s; scene: A %d, shadows %s, fill %d, fill_mode %s, fill_clear %.2f" % [tag,
		pass_node.bake_ms, pass_node.bake_count, pass_node.shade_image.get_width(), pass_node.shade_image.get_height(),
		pass_node.shade_origin, lighting.ambient_steps, lighting.shadows, lighting.fill_lift,
		RoomLighting.FillMode.keys()[lighting.fill_mode], lighting.fill_clear])
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
	# unlit (the pass cleared)
	pass_node.apply_room(null, null, null)
	var unlit := await _grab()
	_save(unlit, "%s_unlit" % tag)
	var ms_unlit := await _gpu_ms()
	# ADR-027 (the room as shipped, or the variant)
	var saved := _apply_variant(variant, room, lighting)
	print("MODE %s: shot with fill_mode %s, fill_clear %.2f" % [tag, RoomLighting.FillMode.keys()[lighting.fill_mode], lighting.fill_clear])
	_router._apply_lighting()
	var shadows := await _grab()
	_save(shadows, "%s_lit_shadows" % tag)
	var entries := pass_node.screen_lights()
	var ms_shadows := await _gpu_ms()
	_player.sprite.visible = false
	var no_elias := await _grab()
	_player.sprite.visible = true
	_hud.visible = true
	var hud := await _grab()
	_save(hud, "%s_lit_shadows_hud" % tag)
	_hud.visible = false
	_settings.lighting_enabled = false
	var setting_off := await _grab()
	_save(setting_off, "%s_setting_off" % tag)
	_settings.lighting_enabled = true
	await _frames(2)
	# keep the ADR-027 state for the reference check: re-apply it after the ADR-026 frame
	_restore_variant(saved, room, lighting)
	var keep := [lighting.shadows, lighting.fill_lift]
	lighting.shadows = false
	lighting.fill_lift = 0
	_router._apply_lighting()
	var adr026 := await _grab()
	_save(adr026, "%s_lit_adr026" % tag)
	var ms_adr026 := await _gpu_ms()
	lighting.shadows = keep[0]
	lighting.fill_lift = keep[1]
	saved = _apply_variant(variant, room, lighting)
	_router._apply_lighting()
	await _frames(3)
	var r := _check(unlit, shadows, hud, adr026, no_elias, pass_node, entries)
	_restore_variant(saved, room, lighting)
	var at := (root.get_canvas_transform() * _player.global_position).round()
	print("ELIAS %s: feet at screen %s" % [tag, at])
	print("CHECK %s: shader vs reference mismatches %d / %d px (%d ms); off-palette (no HUD) %d; off-palette outside the HUD (%d HUD px) %d; setting off == unlit %s" % [
		tag, r["mismatch"], unlit.get_width() * unlit.get_height(), r["check_ms"], r["off_palette"], r["hud_px"],
		r["off_palette_outside_hud"], setting_off.get_data() == unlit.get_data()])
	print("UNTOUCHED %s (ADR-026 lit vs ADR-027): information pixels changed %d of %d; exempt (>= %d) pixels changed %d; non-receiver pixels changed %d" % [
		tag, r["info_changed"], r["info_px"], lighting.exempt_from, r["exempt_changed"], r["non_receiver_changed"]])
	print("FLOOR %s: floor pixels lifted (fill) %d, darkened %d; pixels with shade > 0 in the frame %d" % [tag, r["floor_lifted"],
		r["floor_darkened"], r["shade_px"]])
	print("ELIAS %s: body pixels %d, darkened %d, lifted %d (ADR-026 lit vs ADR-027)" % [tag, r["elias_px"], r["elias_darkened"], r["elias_lifted"]])
	print("TIMING %s: viewport GPU unlit %.3f ms, ADR-026 lit %.3f ms, ADR-027 lit+shadows %.3f ms (delta vs ADR-026 %+.3f ms)" % [tag,
		ms_unlit, ms_adr026, ms_shadows, ms_shadows - ms_adr026])
	print("TLF-084 P2 SHOT DONE %s" % tag)
	quit(0)
