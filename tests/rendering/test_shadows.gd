extends "res://tests/support/base_test.gd"

## TLF-084 Part 2 (ADR-027): shadows and the floor fill in the ADR-026 pass. The shade map baker
## (scanline rasterizer against a brute-force reference, Concourse West's casters, AO strips and the
## 315 degree key, side view, skips), the pass rules (floor receivers only, information regions and
## exempt indices untouched, k = clamp(A - max(lights, fill) + shade, 0, 3), the fill cleared around
## room pools but not around the Elias zone), Elias's contact ellipse below his body, the setting
## (off: no bake, pass hidden), and the router hook (map rebuilt on every room change, no leaks).
## Round 2 (Fable P2-1, P2-3, P3): k = clamp(max(A - lift, 0) + shade, 0, 3) (shadows read inside
## pools), receivers only on the baked floor mask, the fill at most A - 1, and a rebake when a
## blocker opens or closes in the room.
## The shader runs only in a windowed build: tools/capture_tlf084.gd compares it pixel by pixel
## with LightingPass.output_index().

const ROOT := "user://tlf_test_shadows_saves"
const ISO_ROOM := &"ch01.room_iso"
const SIDE := &"ch01.room_side"
const FIXTURE := "res://tests/rooms/fixtures/side_room_fixture.tscn"
const CONCOURSE := "res://scenes/chapters/ch01/rooms/concourse_west.tscn"
const ROOMS_DIR := "res://scenes/chapters/ch01/rooms"


# --- helpers -----------------------------------------------------------------------------------

func _own(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_own(child, owner)


static func _ellipse(c: Vector2, r: Vector2, lift_in: int, lift_out: int, mask: int = 0, room: bool = true) -> Dictionary:
	return {"kind": 0, "a": Vector4(c.x, c.y, r.x, r.y), "b": Vector4.ZERO, "lift_in": lift_in,
		"lift_out": lift_out, "inner": 0.55, "mask": mask, "room": room}


static func _quad(p: Array, lift: int, mask: int) -> Dictionary:
	return {"kind": 1, "a": Vector4(p[0].x, p[0].y, p[1].x, p[1].y), "b": Vector4(p[2].x, p[2].y, p[3].x, p[3].y),
		"lift_in": lift, "lift_out": 0, "inner": 0.55, "mask": mask, "room": true}


## A LightingPass (not in the tree) lighting a dummy room at A `ambient`, with a constant shade map
## of `shade` over (0,0)-(200,200) when `shade` >= 0 (shadows on), and a floor mask covering
## (0,0)-(600,400) whenever there is a map or a fill.
func _pass(ambient: int, shade: int = -1, fill: int = 0) -> Dictionary:
	var room := Node2D.new()
	var lit := RoomLighting.new()
	lit.ambient_steps = ambient
	lit.fill_lift = fill
	var pass_node := LightingPass.new()
	pass_node.apply_room(room, lit, null)
	if shade >= 0:
		lit.shadows = true
		var img := Image.create(200, 200, false, Image.FORMAT_L8)
		img.fill(Color8(shade, shade, shade))
		pass_node.shade_image = img
		pass_node.shade_origin = Vector2.ZERO
	if shade >= 0 or fill > 0:
		var mask := Image.create(600, 400, false, Image.FORMAT_L8)
		mask.fill(Color8(1, 1, 1))
		pass_node.floor_image = mask
		pass_node.shade_origin = Vector2.ZERO
	return {"pass": pass_node, "room": room, "lit": lit}


func _free_pass(rig: Dictionary) -> void:
	rig["pass"].free()
	rig["room"].free()


static func _inside_convex(p: Vector2, poly: PackedVector2Array) -> bool:
	var pos := true
	var neg := true
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var c := (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
		pos = pos and c >= 0.0
		neg = neg and c <= 0.0
	return pos or neg


## Brute force: every texel centre against every shape (bounding boxes only), maximum value.
static func _reference(bounds: Rect2, polys: Array, ellipses: Array) -> PackedByteArray:
	var w := int(bounds.size.x)
	var h := int(bounds.size.y)
	var o := bounds.position
	var data := PackedByteArray()
	data.resize(w * h)
	for pv in polys:
		var poly: PackedVector2Array = pv[0]
		var box := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			box = box.expand(q)
		for y in range(maxi(int(box.position.y - o.y) - 1, 0), mini(int(box.end.y - o.y) + 2, h)):
			for x in range(maxi(int(box.position.x - o.x) - 1, 0), mini(int(box.end.x - o.x) + 2, w)):
				if _inside_convex(o + Vector2(x + 0.5, y + 0.5), poly):
					data[y * w + x] = maxi(data[y * w + x], pv[1])
	for e in ellipses:
		var c: Vector2 = e[0]
		var r: Vector2 = e[1]
		for y in range(maxi(int(c.y - r.y - o.y) - 1, 0), mini(int(c.y + r.y - o.y) + 2, h)):
			for x in range(maxi(int(c.x - r.x - o.x) - 1, 0), mini(int(c.x + r.x - o.x) + 2, w)):
				var d := ((o + Vector2(x + 0.5, y + 0.5) - c) / r).length()
				if d < 1.0:
					var v := ShadeBaker.CONTACT_CORE if d < ShadeBaker.CONTACT_INNER else ShadeBaker.CONTACT_RIM
					data[y * w + x] = maxi(data[y * w + x], v)
	return data


func _concourse(s: Node) -> Node2D:
	var room := (load(CONCOURSE) as PackedScene).instantiate() as Node2D
	s.add_child(room)
	return room


# --- the baker ---------------------------------------------------------------------------------

func test_rasterizer_matches_a_brute_force_reference() -> void:
	var s := make_session()
	var room := _concourse(s)
	var shapes := ShadeBaker.shapes_for(room)
	var bounds: Rect2 = shapes["bounds"]
	# plus awkward synthetic shapes: a sliver, a shape crossing the map edge, overlapping values
	var polys: Array = shapes["polys"].duplicate()
	polys.append([PackedVector2Array([Vector2(100.3, 50.7), Vector2(180.9, 90.2), Vector2(181.4, 92.6), Vector2(99.8, 52.1)]), 1])
	polys.append([PackedVector2Array([Vector2(20, -30), Vector2(90, 10), Vector2(60, 40), Vector2(-10, 5)]), 2])
	var ellipses: Array = shapes["ellipses"].duplicate()
	ellipses.append([Vector2(bounds.end.x - 3.3, 200.25), Vector2(20.5, 10.25)])
	var img := ShadeBaker.rasterize(bounds, polys, ellipses)
	var ref := _reference(bounds, polys, ellipses)
	var got := img.get_data()
	_assert_eq(img.get_format(), Image.FORMAT_L8, "L8 map")
	_assert_eq(Vector2(img.get_width(), img.get_height()), bounds.size, "one texel per world pixel")
	var mismatch := 0
	var counts := [0, 0, 0]
	for i in ref.size():
		if got[i] != ref[i]:
			mismatch += 1
		if ref[i] < 3:
			counts[ref[i]] += 1
	_assert_eq(mismatch, 0, "scanline map equals the brute-force reference (%d texels)" % ref.size())
	_assert_true(counts[1] > 10000 and counts[2] > 300, "the map has shade 1 (%d) and 2 (%d) texels" % [counts[1], counts[2]])
	var t0 := Time.get_ticks_usec()
	var r := ShadeBaker.bake(room)
	print("  INFO: Concourse West bake %.2f ms (%d polygons, %d ellipses, map %dx%d); bake() call %.0f ms" % [r["ms"],
		r["polys"], r["ellipses"], r["image"].get_width(), r["image"].get_height(), (Time.get_ticks_usec() - t0) / 1000.0])
	free_session(s)


func test_concourse_west_casters_ao_and_the_315_key() -> void:
	var s := make_session()
	var room := _concourse(s)
	var shape := room.get_meta(&"room_shape") as RoomShape
	var names: Array[String] = []
	for g in ShadeBaker.grounded(room, shape):
		names.append(String(room.get_path_to(g["node"])))
	names.sort()
	_assert_eq(names, ["YSort_Actors/ConcourseBench", "n05_courier/Presenter", "n06_red_coat/Footprint/CollisionShape2D",
		"n07_briefcase/Footprint/CollisionShape2D", "n08_father/Footprint/CollisionShape2D", "n09_teen/Footprint/CollisionShape2D",
		"reset_anchor_01/ConsoleSprite", "support_pillar_01/PillarCollision/CollisionShape2D",
		"ticket_validator/ConsoleFootprint/CollisionShape2D", "turnstile_gate/Blocker/CollisionShape2D"],
		"10 grounded casters: statues, gate, pillar once (its wall-layer sprite is its art), validator, console, bench, courier; not the staff door in the E wall")
	var r := ShadeBaker.bake(room)
	var img: Image = r["image"]
	var o: Vector2 = r["origin"]
	var at := func(world: Vector2) -> int:
		var t := Vector2i((world - o).floor())
		return img.get_pixel(t.x, t.y).r8
	_assert_eq(at.call(RoomShape.tile_to_px(Vector2(14, 0.2))), ShadeBaker.AO, "AO strip along the N wall base")
	_assert_eq(at.call(RoomShape.tile_to_px(Vector2(0.2, 8))), ShadeBaker.AO, "AO strip along the W wall base")
	_assert_eq(at.call(RoomShape.tile_to_px(Vector2(14, 0.8))), 0, "nothing 0.8 tile off the N wall")
	_assert_eq(at.call(RoomShape.tile_to_px(Vector2(14, 15.85))), ShadeBaker.AO, "low S edge strip")
	_assert_eq(at.call(Vector2(528, 320)), ShadeBaker.CONTACT_CORE, "contact core under the red-coat statue")
	_assert_eq(at.call(Vector2(528 + 5, 320)), ShadeBaker.CONTACT_RIM, "contact rim at 0.73 of its radius")
	# 315 degree key: the pillar's cast runs to the screen's bottom-right (+x tiles), not up-left
	var foot := RoomShape.px_to_tile(Vector2(416, 288))
	_assert_eq(at.call(RoomShape.tile_to_px(foot + Vector2(1.5, 0))), ShadeBaker.CAST, "pillar cast 1.5 tiles down-right")
	_assert_eq(at.call(RoomShape.tile_to_px(foot + Vector2(-1.5, 0))), 0, "no cast up-left of the pillar")
	_assert_eq(at.call(RoomShape.tile_to_px(foot + Vector2(0, 1.5))), 0, "no cast down-left of the pillar")
	var children := room.get_child_count()
	ShadeBaker.bake(room)
	_assert_eq(room.get_child_count(), children, "baking adds nothing to the room")
	free_session(s)


func test_skip_meta_and_footprints_on_the_floor_edge() -> void:
	var s := make_session()
	var room := _concourse(s)
	var shape := room.get_meta(&"room_shape") as RoomShape
	var before := ShadeBaker.grounded(room, shape).size()
	room.get_node("n06_red_coat").set_meta(ShadeBaker.SKIP_META, true)
	_assert_eq(ShadeBaker.grounded(room, shape).size(), before - 1, "metadata/shade_skip on the statue removes its contact")
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 8)
	cs.shape = rect
	body.add_child(cs)
	body.position = RoomShape.tile_to_px(Vector2(0.1, 8))
	room.add_child(body)
	_assert_eq(ShadeBaker.grounded(room, shape).size(), before - 1, "a footprint 0.1 tile from the W edge casts nothing")
	body.position = RoomShape.tile_to_px(Vector2(5, 8))
	_assert_eq(ShadeBaker.grounded(room, shape).size(), before, "the same footprint inside the floor casts")
	free_session(s)


func test_side_view_band_contacts_and_casts() -> void:
	var root := Node2D.new()
	root.set_meta(&"view_mode", ViewMode.SIDE)
	var side := SideView.new()
	side.floor_y = 394.0
	side.width = 960.0
	root.set_meta(&"side_view", side)
	var crate := Node2D.new()
	crate.position = Vector2(300, 394)
	var spr := Sprite2D.new()
	var tex := ImageTexture.create_from_image(Image.create(20, 40, false, Image.FORMAT_RGBA8))
	spr.texture = tex
	crate.add_child(spr)
	root.add_child(crate)
	var r := ShadeBaker.bake(root)
	var img: Image = r["image"]
	var o: Vector2 = r["origin"]
	var at := func(p: Vector2) -> int:
		return img.get_pixel(int(p.x - o.x), int(p.y - o.y)).r8
	_assert_eq(Vector2(img.get_width(), img.get_height()), side.bounds_px().size, "side map covers the side bounds")
	_assert_eq(at.call(Vector2(600, 394 - 10.5)), ShadeBaker.AO, "AO band where the far wall meets the deck")
	_assert_eq(at.call(Vector2(600, 394 - 14)), 0, "nothing above the band")
	_assert_eq(at.call(Vector2(300, 394)), ShadeBaker.CONTACT_CORE, "contact core on the floor line")
	_assert_eq(at.call(Vector2(300 + 12, 394)), ShadeBaker.CAST, "40 px tall: cast to the right (key 315)")
	_assert_eq(at.call(Vector2(300 - 12, 394)), 0, "no cast to the left")
	root.free()


# --- the pass rules ----------------------------------------------------------------------------

func test_only_floor_receivers_take_shade_and_fill() -> void:
	var rig := _pass(2, 1, 1)
	var p: LightingPass = rig["pass"]
	var e: Array[Dictionary] = []
	for index in TlfPalette.SIZE:
		var floor := index <= 5
		_assert_eq(p.shade_at(Vector2(50, 50), index, e), 1 if floor else 0, "index %02d: shade %s" % [index, "1 (floor)" if floor else "0"])
		_assert_eq(p.fill_at(Vector2(50, 50), index, e), 1 if floor else 0, "index %02d: fill %s" % [index, "1 (floor)" if floor else "0"])
	_assert_eq(p.output_index(Vector2(50, 50), 8, e), 6, "wall 08 at A 2: k 2, no fill, no shade")
	_assert_eq(p.output_index(Vector2(50, 50), 4, e), 2, "floor 04: A 2 - fill 1 + shade 1 = k 2")
	_assert_eq(p.output_index(Vector2(300, 300), 4, e), 3, "floor 04 off the map: k 1 (fill only)")
	_free_pass(rig)


func test_information_regions_and_exempt_indices_take_nothing() -> void:
	var rig := _pass(2, 2, 1)
	var p: LightingPass = rig["pass"]
	var dials := [Vector2(40, 40), Vector2(120, 20), Vector2(120, 80), Vector2(40, 100)]
	var e: Array[Dictionary] = [_quad(dials, 2, (1 << 2) | (1 << 3) | (1 << 24))]
	_assert_eq(p.output_index(Vector2(80, 60), 2, e), 2, "dial face 02 in its information region: unchanged (no shade, no fill)")
	_assert_eq(p.output_index(Vector2(80, 60), 24, e), 24, "dial 24 in the region: unchanged")
	_assert_eq(p.shade_at(Vector2(80, 60), 2, e), 0, "no shade on an information pixel")
	_assert_eq(p.shade_at(Vector2(80, 60), 0, e), 2, "floor 00 inside the region but not one of its indices: shaded")
	_assert_eq(p.output_index(Vector2(80, 60), 4, e), 1, "floor 04 inside the region but not one of its indices: A 2 - fill 1 + shade 2 = k 3 (04 -> 01)")
	for index in range(25, 32):
		_assert_eq(p.output_index(Vector2(150, 150), index, e), index, "exempt %02d never moves under shade 2" % index)
	var region := RoomLight.new()
	region.name = "Info"
	region.shape = RoomLight.Shape.QUAD
	region.quad = PackedVector2Array([Vector2(0, 0), Vector2(16, -8), Vector2(16, 8), Vector2(0, 16)])
	region.only_indices = PackedInt32Array([2, 24])
	region.lift_inner = 0
	_assert_eq(region.validate().size(), 1, "an information region lifting 0 is rejected (the fill could change its pixels)")
	region.lift_inner = 1
	_assert_eq(region.validate(), PackedStringArray(), "lift 1: valid")
	region.free()
	_free_pass(rig)


func test_shade_is_added_after_the_lift() -> void:
	var rig := _pass(1, 1)
	var p: LightingPass = rig["pass"]
	var pool: Array[Dictionary] = [_ellipse(Vector2(100.5, 100.5), Vector2(60, 30), 2, 2)]
	_assert_eq(p.output_index(Vector2(100, 100), 4, pool), 3,
		"A 1, lift 2, shade 1: k = max(1 - 2, 0) + 1 = 1 (r2: the lift is capped at A, the shadow still reads; was k 0)")
	rig["lit"].ambient_steps = 2
	_assert_eq(p.output_index(Vector2(100, 100), 4, pool), 3, "A 2, lift 2, shade 1: k 1 (a shadow reads inside the pool)")
	_assert_eq(p.output_index(Vector2(190, 100), 4, pool), 1, "A 2 outside the pool, shade 1: k 3 (04 -> 01)")
	rig["lit"].ambient_steps = 3
	_assert_eq(p.output_index(Vector2(190, 100), 4, pool), 1, "A 3 + shade 1: k clamps at 3")
	rig["lit"].ambient_steps = 0
	_assert_eq(p.output_index(Vector2(190, 100), 4, pool), 3, "A 0 + shade 1: k 1 (a shadow on unlit-value floor)")
	_free_pass(rig)


func test_shadows_read_inside_the_focal_and_helper_pools() -> void:
	# Fable P2-1: under ADD the focal core is lifted 2 + fill 1 = 3 > A 2, which swallowed shade 1.
	for shade in [1, 2]:
		var rig := _pass(2, shade, 1)
		var p: LightingPass = rig["pass"]
		var floor_mask := 0b111111
		var focal: Array[Dictionary] = [_ellipse(Vector2(100.5, 100.5), Vector2(64, 32), 2, 1, floor_mask)]
		var helper: Array[Dictionary] = [_ellipse(Vector2(100.5, 100.5), Vector2(64, 32), 1, 0, floor_mask)]
		var want := LightingPass.shifted_index(4, shade, 25)
		_assert_eq(p.output_index(Vector2(100, 100), 4, focal), want,
			"focal core (lift 2 + fill 1 = 3) with shade %d: k = max(2 - 3, 0) + %d = %d (was 0, the shadow vanished)" % [shade, shade, shade])
		_assert_eq(p.output_index(Vector2(140, 100), 4, focal), want, "focal band (1 + fill 1 = 2) with shade %d: k %d" % [shade, shade])
		_assert_eq(p.output_index(Vector2(100, 100), 4, helper), want, "helper core (1 + fill 1 = 2) with shade %d: k %d" % [shade, shade])
		_assert_eq(p.output_index(Vector2(100, 100), 8, focal), 6, "wall 08 under a floor pool: k 2, no shade (not a receiver)")
		rig["lit"].shadows = false
		_assert_eq(p.output_index(Vector2(100, 100), 4, focal), 4, "shadows off: the focal core keeps its art value (k 0)")
		_free_pass(rig)


func test_fill_and_shade_only_on_the_floor_mask() -> void:
	# Fable P2-3: receivers are floor indices on the room's floor, not every 00-05 pixel on screen.
	var rig := _pass(2, 1, 1)
	var p: LightingPass = rig["pass"]
	p.floor_image.fill_rect(Rect2i(0, 0, 100, 400), Color8(0, 0, 0))
	var e: Array[Dictionary] = []
	_assert_false(p.on_floor(Vector2(50, 50)), "x < 100: off the floor mask")
	_assert_true(p.on_floor(Vector2(150, 50)), "x >= 100: on the floor mask")
	_assert_eq(p.fill_at(Vector2(50, 50), 4, e), 0, "index 04 off the floor: no fill")
	_assert_eq(p.shade_at(Vector2(50, 50), 4, e), 0, "index 04 off the floor: no shade")
	_assert_eq(p.output_index(Vector2(50, 50), 4, e), 2, "index 04 off the floor (a wall dark, an arch window): the ADR-026 k 2")
	_assert_eq(p.fill_at(Vector2(150, 50), 4, e), 1, "index 04 on the floor: fill 1")
	_assert_eq(p.shade_at(Vector2(150, 50), 4, e), 1, "index 04 on the floor: shade 1")
	rig["lit"].shadows = false
	_assert_eq(p.output_index(Vector2(50, 50), 4, e), 2, "fill only, off the floor: k 2")
	_assert_eq(p.output_index(Vector2(150, 50), 4, e), 3, "fill only, on the floor: k 1")
	p.floor_image = null
	_assert_eq(p.output_index(Vector2(150, 50), 4, e), 2, "no floor mask: nothing is a receiver (no fill)")
	_free_pass(rig)


func test_the_fill_never_returns_the_floor_to_its_unlit_value() -> void:
	# Fable P2-3: at A 1 a fill of 1 left no step between the open floor and a pool.
	var lit := RoomLighting.new()
	lit.fill_lift = 1
	var want := [0, 0, 1, 1]
	for a in 4:
		lit.ambient_steps = a
		_assert_eq(lit.effective_fill(), want[a], "A %d, fill_lift 1: effective fill %d (at most A - 1)" % [a, want[a]])
	lit.fill_lift = 0
	lit.ambient_steps = 3
	_assert_eq(lit.effective_fill(), 0, "fill_lift 0: no fill at any A")
	var rig := _pass(1, -1, 1)
	var p: LightingPass = rig["pass"]
	var helper: Array[Dictionary] = [_ellipse(Vector2(300.5, 200.5), Vector2(64, 32), 1, 0, 0b111111)]
	_assert_eq(p.output_index(Vector2(450, 200), 4, helper), 3, "A 1, fill 1: open floor stays k 1 (no fill)")
	_assert_eq(p.output_index(Vector2(300, 200), 4, helper), 4, "A 1: the pool core is k 0, one step above the floor")
	_assert_eq(p.fill_at(Vector2(450, 200), 4, helper), 0, "A 1: fill_at 0")
	rig["lit"].ambient_steps = 3
	_assert_eq(p.output_index(Vector2(450, 200), 4, helper), 2, "A 3, fill 1: open floor k 2")
	_assert_eq(p.output_index(Vector2(300, 200), 4, helper), 3, "A 3: helper core 1 + 1 -> k 1")
	_free_pass(rig)


func test_baked_floor_mask_iso_polygon_and_side_strip() -> void:
	var s := make_session()
	var room := _concourse(s)
	var shape := room.get_meta(&"room_shape") as RoomShape
	var r := ShadeBaker.bake(room)
	var mask: Image = r["floor"]
	var o: Vector2 = r["origin"]
	_assert_eq(mask.get_format(), Image.FORMAT_L8, "L8 mask")
	_assert_eq(Vector2(mask.get_width(), mask.get_height()), Vector2(r["image"].get_width(), r["image"].get_height()), "same size as the shade map")
	var at := func(world: Vector2) -> int:
		var t := Vector2i((world - o).floor())
		return mask.get_pixel(t.x, t.y).r8
	_assert_eq(at.call(RoomShape.tile_to_px(Vector2(14, 0.2))), 1, "floor just inside the N wall base")
	_assert_eq(at.call(RoomShape.tile_to_px(Vector2(14, -0.3))), 0, "the N wall above the floor edge: not floor")
	_assert_eq(at.call(RoomShape.tile_to_px(Vector2(-0.3, 8))), 0, "the W wall: not floor")
	_assert_eq(at.call(RoomShape.tile_to_px(Vector2(8, 8))), 1, "mid floor")
	var count := 0
	var data := mask.get_data()
	for v in data:
		count += v
	var area := shape.floor_cells().size() * 256
	_assert_true(absf(count - area) < 0.02 * area, "mask area %d px vs %d floor cells x 256 px" % [count, shape.floor_cells().size()])
	free_session(s)
	var side_root := (load(FIXTURE) as PackedScene).instantiate() as Node2D
	var side := ViewMode.side_view_of(side_root)
	var rs := ShadeBaker.bake(side_root)
	var sm: Image = rs["floor"]
	var so: Vector2 = rs["origin"]
	var row := func(y: float) -> int:
		return sm.get_pixel(int(200 - so.x), int(y - so.y)).r8
	var fy := side.floor_y
	# ASSET_METADATA 13.1: the 960 x 72 platform floor strip sits at screen y 378 with the floor line at 394.
	_assert_eq(fy, 394.0, "fixture floor line at y 394")
	_assert_eq(row.call(377), 0, "side: y 377, above the platform floor strip (wall, arches): not floor")
	_assert_eq(row.call(378), 1, "side: y 378, the strip's top row")
	_assert_eq(row.call(fy), 1, "side: the floor line")
	_assert_eq(row.call(449), 1, "side: y 449, the strip's last row (rail trench)")
	_assert_eq(row.call(450), 0, "side: y 450, the letterbox below: not floor")
	_assert_eq(rs["image"].get_pixel(int(600 - so.x), int(fy - 10.5 - so.y)).r8, ShadeBaker.AO, "side AO band lies on the strip")
	side_root.free()


func test_fill_adds_to_room_pools_but_not_to_the_elias_zone() -> void:
	var rig := _pass(2, -1, 1)
	var p: LightingPass = rig["pass"]
	_assert_eq(rig["lit"].fill_mode, RoomLighting.FillMode.ADD, "ADD is the default fill mode")
	var c := Vector2(300.5, 200.5)
	var floor_mask := 0b111111
	var helper: Array[Dictionary] = [_ellipse(c, Vector2(64, 32), 1, 0, floor_mask)]
	_assert_eq(p.output_index(Vector2(300, 200), 4, helper), 4, "helper core: lift 1 + fill 1 -> k 0, a step above the filled floor")
	_assert_eq(p.output_index(Vector2(350, 200), 4, helper), 3, "helper outer band: 0 + fill 1 -> k 1, the filled floor (no dark ring)")
	_assert_eq(p.output_index(Vector2(400, 200), 4, helper), 3, "outside: the fill, k 1")
	_assert_eq(p.fill_at(Vector2(300, 200), 4, helper), 1, "the fill adds one step inside the pool")
	var focal: Array[Dictionary] = [_ellipse(c, Vector2(64, 32), 2, 1, floor_mask)]
	_assert_eq(p.output_index(Vector2(350, 200), 4, focal), 4, "focal outer band: 1 + 1 -> k 0")
	_assert_eq(p.output_index(Vector2(350, 200), 8, focal), 6, "wall 08 under a floor-only pool: k 2 (no lift, no fill)")
	var any_index: Array[Dictionary] = [_ellipse(c, Vector2(64, 32), 1, 0)]
	_assert_eq(p.output_index(Vector2(300, 200), 13, any_index), 12, "a body index (13) in a pool: lift 1, no fill (not a receiver), k 1")
	var body_only: Array[Dictionary] = [_ellipse(c, Vector2(64, 32), 2, 1, 0b11111 << 11)]
	_assert_eq(p.output_index(Vector2(300, 200), 4, body_only), 3, "a light lifting only bodies (11-15) adds nothing to the floor: k 1")
	var elias: Array[Dictionary] = [_ellipse(c, Vector2(18, 28), 1, 0, 0, false)]
	_assert_eq(p.output_index(Vector2(300, 200), 4, elias), 3, "the Elias zone does not add the fill: max(zone 1, fill 1) -> k 1, no bright capsule on the floor")
	_free_pass(rig)


func test_fill_is_cleared_around_room_pools_only() -> void:
	var rig := _pass(2, -1, 1)
	var p: LightingPass = rig["pass"]
	rig["lit"].fill_mode = RoomLighting.FillMode.CLEAR
	rig["lit"].fill_clear = 1.5
	var c := Vector2(300.5, 200.5)
	var floor_mask := 0b111111
	var e: Array[Dictionary] = [_ellipse(c, Vector2(64, 32), 1, 0, floor_mask)]
	_assert_eq(p.output_index(Vector2(300, 200), 4, e), 3, "helper core: lift 1 -> k 1")
	_assert_eq(p.output_index(Vector2(300 + 50, 200), 4, e), 2, "helper outer band: fill cleared, k 2")
	_assert_eq(p.output_index(Vector2(300 + 90, 200), 4, e), 2, "1.4 radii: still the dark surround, k 2")
	_assert_eq(p.output_index(Vector2(300 + 100, 200), 4, e), 3, "1.56 radii: the fill, k 1")
	_assert_eq(p.output_index(Vector2(300 + 50, 200), 8, e), 6, "wall 08 in the clear area: no fill anyway, k 2")
	var body_only: Array[Dictionary] = [_ellipse(c, Vector2(64, 32), 2, 1, 0b11111 << 11)]
	_assert_eq(p.output_index(Vector2(300, 200), 4, body_only), 3, "a light that lifts only bodies (11-15) does not clear the floor fill")
	var elias: Array[Dictionary] = [_ellipse(c, Vector2(18, 28), 1, 0, 0, false)]
	_assert_eq(p.output_index(Vector2(300 + 15, 200), 4, elias), 3, "the Elias zone (outer band) does not clear the fill: k 1, no dark ring")
	rig["lit"].fill_lift = 0
	_assert_eq(p.output_index(Vector2(300 + 100, 200), 4, e), 2, "fill 0: the ADR-026 look, k 2")
	_free_pass(rig)


func test_room_lighting_fill_ranges() -> void:
	var lit := RoomLighting.new()
	_assert_eq(lit.validate(), PackedStringArray(), "defaults are valid")
	_assert_false(lit.shadows, "shadows off by default (ADR-026 rooms keep their look)")
	_assert_eq(lit.fill_lift, 0, "no fill by default")
	_assert_eq(lit.fill_mode, RoomLighting.FillMode.ADD, "fill mode ADD by default")
	lit.fill_lift = 2
	_assert_eq(lit.validate().size(), 1, "fill_lift 2 rejected")
	lit.fill_lift = 1
	lit.fill_clear = 0.8
	_assert_eq(lit.validate().size(), 1, "fill_clear below 1 rejected (the pool itself must stay clear)")


func test_every_lit_ch01_room_has_shadows_and_the_fill() -> void:
	var dir := DirAccess.open(ROOMS_DIR)
	var lit_rooms := 0
	for file in dir.get_files():
		if not file.ends_with(".tscn"):
			continue
		var state := (load(ROOMS_DIR.path_join(file)) as PackedScene).get_state()
		for p in state.get_node_property_count(0):
			if state.get_node_property_name(0, p) == &"metadata/lighting":
				var lit := state.get_node_property_value(0, p) as RoomLighting
				lit_rooms += 1
				_assert_true(lit.shadows, "%s: shadows on (ADR-027)" % file)
				if lit.ambient_steps >= 2:
					_assert_eq(lit.fill_lift, 1, "%s: A %d, floor fill 1 (owner: fill, keep the focal)" % [file, lit.ambient_steps])
				else:
					_assert_eq(lit.effective_fill(), 0, "%s: A %d, the fill is not applied (r2: at most A - 1), fill_lift is free" % [file, lit.ambient_steps])
	_assert_true(lit_rooms >= 1, "at least Concourse West is lit (%d)" % lit_rooms)


func test_elias_contact_sits_below_his_body() -> void:
	var r := LightingPass.ELIAS_CONTACT_RADIUS
	var sprite_pos := Vector2(0, -20)
	for frames: SpriteFrames in [Player.ISO_FRAMES, Player.SIDE_FRAMES]:
		var off := LightingPass.ELIAS_CONTACT_OFFSET if frames == Player.ISO_FRAMES else LightingPass.ELIAS_CONTACT_OFFSET_SIDE
		var inside := 0
		var lowest := -999
		var checked := 0
		for anim in frames.get_animation_names():
			for f in frames.get_frame_count(anim):
				var img := frames.get_frame_texture(anim, f).get_image()
				if img.is_compressed():
					img.decompress()
				var tl := sprite_pos - Vector2(img.get_width(), img.get_height()) / 2.0
				checked += 1
				for y in img.get_height():
					for x in img.get_width():
						var col := img.get_pixel(x, y)
						if col.a <= 0.5:
							continue
						var px := Vector2(int(tl.x) + x, int(tl.y) + y)
						lowest = maxi(lowest, int(px.y))
						var index := TlfPalette.nearest_index(col)
						if LightingPass.shifted_index(index, 1, 25) == index:
							continue
						if ((px + Vector2(0.5, 0.5) - off) / r).length() < 1.0:
							inside += 1
		_assert_true(checked > 8, "%s: %d frames checked" % [frames.resource_path.get_file(), checked])
		_assert_eq(inside, 0, "%s: no body pixel the shade could change lies in the contact ellipse" % frames.resource_path.get_file())
		var top_row := int(ceil(off.y - r.y - 0.5))
		_assert_true(top_row <= lowest + 1, "%s: the ellipse touches his lowest body row (%d), it does not float (top row %d)" % [
			frames.resource_path.get_file(), lowest, top_row])


# --- the setting and the router hook -------------------------------------------------------------

func test_setting_off_skips_the_bake_and_hides_the_pass() -> void:
	var settings := _tree().root.get_node_or_null("Settings")
	var was_enabled: bool = settings.lighting_enabled
	settings.lighting_enabled = false
	var s := make_session()
	var room := _concourse(s)
	var nodes := room.find_children("*", "", true, false).size()
	var pass_node := LightingPass.new()
	_tree().root.add_child(pass_node)
	pass_node.apply_room(room, room.get_meta(&"lighting") as RoomLighting, null)
	_assert_false(pass_node.visible, "setting off: the pass is hidden (today's unlit frame)")
	_assert_eq(pass_node.bake_count, 0, "setting off: no bake at room entry")
	_assert_true(pass_node.shade_image == null, "setting off: no map")
	settings.lighting_enabled = true
	_assert_true(pass_node.visible and pass_node.shadows_active(), "setting on: visible, map baked")
	_assert_eq(pass_node.bake_count, 1, "one bake")
	_assert_eq(Vector2(pass_node.shade_image.get_width(), pass_node.shade_image.get_height()),
		(room.get_meta(&"room_shape") as RoomShape).bounds_px().size, "map over the room bounds")
	settings.lighting_enabled = false
	settings.lighting_enabled = true
	_assert_eq(pass_node.bake_count, 1, "toggling the setting in the same room does not bake again")
	_assert_eq(room.find_children("*", "", true, false).size(), nodes, "the room's nodes are untouched")
	var fill_only := (room.get_meta(&"lighting") as RoomLighting).duplicate() as RoomLighting
	fill_only.shadows = false
	pass_node.apply_room(room, fill_only, null)
	_assert_true(pass_node.floor_active() and not pass_node.shadows_active(), "fill without shadows: the floor mask is baked, no shade")
	_assert_eq(pass_node.bake_count, 2, "fill without shadows: one bake (the mask)")
	pass_node.apply_room(room, null, null)
	_assert_true(pass_node.shade_image == null and not pass_node.shadows_active(), "unlit room: map dropped")
	settings.lighting_enabled = was_enabled
	pass_node.free()
	free_session(s)


func _connections_to(sig: Signal, target: Object) -> int:
	var n := 0
	for c in sig.get_connections():
		if (c["callable"] as Callable).get_object() == target:
			n += 1
	return n


func test_opening_the_concourse_gate_rebakes_the_map() -> void:
	# Fable P3: the turnstile's Blocker collider is disabled when it opens; the map follows at once.
	var settings := _tree().root.get_node_or_null("Settings")
	var was_enabled: bool = settings.lighting_enabled
	settings.lighting_enabled = true
	var s := make_session()
	var room := _concourse(s)
	var pass_node := LightingPass.new()
	_tree().root.add_child(pass_node)
	pass_node.apply_room(room, room.get_meta(&"lighting") as RoomLighting, null)
	await physics_frames(2)
	var gate := room.get_node("turnstile_gate") as TurnstileGate
	var blocker := room.get_node("turnstile_gate/Blocker/CollisionShape2D") as CollisionShape2D
	_assert_eq(_connections_to(gate.passage_changed, pass_node), 1, "the pass watches the gate's passage_changed")
	_assert_false(blocker.disabled, "the gate starts closed (Blocker on)")
	var bakes := pass_node.bake_count
	var closed := pass_node.shade_image.get_data()
	var c := blocker.global_position - pass_node.shade_origin
	var rim := Vector2i(int(c.x - 13), int(c.y))
	_assert_eq(pass_node.shade_image.get_pixel(rim.x, rim.y).r8, ShadeBaker.CONTACT_RIM, "closed: the Blocker's contact rim 13 px left of the post")
	gate.apply_state({"arm_state": &"open", "passage_blocked": false})
	_assert_eq(pass_node.bake_count, bakes, "no bake before the collider has changed (set_deferred)")
	await physics_frames(1)
	_assert_true(blocker.disabled, "open: Blocker off")
	_assert_eq(pass_node.bake_count, bakes + 1, "open: the map is rebaked once")
	_assert_eq(pass_node.shade_image.get_pixel(rim.x, rim.y).r8, 0, "open: the Blocker's contact rim is gone")
	var fresh := ShadeBaker.bake(room)
	_assert_true(pass_node.shade_image.get_data() == fresh["image"].get_data(), "open: the map equals a fresh bake (as on entering the solved room)")
	_assert_true(pass_node.shade_image.get_data() != closed, "open: the map changed")
	print("  INFO: post centre after opening: shade %d (the open post's own contact from its sprite)" % pass_node.shade_image.get_pixel(int(c.x), int(c.y)).r8)
	for i in 3:
		gate.apply_state({"arm_state": &"open", "passage_blocked": false})
	await physics_frames(2)
	_assert_eq(pass_node.bake_count, bakes + 1, "the same state again (a rewind re-applies it every tick): no bake")
	gate.apply_state({"arm_state": &"collapsed", "passage_blocked": true})
	await physics_frames(1)
	_assert_eq(pass_node.bake_count, bakes + 2, "closed again (reset): rebaked")
	_assert_true(pass_node.shade_image.get_data() == closed, "closed again: the first map back, texel for texel")
	settings.lighting_enabled = false
	gate.apply_state({"arm_state": &"open", "passage_blocked": false})
	await physics_frames(1)
	_assert_eq(pass_node.bake_count, bakes + 2, "setting off: a toggle drops the map but bakes nothing")
	_assert_true(pass_node.shade_image == null, "setting off: the stale map is dropped")
	settings.lighting_enabled = true
	_assert_eq(pass_node.bake_count, bakes + 3, "setting on again: one bake, of the open gate")
	_assert_true(pass_node.shade_image.get_data() == fresh["image"].get_data(), "setting on again: the open-gate map")
	pass_node.apply_room(null, null, null)
	_assert_eq(_connections_to(gate.passage_changed, pass_node), 0, "leaving the room disconnects the gate")
	settings.lighting_enabled = was_enabled
	pass_node.free()
	free_session(s)


func _iso_room() -> PackedScene:
	var root := Node2D.new()
	root.name = "RoomIso"
	var shape := RoomShape.rectangle(12, 8)
	root.set_meta(&"room_shape", shape)
	var lit := RoomLighting.new()
	lit.shadows = true
	lit.fill_lift = 1
	root.set_meta(&"lighting", lit)
	var d := DoorwayPresenter.new()
	d.name = "door_e"
	d.object_id = &"ch01.room_iso.door_e"
	d.room_id = ISO_ROOM
	d.door_id = &"door_e"
	d.position = RoomShape.tile_to_px(Vector2(11, 4))
	var marker := Marker2D.new()
	marker.name = "Spawn"
	marker.position = Vector2(-40, 0)
	d.add_child(marker)
	root.add_child(d)
	var body := StaticBody2D.new()
	body.name = "Crate"
	body.position = RoomShape.tile_to_px(Vector2(5, 4))
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 8)
	cs.shape = rect
	body.add_child(cs)
	root.add_child(body)
	var l := RoomLight.new()
	l.name = "Focal"
	l.position = RoomShape.tile_to_px(Vector2(6, 4))
	root.add_child(l)
	_own_children(root)
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


func _own_children(root: Node) -> void:
	for child in root.get_children():
		_own(child, root)


func _side_room() -> PackedScene:
	var root := (load(FIXTURE) as PackedScene).instantiate()
	var lit := RoomLighting.new()
	lit.ambient_steps = 1
	lit.shadows = true
	root.set_meta(&"lighting", lit)
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


func test_map_rebuilt_on_every_room_change_without_leaks() -> void:
	var settings := _tree().root.get_node_or_null("Settings")
	var was_enabled: bool = settings.lighting_enabled
	settings.lighting_enabled = true
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
	router.register_room(ISO_ROOM, _iso_room())
	router.register_room(SIDE, _side_room())
	router.enter_room(ISO_ROOM, &"door_e")
	var pass_node := router.lighting_pass
	_assert_true(pass_node != null and pass_node.shadows_active(), "lit iso room with shadows: map baked")
	var iso_size := Vector2(pass_node.shade_image.get_width(), pass_node.shade_image.get_height())
	_assert_eq(iso_size, RoomShape.rectangle(12, 8).bounds_px().size, "iso map = the room's bounds")
	var crate := RoomShape.tile_to_px(Vector2(5, 4)) - pass_node.shade_origin
	_assert_eq(pass_node.shade_image.get_pixel(int(crate.x), int(crate.y)).r8, ShadeBaker.CONTACT_CORE, "the crate's contact core is in this room's map")
	var walk := func(id: StringName) -> void:
		s.sim_clock.step(20)
		s.interaction_service.trigger_enter(&"player", id)
		router.process_pending()
	await physics_frames(2)
	walk.call(&"ch01.room_iso.door_e")
	walk.call(&"ch01.room_side.door_w")
	await physics_frames(2)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var bakes := pass_node.bake_count
	for round in 3:
		walk.call(&"ch01.room_iso.door_e")
		_assert_eq(router.current_view_mode(), ViewMode.SIDE, "round %d: side" % round)
		_assert_eq(pass_node.bake_count, bakes + 1, "round %d: map rebuilt for the side room" % round)
		_assert_eq(Vector2(pass_node.shade_image.get_width(), pass_node.shade_image.get_height()),
			SideView.new().bounds_px().size if not router.current_room.has_meta(&"side_view") else (router.current_room.get_meta(&"side_view") as SideView).bounds_px().size,
			"round %d: side map = the side bounds" % round)
		var side_c := RoomShape.tile_to_px(Vector2(5, 4)) - pass_node.shade_origin
		_assert_true(side_c.x < 0 or side_c.y < 0 or side_c.x >= pass_node.shade_image.get_width() or side_c.y >= pass_node.shade_image.get_height()
			or pass_node.shade_image.get_pixel(int(side_c.x), int(side_c.y)).r8 != ShadeBaker.CONTACT_CORE, "round %d: no stale iso contact" % round)
		walk.call(&"ch01.room_side.door_w")
		_assert_eq(pass_node.bake_count, bakes + 2, "round %d: map rebuilt for the iso room" % round)
		_assert_eq(Vector2(pass_node.shade_image.get_width(), pass_node.shade_image.get_height()), iso_size, "round %d: iso map again" % round)
		bakes = pass_node.bake_count
		await physics_frames(1)
	await physics_frames(2)
	_assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans, "no orphan nodes after 3 round trips")
	_assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), objects, "no leaked objects (maps, textures) after 3 round trips")
	settings.lighting_enabled = was_enabled
	free_session(s)
	var dir := DirAccess.open(ROOT)
	if dir != null:
		for f in dir.get_files():
			dir.remove(f)
		DirAccess.remove_absolute(ROOT)
