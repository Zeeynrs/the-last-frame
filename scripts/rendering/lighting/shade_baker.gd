class_name ShadeBaker
extends RefCounted

## ADR-027 shade map (TLF-084): one L8 texel per world pixel, values 0..2 (extra ramp steps), baked
## from what a room already has when the LightingPass applies it. No authoring:
##  - AO strips on the floor along the tall N/W wall bases (AO_TALL tile wide), the low S/E edges and
##    both sides of every partition segment (SegmentShape2D under a StaticBody2D; AO_LOW tile);
##  - contact shadows, 2:1 ellipses with a core (CONTACT_CORE) and a rim (CONTACT_RIM), under every
##    footprint collider (Rectangle/Circle/Capsule under a StaticBody2D) and every actor-layer sprite
##    without one (DepthSort upright art or z ACTOR_Z: statues, consoles, bench, courier);
##  - cast shadows (CAST) from grounded casters at least CAST_MIN_HEIGHT px tall: a tapered quad on the
##    floor, length = height / 32 tiles, falling away from the ART_BIBLE key light at 315 degrees
##    (screen down-right, +x in tile space) in every room.
## Footprints on or outside the floor edge (doors set into a wall) and anything under a node with
## `metadata/shade_skip = true` cast nothing. Side rooms (ADR-025) get a band where the far wall
## meets the deck, contact ellipses on the floor line and short casts to the right.
## The rasterizer is a scanline fill (convex polygons and ellipses, pixel centres), written row
## by row with Image.fill_rect in ascending value order, so the map holds the maximum value.

const AO := 1
const AO_TALL := 0.5
const AO_LOW := 0.3
const CONTACT_CORE := 2
const CONTACT_RIM := 1
## Core band edge as a fraction of the contact ellipse radius.
const CONTACT_INNER := 0.55
const CAST := 1
const CAST_MIN_HEIGHT := 28.0
## Tile-space direction shadows fall in: the ART_BIBLE key light at 315 degrees (top-left of the
## screen) throws them to the screen's bottom-right, +x in tile space (ADR-027).
const KEY_DIR_TILES := Vector2(1, 0)
## Side view: shadows fall to the right of the caster (same key).
const KEY_DIR_SIDE := 1.0
const SKIP_META := &"shade_skip"
## A sprite this close (px) to a footprint already listed is that body's art (e.g. a pillar sprite
## in YSort_Walls over its collider) and casts nothing more.
const SAME_BODY_PX := 16.0
## Footprints whose centre is closer than this (tiles) to the floor outline, or outside it, cast nothing.
const EDGE_MARGIN := 0.25
## Side view: the AO band where the far wall meets the deck, relative to SideView.floor_y.
const SIDE_AO_TOP := -12.0
const SIDE_AO_BOTTOM := -9.0
## Side view: contact ellipse half height and the smallest caster width.
const SIDE_CONTACT_RY := 3.0
const SIDE_MIN_WIDTH := 12.0


## Bakes `room`'s shade map. Returns {image (L8), origin (world position of texel 0,0), ms,
## polys, ellipses}. An empty room still gets a map (all zeros) over its bounds.
static func bake(room: Node2D) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var shapes := shapes_for(room)
	var bounds: Rect2 = shapes["bounds"]
	var img := rasterize(bounds, shapes["polys"], shapes["ellipses"])
	return {"image": img, "origin": bounds.position, "ms": (Time.get_ticks_usec() - t0) / 1000.0,
		"polys": shapes["polys"].size(), "ellipses": shapes["ellipses"].size()}


## The shapes of `room` in world pixels: {bounds: Rect2 (whole pixels), polys: [[PackedVector2Array
## (convex), value]], ellipses: [[centre, radius]]} (contact ellipses: CONTACT_CORE inside
## CONTACT_INNER, CONTACT_RIM up to the radius).
static func shapes_for(room: Node2D) -> Dictionary:
	var side := ViewMode.side_view_of(room) if ViewMode.of(room) == ViewMode.SIDE else null
	if side != null:
		return side_shapes(room, side)
	var shape: RoomShape = room.get_meta(&"room_shape") as RoomShape if room.has_meta(&"room_shape") else null
	return iso_shapes(room, shape)


static func iso_shapes(room: Node2D, shape: RoomShape) -> Dictionary:
	var xf := room.global_transform
	var valid := shape != null and shape.is_valid()
	var local_bounds := shape.bounds_px() if valid else RoomCamera.LEGACY_SCREEN
	var polys: Array = []
	if valid:
		for seg in shape.wall_segments():
			if seg["kind"] != &"straight":
				continue
			var a := Vector2(seg["from"])
			var b := Vector2(seg["to"])
			match seg["face"]:
				&"N": polys.append([_strip(xf, a, b, Vector2(0, 1), 0.0, AO_TALL), AO])
				&"W": polys.append([_strip(xf, a, b, Vector2(1, 0), 0.0, AO_TALL), AO])
				&"low_S": polys.append([_strip(xf, a, b, Vector2(0, -1), 0.0, AO_LOW), AO])
				&"low_E": polys.append([_strip(xf, a, b, Vector2(-1, 0), 0.0, AO_LOW), AO])
	var inv := xf.affine_inverse()
	for node in room.find_children("*", "CollisionShape2D", true, false):
		var cs := node as CollisionShape2D
		var seg := cs.shape as SegmentShape2D
		if seg == null or cs.disabled or not (cs.get_parent() is StaticBody2D) or _skipped(cs, room):
			continue
		var a_t := RoomShape.px_to_tile(inv * (cs.global_transform * seg.a))
		var b_t := RoomShape.px_to_tile(inv * (cs.global_transform * seg.b))
		if a_t.is_equal_approx(b_t):
			continue
		var dir := (b_t - a_t).normalized()
		polys.append([_strip(xf, a_t, b_t, Vector2(-dir.y, dir.x), -AO_LOW, AO_LOW), AO])
	var ellipses: Array = []
	for g in grounded(room, shape if valid else null):
		var c: Vector2 = g["centre"]
		var rx: float = g["rx"]
		ellipses.append([c, Vector2(rx, rx * 0.5)])
		var h: float = g["height"]
		if h < CAST_MIN_HEIGHT:
			continue
		var foot := RoomShape.px_to_tile(inv * c)
		var perp := Vector2(-KEY_DIR_TILES.y, KEY_DIR_TILES.x)
		var w := clampf(rx / 16.0, 0.3, 0.6)
		var tip := foot + KEY_DIR_TILES * (h / 32.0)
		polys.append([PackedVector2Array([_t2w(xf, foot + perp * w), _t2w(xf, tip + perp * w * 0.4),
			_t2w(xf, tip - perp * w * 0.4), _t2w(xf, foot - perp * w)]), CAST])
	return {"bounds": _world_rect(xf, local_bounds), "polys": polys, "ellipses": ellipses}


## Grounded casters of an iso room: [{centre (world px), rx, height, node}]. Footprint colliders
## first, then actor-layer sprites of objects without one (and not within SAME_BODY_PX of one).
static func grounded(room: Node2D, shape: RoomShape) -> Array:
	var out: Array = []
	var with_body := {}
	var inv := room.global_transform.affine_inverse()
	for node in room.find_children("*", "CollisionShape2D", true, false):
		var cs := node as CollisionShape2D
		var body := cs.get_parent() as StaticBody2D
		if body == null or cs.disabled or cs.shape == null or _skipped(cs, room):
			continue
		var half := 0.0
		if cs.shape is RectangleShape2D:
			half = (cs.shape as RectangleShape2D).size.x * 0.5
		elif cs.shape is CircleShape2D:
			half = (cs.shape as CircleShape2D).radius
		elif cs.shape is CapsuleShape2D:
			half = (cs.shape as CapsuleShape2D).radius
		else:
			continue
		with_body[body.get_parent()] = true
		var c := cs.global_position
		if shape != null and not _inside_floor(shape, RoomShape.px_to_tile(inv * c)):
			continue
		out.append({"centre": c, "rx": maxf(half * 1.25, 6.0), "height": _height_near(room, c), "node": cs})
	for node in room.find_children("*", "Sprite2D", true, false):
		var s := node as Sprite2D
		if s.texture == null or not s.visible or with_body.has(s.get_parent()) or _skipped(s, room):
			continue
		if not (DepthSort.is_upright_texture(s.texture) or effective_z(s) == DepthSort.ACTOR_Z):
			continue
		var c := (s.get_parent() as Node2D).global_position if s.get_parent() is Area2D else s.global_position
		if out.any(func(g: Dictionary) -> bool: return g["centre"].distance_to(c) <= SAME_BODY_PX):
			continue
		var size := s.get_rect().size
		out.append({"centre": c, "rx": maxf(size.x * 0.35, 6.0), "height": size.y, "node": s})
	return out


static func side_shapes(room: Node2D, side: SideView) -> Dictionary:
	var xf := room.global_transform
	var local_bounds := side.bounds_px()
	var fy := side.floor_y
	var x0 := local_bounds.position.x
	var x1 := local_bounds.end.x
	var polys: Array = [[PackedVector2Array([xf * Vector2(x0, fy + SIDE_AO_TOP), xf * Vector2(x1, fy + SIDE_AO_TOP),
		xf * Vector2(x1, fy + SIDE_AO_BOTTOM), xf * Vector2(x0, fy + SIDE_AO_BOTTOM)]), AO]]
	var ellipses: Array = []
	for node in room.get_children():
		if not (node is Node2D) or node is Marker2D or _skipped(node, room):
			continue
		var n2 := node as Node2D
		if absf(n2.position.y - fy) > 0.5:
			continue
		var w := 0.0
		var h := 0.0
		for s in [n2] + n2.find_children("*", "Sprite2D", true, false):
			if s is Sprite2D and (s as Sprite2D).texture != null and (s as Sprite2D).visible:
				var size := (s as Sprite2D).get_rect().size
				w = maxf(w, size.x)
				h = maxf(h, size.y)
		if w < SIDE_MIN_WIDTH:
			continue
		var c := xf * n2.position
		ellipses.append([c, Vector2(w * 0.45, SIDE_CONTACT_RY)])
		if h >= CAST_MIN_HEIGHT:
			var len := h * 0.35 * KEY_DIR_SIDE
			polys.append([PackedVector2Array([c + Vector2(0, -1), c + Vector2(len, -1), c + Vector2(len, 1),
				c + Vector2(0, 1)]), CAST])
	return {"bounds": _world_rect(xf, local_bounds), "polys": polys, "ellipses": ellipses}


## Scanline rasterizer: an L8 image over `bounds` (whole pixels), each texel the largest value of the
## shapes covering its centre. Polygons are convex and include their edges; contact ellipses are
## open (normalized distance < 1, core < CONTACT_INNER).
static func rasterize(bounds: Rect2, polys: Array, ellipses: Array) -> Image:
	var w := maxi(int(bounds.size.x), 1)
	var h := maxi(int(bounds.size.y), 1)
	var img := Image.create(w, h, false, Image.FORMAT_L8)
	var o := bounds.position
	# Ascending values, so a later (stronger) write is the maximum.
	for v in range(1, 256):
		var col := Color8(v, v, v)
		var any := false
		for pv in polys:
			if pv[1] == v:
				_fill_poly(img, o, pv[0], col)
			any = any or pv[1] > v
		for e in ellipses:
			if v == CONTACT_RIM:
				_fill_ellipse(img, o, e[0], e[1], 1.0, col)
			if v == CONTACT_CORE:
				_fill_ellipse(img, o, e[0], e[1], CONTACT_INNER, col)
		if not any and v >= maxi(CONTACT_RIM, CONTACT_CORE):
			break
	return img


## Effective z of a canvas item (its own z plus every relative parent's).
static func effective_z(item: CanvasItem) -> int:
	var z := item.z_index
	var node: Node = item
	while (node as CanvasItem).z_as_relative:
		node = node.get_parent()
		if not (node is CanvasItem):
			break
		z += (node as CanvasItem).z_index
	return z


# --- internals -----------------------------------------------------------------------------

static func _fill_poly(img: Image, o: Vector2, poly: PackedVector2Array, col: Color) -> void:
	var ymin := INF
	var ymax := -INF
	for q in poly:
		ymin = minf(ymin, q.y)
		ymax = maxf(ymax, q.y)
	var w := img.get_width()
	var h := img.get_height()
	var n := poly.size()
	for y in range(maxi(int(ceil(ymin - o.y - 0.5)), 0), mini(int(floor(ymax - o.y - 0.5)), h - 1) + 1):
		var sy := o.y + y + 0.5
		var xl := INF
		var xr := -INF
		for i in n:
			var a := poly[i]
			var b := poly[(i + 1) % n]
			if (a.y < sy and b.y < sy) or (a.y > sy and b.y > sy):
				continue
			if a.y == b.y:
				xl = minf(xl, minf(a.x, b.x))
				xr = maxf(xr, maxf(a.x, b.x))
			else:
				var x := a.x + (sy - a.y) * (b.x - a.x) / (b.y - a.y)
				xl = minf(xl, x)
				xr = maxf(xr, x)
		if xl > xr:
			continue
		var x0 := maxi(int(ceil(xl - o.x - 0.5)), 0)
		var x1 := mini(int(floor(xr - o.x - 0.5)), w - 1)
		if x1 >= x0:
			img.fill_rect(Rect2i(x0, y, x1 - x0 + 1, 1), col)


static func _fill_ellipse(img: Image, o: Vector2, c: Vector2, r: Vector2, edge: float, col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var ry := r.y * edge
	for y in range(maxi(int(floor(c.y - ry - o.y - 0.5)), 0), mini(int(ceil(c.y + ry - o.y - 0.5)), h - 1) + 1):
		var dy := (o.y + y + 0.5 - c.y) / r.y
		var t := edge * edge - dy * dy
		if t <= 0.0:
			continue
		var half := r.x * sqrt(t)
		# pixel x is inside when |o.x + x + 0.5 - c.x| < half
		var x0 := maxi(int(floor(c.x - half - o.x - 0.5)) + 1, 0)
		var x1 := mini(int(ceil(c.x + half - o.x - 0.5)) - 1, w - 1)
		if x1 >= x0:
			img.fill_rect(Rect2i(x0, y, x1 - x0 + 1, 1), col)


static func _t2w(xf: Transform2D, t: Vector2) -> Vector2:
	return xf * RoomShape.tile_to_px(t)


static func _strip(xf: Transform2D, a_t: Vector2, b_t: Vector2, n_t: Vector2, d0: float, d1: float) -> PackedVector2Array:
	return PackedVector2Array([_t2w(xf, a_t + n_t * d0), _t2w(xf, b_t + n_t * d0), _t2w(xf, b_t + n_t * d1),
		_t2w(xf, a_t + n_t * d1)])


static func _world_rect(xf: Transform2D, r: Rect2) -> Rect2:
	var a := (xf * r.position).floor()
	var b := (xf * r.end).ceil()
	return Rect2(a, b - a)


static func _height_near(room: Node, at: Vector2) -> float:
	var best := 0.0
	for node in room.find_children("*", "Sprite2D", true, false):
		var s := node as Sprite2D
		if s.texture == null or not s.visible or s.global_position.distance_to(at) > 14.0:
			continue
		best = maxf(best, s.get_rect().size.y)
	return best


static func _skipped(node: Node, room: Node) -> bool:
	var n := node
	while n != null and n != room:
		if n.has_meta(SKIP_META) and bool(n.get_meta(SKIP_META)):
			return true
		n = n.get_parent()
	return false


static func _inside_floor(shape: RoomShape, t: Vector2) -> bool:
	var poly := shape.canonical_outline()
	if not Geometry2D.is_point_in_polygon(t, poly):
		return false
	for i in poly.size():
		var q := Geometry2D.get_closest_point_to_segment(t, poly[i], poly[(i + 1) % poly.size()])
		if q.distance_to(t) < EDGE_MARGIN:
			return false
	return true
