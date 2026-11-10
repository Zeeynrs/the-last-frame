extends "res://tests/support/base_test.gd"

## TLF-083 Part 1 (ADR-026): the palette-indexed lighting pass. Pure rules (ramp table, lift
## bands, information regions), RoomLighting / RoomLight validation (ranges, at most 8 lights inside
## the room bounds), UI layers above the pass, the `lighting_enabled` setting, and the RoomRouter
## hook iso -> side -> iso without leaks or stale lights. The shader itself only runs in a windowed
## build (tools/capture_tlf083.gd compares it pixel by pixel with LightingPass.output_index()).

const GPL := "res://assets/source/ch01/ch01_palette_elysium09.gpl"
const ROOT := "user://tlf_test_lighting_saves"
const SETTINGS_FILE := "user://tlf_test_lighting_settings.cfg"
const ISO_ROOM := &"ch01.room_iso"
const SIDE := &"ch01.room_side"
const FIXTURE := "res://tests/rooms/fixtures/side_room_fixture.tscn"
const ROOMS_DIR := "res://scenes/chapters/ch01/rooms"


# --- helpers -----------------------------------------------------------------------------------

func _own(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_own(child, owner)


static func _light(name: String, pos: Vector2, radius: Vector2, lift_in: int, lift_out: int) -> RoomLight:
	var l := RoomLight.new()
	l.name = name
	l.position = pos
	l.radius = radius
	l.lift_inner = lift_in
	l.lift_outer = lift_out
	return l


static func _ellipse(c: Vector2, r: Vector2, lift_in: int, lift_out: int, mask: int = 0) -> Dictionary:
	return {"kind": 0, "a": Vector4(c.x, c.y, r.x, r.y), "b": Vector4.ZERO, "lift_in": lift_in,
		"lift_out": lift_out, "inner": 0.55, "mask": mask}


static func _quad(p: Array, lift: int, mask: int) -> Dictionary:
	return {"kind": 1, "a": Vector4(p[0].x, p[0].y, p[1].x, p[1].y), "b": Vector4(p[2].x, p[2].y, p[3].x, p[3].y),
		"lift_in": lift, "lift_out": 0, "inner": 0.55, "mask": mask}


## A LightingPass with a lit dummy room (A = `ambient`), not in the tree.
func _pass(ambient: int = 2) -> Dictionary:
	var room := Node2D.new()
	var lit := RoomLighting.new()
	lit.ambient_steps = ambient
	var pass_node := LightingPass.new()
	pass_node.apply_room(room, lit, null)
	return {"pass": pass_node, "room": room, "lit": lit}


func _free_pass(rig: Dictionary) -> void:
	rig["pass"].free()
	rig["room"].free()


## An iso room built in code: a door east, `metadata/lighting` when `lit`, two RoomLights.
func _iso_room(lit: bool) -> PackedScene:
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
	if lit:
		root.set_meta(&"lighting", RoomLighting.new())
		root.add_child(_light("FocalLight", Vector2(300, 150), Vector2(64, 32), 2, 1))
		root.add_child(_light("HelperLight", Vector2(200, 220), Vector2(48, 24), 1, 0))
	for child in root.get_children():
		_own(child, root)
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


## The side fixture, lit with one RoomLight when `lit`.
func _side_room(lit: bool) -> PackedScene:
	var base := load(FIXTURE) as PackedScene
	if not lit:
		return base
	var root := base.instantiate()
	var side_lit := RoomLighting.new()
	side_lit.ambient_steps = 1
	root.set_meta(&"lighting", side_lit)
	var l := _light("SideLight", Vector2(840, 360), Vector2(56, 70), 1, 0)
	root.add_child(l)
	l.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


func _rig(iso_lit: bool, side_lit: bool) -> Dictionary:
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
	var store := SaveStore.new()
	store.name = "SaveService"
	store.save_root = ROOT
	router.add_child(store)
	router.save_service = store
	s.add_child(router)
	s.room_router = router
	router.register_room(ISO_ROOM, _iso_room(iso_lit))
	router.register_room(SIDE, _side_room(side_lit))
	return {"s": s, "router": router, "player": player}


func _walk(rig: Dictionary, presenter_id: StringName) -> void:
	rig["s"].sim_clock.step(20)
	rig["s"].interaction_service.trigger_enter(&"player", presenter_id)
	rig["router"].process_pending()


func _done(rig: Dictionary) -> void:
	free_session(rig["s"])
	var dir := DirAccess.open(ROOT)
	if dir != null:
		for f in dir.get_files():
			dir.remove(f)
		DirAccess.remove_absolute(ROOT)


# --- the palette and the ramp table ------------------------------------------------------------

func test_palette_matches_the_gpl_file() -> void:
	var colours: Array[Color] = []
	var f := FileAccess.open(GPL, FileAccess.READ)
	while f != null and not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or not line[0].is_valid_int():
			continue
		var rgb := line.split("\t")[0].split_floats(" ", false)
		colours.append(Color8(int(rgb[0]), int(rgb[1]), int(rgb[2])))
	_assert_eq(colours.size(), 32, "the .gpl has 32 colours")
	_assert_eq(TlfPalette.COLORS, colours, "TlfPalette.COLORS equals the .gpl, in order")
	for i in 32:
		_assert_eq(TlfPalette.nearest_index(TlfPalette.COLORS[i]), i, "palette colour %d maps to itself" % i)


func test_shift_table_stays_inside_each_ramp() -> void:
	for exempt in [25, 26, 32]:
		var table := LightingPass.shift_table(exempt)
		_assert_eq(table.size(), 128, "exempt %d: 32 x 4 entries" % exempt)
		for index in 32:
			var previous := index
			for k in 4:
				var out := table[index * 4 + k]
				_assert_eq(out, LightingPass.shifted_index(index, k, exempt), "table == shifted_index (%d, k %d)" % [index, k])
				if index >= exempt or k == 0:
					_assert_eq(out, index, "exempt %d: index %d k %d unchanged" % [exempt, index, k])
				else:
					var same_ramp := TlfPalette.ramp_start(out) == TlfPalette.ramp_start(index)
					_assert_true((same_ramp and out <= index) or out == 0 or out == 1,
						"exempt %d: %d k %d -> %d stays in its ramp or falls to 00/01" % [exempt, index, k, out])
					_assert_true(out <= previous or out <= 1, "exempt %d: %d darkens monotonically (k %d)" % [exempt, index, k])
				previous = out
	# spot values from ART_BIBLE §3.1 ramps
	_assert_eq(LightingPass.shifted_index(8, 2, 25), 6, "ceramic mid 08 two steps -> 06")
	_assert_eq(LightingPass.shifted_index(6, 1, 25), 1, "ceramic 06 one step below its ramp -> 01")
	_assert_eq(LightingPass.shifted_index(6, 2, 25), 0, "ceramic 06 two steps below -> 00")
	_assert_eq(LightingPass.shifted_index(2, 2, 25), 0, "terrazzo 02 two steps -> 00")
	_assert_eq(LightingPass.shifted_index(24, 2, 25), 22, "dado 24 darkens to 22 (24 is not exempt)")
	_assert_eq(LightingPass.shifted_index(25, 3, 25), 25, "25 (tactile, watch, clock mid) never shifts")
	_assert_eq(LightingPass.shifted_index(29, 3, 25), 29, "29 (Rewind / UI cyan) never shifts")


# --- validation --------------------------------------------------------------------------------

func test_room_lighting_ranges() -> void:
	var lit := RoomLighting.new()
	_assert_eq(lit.validate(), PackedStringArray(), "defaults are valid (A 2, exempt 25, dither off)")
	_assert_eq(lit.exempt_from, 25, "default exempt_from 25 (Sol, TLF-082)")
	_assert_false(lit.dither, "dither off by default")
	var cases := [
		["ambient_steps", 4], ["ambient_steps", -1], ["exempt_from", 24], ["dither", true],
		["elias_lift_outer", 3], ["elias_radius", Vector2(0, 40)], ["elias_inner", 0.0],
	]
	for c in cases:
		var bad := RoomLighting.new()
		bad.set(c[0], c[1])
		_assert_false(bad.validate().is_empty(), "%s = %s is rejected" % [c[0], c[1]])
	# The Elias zone's inner band covers his 32 x 48 sprite (centre (0,-20), corners at +-16, +-24).
	var r := lit.elias_radius * lit.elias_inner
	_assert_true(pow(16.0 / r.x, 2) + pow(24.0 / r.y, 2) <= 1.0, "default Elias inner band (%s) covers the sprite" % r)


func test_room_light_validation() -> void:
	var ok := _light("Ok", Vector2.ZERO, Vector2(64, 32), 2, 1)
	_assert_eq(ok.validate(), PackedStringArray(), "a 2/1 ellipse is valid")
	var cases := [["radius", Vector2(0, 32)], ["lift_outer", 3], ["lift_inner", 4], ["inner", 0.0], ["only_indices", PackedInt32Array([40])]]
	for c in cases:
		var bad := _light("Bad", Vector2.ZERO, Vector2(64, 32), 2, 1)
		bad.set(c[0], c[1])
		_assert_false(bad.validate().is_empty(), "%s = %s is rejected" % [c[0], c[1]])
		bad.free()
	var q := RoomLight.new()
	q.shape = RoomLight.Shape.QUAD
	q.quad = PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	_assert_false(q.validate().is_empty(), "a quad needs 4 points")
	q.quad = PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(2, 2), Vector2(0, 10)])
	_assert_false(q.validate().is_empty(), "a concave quad is rejected")
	q.quad = PackedVector2Array([Vector2(0, 0), Vector2(16, -8), Vector2(16, 8), Vector2(0, 16)])
	_assert_eq(q.validate(), PackedStringArray(), "a sheared (wall-plane) quad is valid")
	q.only_indices = PackedInt32Array([24, 22])
	_assert_eq(q.index_mask(), (1 << 24) | (1 << 22), "index mask bits")
	q.free()
	ok.free()


func test_room_validation_limits_and_bounds() -> void:
	var room := Node2D.new()
	room.name = "LimitRoom"
	var bounds := Rect2(0, 0, 400, 300)
	var lit := RoomLighting.new()
	for i in 8:
		room.add_child(_light("L%d" % i, Vector2(40 + i * 40, 150), Vector2(32, 16), 1, 0))
	_assert_eq(LightingPass.validate_room(room, lit, bounds), PackedStringArray(), "8 lights inside the bounds: valid")
	room.add_child(_light("L8", Vector2(380, 40), Vector2(32, 16), 1, 0))
	var errors := LightingPass.validate_room(room, lit, bounds)
	_assert_eq(errors.size(), 1, "9 lights: one error (%s)" % [errors])
	room.get_child(8).free()
	room.get_child(0).position = Vector2(-50, 150)
	errors = LightingPass.validate_room(room, lit, bounds)
	_assert_eq(errors.size(), 1, "a light outside the room bounds: one error (%s)" % [errors])
	var pass_node := LightingPass.new()
	room.get_child(0).position = Vector2(40, 150)
	for i in 3:
		room.add_child(_light("Extra%d" % i, Vector2(100, 100), Vector2(32, 16), 1, 0))
	pass_node.apply_room(room, lit, null)
	_assert_eq(pass_node.lights.size(), LightingPass.MAX_LIGHTS, "the pass uses at most 8 room lights")
	pass_node.free()
	room.free()


func test_every_lit_ch01_room_validates() -> void:
	var dir := DirAccess.open(ROOMS_DIR)
	_assert_true(dir != null, "rooms folder")
	var lit_rooms := 0
	var s := make_session()
	for file in dir.get_files():
		if not file.ends_with(".tscn"):
			continue
		var scene := load(ROOMS_DIR.path_join(file)) as PackedScene
		var state := scene.get_state()
		var has_lighting := false
		for p in state.get_node_property_count(0):
			if state.get_node_property_name(0, p) == &"metadata/lighting":
				has_lighting = true
		if not has_lighting:
			continue
		lit_rooms += 1
		var room := scene.instantiate()
		s.add_child(room)
		var shape := room.get_meta(&"room_shape") as RoomShape if room.has_meta(&"room_shape") else null
		var bounds := shape.bounds_px() if shape != null else RoomCamera.LEGACY_SCREEN
		var errors := LightingPass.validate_room(room, room.get_meta(&"lighting") as RoomLighting, bounds)
		_assert_eq(errors, PackedStringArray(), "%s lighting is valid" % file)
		s.remove_child(room)
		room.free()
	print("  INFO: lit rooms in %s: %d" % [ROOMS_DIR, lit_rooms])
	free_session(s)


# --- the lift rules ----------------------------------------------------------------------------

func test_ellipse_bands_and_ambient() -> void:
	var rig := _pass(2)
	var p: LightingPass = rig["pass"]
	var e: Array[Dictionary] = [_ellipse(Vector2(100.5, 100.5), Vector2(40, 20), 2, 1)]
	_assert_eq(p.lift_at(Vector2(100, 100), 8, e), 2, "centre: inner lift 2")
	_assert_eq(p.output_index(Vector2(100, 100), 8, e), 8, "A 2 - lift 2 = k 0: the art is unchanged")
	_assert_eq(p.output_index(Vector2(130, 100), 8, e), 7, "outer band (d 0.75): lift 1, k 1")
	_assert_eq(p.output_index(Vector2(150, 100), 8, e), 6, "outside: k 2")
	_assert_eq(p.output_index(Vector2(100, 125), 8, e), 6, "the ellipse is 2:1 (y radius 20)")
	rig["lit"].ambient_steps = 0
	_assert_eq(p.output_index(Vector2(150, 100), 8, e), 8, "A 0: nothing darkens")
	_free_pass(rig)


func test_lights_do_not_add_up() -> void:
	var rig := _pass(3)
	var p: LightingPass = rig["pass"]
	var e: Array[Dictionary] = [_ellipse(Vector2(100.5, 100.5), Vector2(40, 40), 1, 1), _ellipse(Vector2(110.5, 100.5), Vector2(40, 40), 1, 1)]
	_assert_eq(p.lift_at(Vector2(105, 100), 9, e), 1, "two lift-1 lights overlap: lift 1, not 2")
	_assert_eq(p.output_index(Vector2(105, 100), 9, e), 7, "A 3 - 1 = k 2: 09 -> 07")
	_free_pass(rig)


## The departure-board information region (index 24 only) restores the glyphs and nothing else:
## not the floor inside it, not the dado (also 24) outside it (TLF-083 Part 1 item 3).
func test_information_region_restores_only_its_indices() -> void:
	var rig := _pass(2)
	var p: LightingPass = rig["pass"]
	var board := [Vector2(64, 60), Vector2(160, 12), Vector2(160, 52), Vector2(64, 100)]   # a sheared W-wall face
	var e: Array[Dictionary] = [_quad(board, 2, 1 << 24)]
	_assert_eq(p.output_index(Vector2(100, 60), 24, e), 24, "LED glyph (24) on the board face: unchanged")
	_assert_eq(p.output_index(Vector2(100, 60), 23, e), 1, "board pixel of another index (23): darkened like the room (below ramp 5 -> 01)")
	_assert_eq(p.output_index(Vector2(100, 60), 2, e), 0, "floor index under the region: darkened (k 2)")
	_assert_eq(p.output_index(Vector2(100, 120), 24, e), 22, "dado 24 below the board: darkened (24 -> 22)")
	_assert_eq(p.output_index(Vector2(40, 60), 24, e), 22, "24 left of the board: darkened")
	_assert_eq(p.output_index(Vector2(100, 60), 25, e), 25, "25 never shifts")
	_free_pass(rig)


func test_screen_positions_follow_the_camera_in_whole_pixels() -> void:
	var room := Node2D.new()
	room.add_child(_light("Lamp", Vector2(300.4, 200.6), Vector2(40, 20), 2, 1))
	var q := RoomLight.new()
	q.name = "Board"
	q.shape = RoomLight.Shape.QUAD
	q.position = Vector2(100, 100)
	q.quad = PackedVector2Array([Vector2(0, 0), Vector2(16, -8), Vector2(16, 8), Vector2(0, 16)])
	q.only_indices = PackedInt32Array([24])
	room.add_child(q)
	_tree().root.add_child(room)
	var cam := Camera2D.new()
	cam.position = Vector2(500, 300)
	_tree().root.add_child(cam)
	cam.make_current()
	var pass_node := LightingPass.new()
	_tree().root.add_child(pass_node)
	pass_node.apply_room(room, RoomLighting.new(), null)
	await physics_frames(2)
	var xf := _tree().root.get_canvas_transform()
	var entries := pass_node.screen_lights()
	_assert_eq(entries.size(), 2, "two room lights; no player, no Elias zone")
	var expected := (xf * Vector2(300.4, 200.6)).round()
	_assert_eq(Vector2(entries[0]["a"].x, entries[0]["a"].y), expected, "ellipse centre through the canvas transform, whole pixels")
	_assert_true(expected != Vector2(300, 201), "the camera moved the light on screen (%s)" % expected)
	_assert_eq(Vector2(entries[1]["a"].x, entries[1]["a"].y), (xf * Vector2(100, 100)).round(), "quad point through the canvas transform")
	_assert_eq(entries[1]["mask"], 1 << 24, "quad keeps its index mask")
	pass_node.free()
	cam.free()
	room.free()


# --- layers and the setting ----------------------------------------------------------------------

func test_every_ui_layer_is_above_the_pass() -> void:
	var hud := (load("res://scenes/ui/HUD.tscn") as PackedScene).instantiate() as CanvasLayer
	_assert_true(hud.layer > LightingPass.LAYER, "HUD layer %d above the pass (%d)" % [hud.layer, LightingPass.LAYER])
	_assert_eq(hud.layer, 2, "HUD on layer 2 (ADR-026)")
	hud.free()
	var checked := 0
	var stack := ["res://scenes"]
	while not stack.is_empty():
		var path: String = stack.pop_back()
		var d := DirAccess.open(path)
		if d == null:
			continue
		for sub in d.get_directories():
			stack.append(path.path_join(sub))
		for file in d.get_files():
			if not file.ends_with(".tscn"):
				continue
			var state := (load(path.path_join(file)) as PackedScene).get_state()
			for i in state.get_node_count():
				if state.get_node_type(i) != &"CanvasLayer":
					continue
				var layer := 1
				for p in state.get_node_property_count(i):
					if state.get_node_property_name(i, p) == &"layer":
						layer = int(state.get_node_property_value(i, p))
				checked += 1
				_assert_true(layer > LightingPass.LAYER, "%s/%s: CanvasLayer %s layer %d above the pass" % [path, file, state.get_node_name(i), layer])
	_assert_true(checked >= 8, "found the UI CanvasLayers (%d)" % checked)
	var router_src := FileAccess.get_file_as_string("res://scripts/core/scene_router.gd")
	_assert_true(router_src.contains("_complete_hint.layer = 101"), "SceneRouter's completion hint stays on layer 101")


func test_setting_hides_the_pass_and_reduced_effects_keeps_it() -> void:
	var settings := _tree().root.get_node_or_null("Settings")
	_assert_true(settings != null and "lighting_enabled" in settings, "Settings has lighting_enabled")
	var was_enabled: bool = settings.lighting_enabled
	var was_reduced: bool = settings.reduced_effects
	settings.lighting_enabled = true
	var room := Node2D.new()
	_tree().root.add_child(room)
	var pass_node := LightingPass.new()
	_tree().root.add_child(pass_node)
	pass_node.apply_room(room, RoomLighting.new(), null)
	_assert_true(pass_node.visible, "lit room, setting on: the pass is visible")
	settings.lighting_enabled = false
	_assert_false(pass_node.visible, "setting off: the pass is hidden")
	settings.lighting_enabled = true
	_assert_true(pass_node.visible, "setting on again: visible")
	settings.reduced_effects = true
	_assert_true(pass_node.visible, "reduced_effects keeps the static lighting")
	pass_node.apply_room(room, null, null)
	_assert_false(pass_node.visible, "unlit room: hidden")
	settings.reduced_effects = was_reduced
	settings.lighting_enabled = was_enabled
	pass_node.free()
	room.free()


func test_lighting_enabled_is_saved_with_the_settings() -> void:
	var script := load("res://scripts/settings/settings.gd")
	var a: Node = script.new()
	a.settings_path = SETTINGS_FILE
	_assert_true(a.lighting_enabled, "on by default")
	a.lighting_enabled = false
	_assert_eq(a.save_settings(), OK, "saved to the scratch settings file")
	var b: Node = script.new()
	b.settings_path = SETTINGS_FILE
	b.load_settings()
	_assert_false(b.lighting_enabled, "loaded back off")
	b.reset_to_defaults()
	_assert_true(b.lighting_enabled, "reset_to_defaults turns it on")
	a.free()
	b.free()
	DirAccess.remove_absolute(SETTINGS_FILE)
	_assert_false(FileAccess.file_exists(SETTINGS_FILE), "scratch settings file removed")


# --- the router hook ---------------------------------------------------------------------------

func test_unlit_rooms_create_no_pass() -> void:
	var rig := _rig(false, false)
	var router: RoomRouter = rig["router"]
	router.enter_room(ISO_ROOM, &"door_e")
	_walk(rig, &"ch01.room_iso.door_e")
	_assert_eq(router.current_room_id, SIDE, "in the side room")
	_assert_true(router.lighting_pass == null, "no lit room entered: no pass exists (today's look)")
	_done(rig)


func test_router_iso_side_iso_without_leaks_or_stale_lights() -> void:
	var rig := _rig(true, true)
	var router: RoomRouter = rig["router"]
	router.enter_room(ISO_ROOM, &"door_e")
	var pass_node := router.lighting_pass
	_assert_true(pass_node != null and pass_node.visible, "lit iso room: the pass is created and visible")
	_assert_eq(pass_node.layer, LightingPass.LAYER, "pass on layer 1")
	await physics_frames(2)
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for round in 3:
		_walk(rig, &"ch01.room_iso.door_e")
		_assert_eq(router.current_view_mode(), ViewMode.SIDE, "round %d: side" % round)
		_assert_true(router.lighting_pass == pass_node, "round %d: the same pass instance" % round)
		_assert_eq(pass_node.room, router.current_room, "round %d: the pass lights the current (side) room" % round)
		_assert_eq(pass_node.lights.size(), 1, "round %d: the side room's one light" % round)
		_assert_true(pass_node.lights[0].get_parent() == router.current_room, "round %d: no stale light from the iso room" % round)
		_assert_eq(pass_node.lighting.ambient_steps, 1, "round %d: the side room's A 1" % round)
		_walk(rig, &"ch01.room_side.door_w")
		_assert_eq(router.current_view_mode(), ViewMode.ISO, "round %d: iso" % round)
		_assert_eq(pass_node.lights.size(), 2, "round %d: the iso room's two lights" % round)
		for l in pass_node.lights:
			_assert_true(is_instance_valid(l) and l.get_parent() == router.current_room, "round %d: iso light %s is current" % [round, l.name])
		_assert_eq(pass_node.screen_lights().size(), 3, "round %d: two lights + the Elias zone" % round)
		await physics_frames(1)
	_assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, "no orphan nodes after 3 round trips")
	# an unlit room hides the pass and drops every light
	router.register_room(SIDE, _side_room(false))
	_walk(rig, &"ch01.room_iso.door_e")
	_assert_false(pass_node.visible, "unlit side room: the pass is hidden")
	_assert_eq(pass_node.lights.size(), 0, "unlit side room: no lights kept")
	_assert_true(pass_node.screen_lights().is_empty(), "unlit side room: nothing to draw")
	_done(rig)
