extends SceneTree

## TLF-084 round 2 proof (Fable P2-1, P2-3, P3) for ch01.concourse_west and the side Mira memory.
## Run it only in a scratch copy with a renamed config/name (Chapter01 writes a playtest log and
## autosaves), windowed Forward+:
##   TLF_OUT=<dir> TLF_SHOT=<arrival|gate|dials|east|side|gate_open|bake> [TLF_VARIANT=a2 (side only)]
##   godot --path . --resolution 960x540 -s res://tools/capture_tlf084r2.gd
## Per shot it saves (HUD hidden unless named) unlit, lit_shadows (round 2 as shipped),
## lit_shadows_hud, setting_off, lit_adr026 (shadows off, no fill), and lit_r1_cpu: the round 1
## rule (8f7cb2d: k = clamp(A - lift + shade, 0, 3), index-only receivers, fill not capped) rebuilt
## on the CPU from the same unlit frame (compared with the P2 pack's lit_shadows afterwards). It prints:
##  - shader vs LightingPass.output_index() on the unlit frame, every pixel; off-palette; setting off;
##  - ADR-026 lit vs round 2: information, exempt, non-receiver and off-floor pixels changed (all 0);
##  - per floor pool (core / band): shaded texels, and how many of them show (output differs from the
##    same pixel without shade) under round 1 and round 2 (P2-1);
##  - fill pixels under round 1 and round 2, on and off the floor mask (P2-3);
##  - GPU time and bake time.
## gate_open: the gate shot with CH1-PZ-001 opened while Elias is in the room (P3 rebake).
## TLF_SHOT=side lights the side Mira memory at runtime (A 1, shadows, fill 1, one RoomLight), as in
## Part 2; TLF_VARIANT=a2 shoots it at A 2 so the fill is applied and the deck mask shows.
## TLF_SHOT=bake enters every ch01 room and times ShadeBaker.bake() (map + floor mask).

const ROOM := &"ch01.concourse_west"
const SHOTS := {
	"arrival": [Vector2(224, 144), "idle_se"],
	"gate": [Vector2(298, 198), "idle_e"],
	"gate_open": [Vector2(298, 198), "idle_e"],
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
		printerr("TIMEOUT: capture_tlf084r2 exceeded 110 s")
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


## Round 1 (8f7cb2d) shade at `p`: the map texel or Elias's contact, on every receiver index (no
## floor mask), none in information regions.
func _shade_r1(pass_node: LightingPass, p: Vector2, index: int, terms: Dictionary) -> int:
	if not pass_node.shadows_active() or ((LightingPass.RECEIVERS >> index) & 1) == 0 or terms["info"]:
		return 0
	var t := pass_node._texel(p)
	var img := pass_node.shade_image
	var s := 0
	if t.x >= 0 and t.y >= 0 and t.x < img.get_width() and t.y < img.get_height():
		s = img.get_pixel(t.x, t.y).r8
	var c := pass_node.elias_contact()
	if ((p.floor() + Vector2(0.5, 0.5) - Vector2(c.x, c.y)) / Vector2(c.z, c.w)).length() < 1.0:
		s = maxi(s, 1)
	return s


## Round 1 lift: the fill on every receiver index, not capped at A - 1.
func _lift_r1(lighting: RoomLighting, index: int, terms: Dictionary, fill: bool) -> int:
	var lift: int = terms["lift"]
	if not fill or lighting.fill_lift <= 0 or ((LightingPass.RECEIVERS >> index) & 1) == 0:
		return lift
	if lighting.fill_mode == RoomLighting.FillMode.ADD:
		return maxi(lift, int(terms["room_lift"]) + lighting.fill_lift)
	return lift if terms["clear"] else maxi(lift, lighting.fill_lift)


func _check(unlit: Image, shadows: Image, hud: Image, adr026: Image, pass_node: LightingPass,
		entries: Array[Dictionary]) -> Dictionary:
	var dials := _quad_screen("DialsInfo")
	var validator := _quad_screen("ValidatorInfo")
	var lighting := pass_node.lighting
	var a := lighting.ambient_steps
	var ex := lighting.exempt_from
	var r := {"mismatch": 0, "off_palette": 0, "off_palette_outside_hud": 0, "hud_px": 0, "info_px": 0, "info_changed": 0,
		"exempt_changed": 0, "non_receiver_changed": 0, "off_floor_changed": 0, "floor_lifted": 0, "floor_darkened": 0,
		"fill_r1": 0, "fill_r1_off_floor": 0, "fill_r2": 0, "fill_r2_off_floor": 0, "shade_r1_px": 0, "shade_r2_px": 0}
	# floor pools: room lights that lift floor indices (ellipses), by name
	var pools := {}
	for i in pass_node.lights.size():
		var e: Dictionary = entries[i]
		if e["kind"] == 0 and (int(e["mask"]) == 0 or (int(e["mask"]) & LightingPass.RECEIVERS) != 0):
			pools[i] = {"name": String(pass_node.lights[i].name), "core_shaded": 0, "core_r1": 0, "core_r2": 0,
				"band_shaded": 0, "band_r1": 0, "band_r2": 0}
	var r1 := Image.create(unlit.get_width(), unlit.get_height(), false, Image.FORMAT_RGBA8)
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
			var terms := pass_node.light_terms(p, src, entries)
			var floor := pass_node.on_floor(p)
			# round 2 (the shipped rule, LightingPass) and its parts
			var lift2 := pass_node._lift_with_fill(terms, src, floor)
			var shade2 := pass_node._shade(p, src, terms, floor) if pass_node.shadows_active() else 0
			var k2 := clampi(maxi(a - lift2, 0) + shade2, 0, 3)
			var k2_noshade := clampi(a - lift2, 0, 3)
			var k2_nofill := clampi(maxi(a - int(terms["lift"]), 0) + shade2, 0, 3)
			var want := LightingPass.shifted_index(src, k2, ex)
			if want != pass_node.output_index(p, src, entries):
				r["mismatch"] += 1000000  # the pieces above must agree with output_index
			if got != want:
				r["mismatch"] += 1
			# round 1, rebuilt
			var lift1 := _lift_r1(lighting, src, terms, true)
			var shade1 := _shade_r1(pass_node, p, src, terms)
			var k1 := clampi(a - lift1 + shade1, 0, 3)
			var k1_noshade := clampi(a - lift1, 0, 3)
			var k1_nofill := clampi(a - int(terms["lift"]) + shade1, 0, 3)
			var out1 := LightingPass.shifted_index(src, k1, ex)
			r1.set_pixel(x, y, TlfPalette.COLORS[out1])
			var vis1 := out1 != LightingPass.shifted_index(src, k1_noshade, ex)
			var vis2 := want != LightingPass.shifted_index(src, k2_noshade, ex)
			if vis1:
				r["shade_r1_px"] += 1
			if vis2:
				r["shade_r2_px"] += 1
			if out1 != LightingPass.shifted_index(src, k1_nofill, ex):
				r["fill_r1"] += 1
				if not floor:
					r["fill_r1_off_floor"] += 1
			if want != LightingPass.shifted_index(src, k2_nofill, ex):
				r["fill_r2"] += 1
				if not floor:
					r["fill_r2_off_floor"] += 1
			if shade2 > 0 or shade1 > 0:
				for i in pools:
					var e: Dictionary = entries[i]
					var av: Vector4 = e["a"]
					var d := ((p + Vector2(0.5, 0.5) - Vector2(av.x, av.y)) / Vector2(av.z, av.w)).length()
					if d >= 1.0:
						continue
					var part := "core" if d < float(e["inner"]) else "band"
					pools[i][part + "_shaded"] += 1
					if vis1:
						pools[i][part + "_r1"] += 1
					if vis2:
						pools[i][part + "_r2"] += 1
			var before := _index(adr026.get_pixel(x, y))
			var changed := got != before
			if src >= ex and changed:
				r["exempt_changed"] += 1
			if ((LightingPass.RECEIVERS >> src) & 1) == 0 and changed:
				r["non_receiver_changed"] += 1
			if not floor and changed:
				r["off_floor_changed"] += 1
			if changed and src < 6:
				if got > before:
					r["floor_lifted"] += 1
				else:
					r["floor_darkened"] += 1
			if src in INFO_IDX and not dials.is_empty():
				var centre := p + Vector2(0.5, 0.5)
				if Geometry2D.is_point_in_polygon(centre, dials) or Geometry2D.is_point_in_polygon(centre, validator):
					r["info_px"] += 1
					if changed:
						r["info_changed"] += 1
	r["check_ms"] = Time.get_ticks_msec() - t0
	r["pools"] = pools.values()
	r["r1_image"] = r1
	return r


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
		var floor_px := 0
		for v in first["floor"].get_data():
			floor_px += v
		print("BAKE %s: first %.2f ms, median %.2f ms, max %.2f ms of 20 more; %d polygons, %d ellipses, map %dx%d, floor mask %d px" % [id,
			first["ms"], times[10], times[19], first["polys"], first["ellipses"], first["image"].get_width(),
			first["image"].get_height(), floor_px])


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
		save.save_root = "user://tlf084r2_capture_saves"
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
		print("TLF-084 R2 SHOT DONE bake")
		quit(0)
		return
	var tag := shot + ("_" + variant if not variant.is_empty() else "")
	if shot == "side":
		_router.enter_room(&"ch01.side_mira_memory")
		await _frames(10)
		var side_lit := RoomLighting.new()
		side_lit.ambient_steps = 2 if variant == "a2" else 1
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
	print("ENTRY %s: bake at room entry %.2f ms (bake #%d), map %dx%d at %s; scene: A %d, shadows %s, fill %d (effective %d), fill_mode %s" % [tag,
		pass_node.bake_ms, pass_node.bake_count, pass_node.shade_image.get_width(), pass_node.shade_image.get_height(),
		pass_node.shade_origin, lighting.ambient_steps, lighting.shadows, lighting.fill_lift, lighting.effective_fill(),
		RoomLighting.FillMode.keys()[lighting.fill_mode]])
	print("VALIDATE %s" % [LightingPass.validate_room(room, lighting, _router.current_room_bounds())])
	if shot == "gate_open":
		var gate := room.get_node("turnstile_gate") as TurnstileGate
		var bakes := pass_node.bake_count
		var before := pass_node.shade_image.get_data()
		gate.apply_state({"arm_state": &"open", "passage_blocked": false})
		await _frames(3)
		var fresh := ShadeBaker.bake(room as Node2D)
		print("GATE %s: opened in the room; bakes %d -> %d; map changed %s; map == fresh bake of the open gate %s" % [tag, bakes,
			pass_node.bake_count, pass_node.shade_image.get_data() != before, pass_node.shade_image.get_data() == fresh["image"].get_data()])
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
	_router._apply_lighting()
	var shadows := await _grab()
	_save(shadows, "%s_lit_shadows" % tag)
	var entries := pass_node.screen_lights()
	var ms_shadows := await _gpu_ms()
	_hud.visible = true
	var hud := await _grab()
	_save(hud, "%s_lit_shadows_hud" % tag)
	_hud.visible = false
	_settings.lighting_enabled = false
	var setting_off := await _grab()
	_save(setting_off, "%s_setting_off" % tag)
	_settings.lighting_enabled = true
	await _frames(2)
	var keep := [lighting.shadows, lighting.fill_lift]
	lighting.shadows = false
	lighting.fill_lift = 0
	_router._apply_lighting()
	var adr026 := await _grab()
	_save(adr026, "%s_lit_adr026" % tag)
	var ms_adr026 := await _gpu_ms()
	lighting.shadows = keep[0]
	lighting.fill_lift = keep[1]
	_router._apply_lighting()
	await _frames(3)
	var r := _check(unlit, shadows, hud, adr026, pass_node, entries)
	_save(r["r1_image"], "%s_lit_r1_cpu" % tag)
	var at := (root.get_canvas_transform() * _player.global_position).round()
	print("ELIAS %s: feet at screen %s" % [tag, at])
	print("CHECK %s: shader vs reference mismatches %d / %d px (%d ms); off-palette (no HUD) %d; off-palette outside the HUD (%d HUD px) %d; setting off == unlit %s" % [
		tag, r["mismatch"], unlit.get_width() * unlit.get_height(), r["check_ms"], r["off_palette"], r["hud_px"],
		r["off_palette_outside_hud"], setting_off.get_data() == unlit.get_data()])
	print("UNTOUCHED %s (ADR-026 lit vs round 2): information pixels changed %d of %d; exempt (>= %d) changed %d; non-receiver changed %d; off the floor mask changed %d" % [
		tag, r["info_changed"], r["info_px"], lighting.exempt_from, r["exempt_changed"], r["non_receiver_changed"], r["off_floor_changed"]])
	print("FLOOR %s: floor pixels lifted %d, darkened %d (ADR-026 lit vs round 2)" % [tag, r["floor_lifted"], r["floor_darkened"]])
	print("FILL %s: pixels the fill changes: round 1 %d (%d off the floor mask), round 2 %d (%d off the floor mask)" % [tag,
		r["fill_r1"], r["fill_r1_off_floor"], r["fill_r2"], r["fill_r2_off_floor"]])
	print("SHADE %s: pixels where the shade shows: round 1 %d, round 2 %d" % [tag, r["shade_r1_px"], r["shade_r2_px"]])
	for pool in r["pools"]:
		print("POOL %s %s: core shaded %d, showing r1 %d / r2 %d; band shaded %d, showing r1 %d / r2 %d" % [tag, pool["name"],
			pool["core_shaded"], pool["core_r1"], pool["core_r2"], pool["band_shaded"], pool["band_r1"], pool["band_r2"]])
	print("TIMING %s: viewport GPU unlit %.3f ms, ADR-026 lit %.3f ms, round 2 lit+shadows %.3f ms (delta vs ADR-026 %+.3f ms)" % [tag,
		ms_unlit, ms_adr026, ms_shadows, ms_shadows - ms_adr026])
	print("TLF-084 R2 SHOT DONE %s" % tag)
	quit(0)
