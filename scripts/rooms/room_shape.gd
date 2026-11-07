class_name RoomShape
extends Resource

## Floor outline of a room in tile coordinates (ADR-023 R3). Floor tiles, the perimeter collision,
## the wall segments and the camera bounds are all derived from it.
##
## - `outline` is a closed (implicitly) rectilinear polygon: every edge runs along x or along y.
##   Winding (clockwise or not) and collinear or repeated points do not matter; everything below
##   works on a canonical copy (positive area, collinear points removed, starting at the vertex
##   with the smallest y, then x).
## - Tile (x, y) is floor when its centre (x + 0.5, y + 0.5) lies inside the outline.
## - Pixel math is ADR-003 / ROOM_GRAPH §1: px_x = 320 + (x - y) * 16, px_y = 64 + (x + y) * 8,
##   for a tile corner; a tile's diamond centre is tile_to_px(t + (0.5, 0.5)).
## - Faces: an edge along x with floor on its +y side is a north wall (N), with floor on its -y
##   side a low south partition (low_S); an edge along y with floor on its +x side is a west wall
##   (W), with floor on its -x side a low east partition (low_E). Only N and W are tall (R2).

const ORIGIN_PX := Vector2(320, 64)
const HALF_TILE_PX := Vector2(16, 8)
## Camera bounds around the floor: the tall N/W walls rise 56 px above the floor edge (wall module
## pivot (16, 56)); today's rooms start their floor at y = 64 under a 64 px north margin.
const MARGIN_TOP := 64.0
const MARGIN_SIDE := 16.0
const MARGIN_BOTTOM := 16.0
## ART_BIBLE: wall module 32 x 64 = 48 px vertical face + 16 px iso run; character 32 x 48, feet pivot.
const WALL_HEIGHT_PX := 48.0
const ACTOR_SIZE_PX := Vector2(32, 48)

@export var outline: PackedVector2Array = PackedVector2Array()

var _cache_key: PackedVector2Array = PackedVector2Array()
var _canonical: PackedVector2Array = PackedVector2Array()


## A rectangle W x H tiles with its north corner at tile (0, 0) (today's rooms).
static func rectangle(width: int, height: int) -> RoomShape:
	var shape := RoomShape.new()
	shape.outline = PackedVector2Array([Vector2(0, 0), Vector2(width, 0), Vector2(width, height), Vector2(0, height)])
	return shape


static func tile_to_px(t: Vector2) -> Vector2:
	return ORIGIN_PX + Vector2((t.x - t.y) * HALF_TILE_PX.x, (t.x + t.y) * HALF_TILE_PX.y)


## Inverse of tile_to_px (fractional tile coordinates).
static func px_to_tile(p: Vector2) -> Vector2:
	var d := p - ORIGIN_PX
	var a := d.x / HALF_TILE_PX.x   # x - y
	var b := d.y / HALF_TILE_PX.y   # x + y
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


## The canonical outline (see the class comment). Empty when the outline has fewer than 4 corners
## or an edge that is not axis-aligned.
func canonical_outline() -> PackedVector2Array:
	if _cache_key == outline and not _canonical.is_empty():
		return _canonical
	_cache_key = outline.duplicate()
	_canonical = _canonicalize(outline)
	return _canonical


func is_valid() -> bool:
	return not canonical_outline().is_empty()


func contains_tile(t: Vector2i) -> bool:
	var poly := canonical_outline()
	return not poly.is_empty() and Geometry2D.is_point_in_polygon(Vector2(t) + Vector2(0.5, 0.5), poly)


## Floor tiles, ordered by y, then x.
func floor_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var poly := canonical_outline()
	if poly.is_empty():
		return cells
	var box := _tile_box(poly)
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
				cells.append(Vector2i(x, y))
	return cells


## The outline in pixels (canonical order). `outset` pushes every edge outwards by that many tiles
## (a rectilinear offset; 0 = the floor edge itself).
func perimeter_polygon_px(outset: float = 0.0) -> PackedVector2Array:
	var poly := canonical_outline()
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var v := poly[i]
		var moved := v
		if outset != 0.0:
			moved += (_outward_normal(poly[(i - 1 + n) % n], v) + _outward_normal(v, poly[(i + 1) % n])) * outset
		out.append(tile_to_px(moved))
	return out


## One entry per straight edge ({face, from, to, kind = &"straight"}, from -> to running towards +x
## or +y) and one per corner ({face, from = to = the vertex, kind = &"inner_corner" (concave, three
## floor tiles around it) or &"outer_corner" (convex, one)}, plus `faces`, the two faces that meet).
## A corner's `face` is its tall face if it has one (N before W), else its low face.
func wall_segments() -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var poly := canonical_outline()
	var n := poly.size()
	if n == 0:
		return segments
	var faces: Array[StringName] = []
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var face := _face(a, b)
		faces.append(face)
		var from := Vector2i(a.min(b))
		var to := Vector2i(a.max(b))
		segments.append({"face": face, "from": from, "to": to, "kind": &"straight"})
	for i in n:
		var v := Vector2i(poly[i])
		var pair: Array[StringName] = [faces[(i - 1 + n) % n], faces[i]]
		var around := 0
		for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			if contains_tile(v + d):
				around += 1
		var tall := pair.filter(func(f: StringName) -> bool: return f == &"N" or f == &"W")
		tall.sort_custom(func(p: StringName, q: StringName) -> bool: return p == &"N" and q != &"N")
		var low := pair.filter(func(f: StringName) -> bool: return f == &"low_S" or f == &"low_E")
		low.sort_custom(func(p: StringName, q: StringName) -> bool: return p == &"low_S" and q != &"low_S")
		segments.append({"face": tall[0] if not tall.is_empty() else low[0], "from": v, "to": v,
			"kind": &"inner_corner" if around == 3 else &"outer_corner", "faces": pair})
	return segments


## Camera bounds: the floor's pixel box plus MARGIN_* (room for the tall N/W walls above it).
func bounds_px() -> Rect2:
	var px := perimeter_polygon_px()
	if px.is_empty():
		return Rect2()
	var lo := px[0]
	var hi := px[0]
	for p in px:
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2(lo - Vector2(MARGIN_SIDE, MARGIN_TOP), hi - lo + Vector2(2.0 * MARGIN_SIDE, MARGIN_TOP + MARGIN_BOTTOM))


## R2 check: floor tiles where an actor (ACTOR_SIZE_PX, feet on the tile centre) is partly covered
## by a tall N/W wall face that is nearer the camera (its base is lower on screen than the feet),
## by at least `min_overlap_px` square pixels. A tall face hides floor only where it meets a
## concave corner (e.g. an L whose north-east part is cut away); rectangles and corners between
## two low faces hide nothing. Pure geometry: today walls sort below actors (z 5 vs 10).
func hidden_floor_cells(min_overlap_px: float = 4.0) -> Array[Vector2i]:
	var faces: Array = []   # [screen polygon of one tile edge's wall face, base depth y]
	for seg in wall_segments():
		if seg["kind"] != &"straight" or not (seg["face"] == &"N" or seg["face"] == &"W"):
			continue
		var from := Vector2(seg["from"])
		var step := (Vector2(seg["to"]) - from).normalized()
		for i in int((Vector2(seg["to"]) - from).length()):
			var p0 := tile_to_px(from + step * i)
			var p1 := tile_to_px(from + step * (i + 1))
			var up := Vector2(0, -WALL_HEIGHT_PX)
			faces.append([PackedVector2Array([p0, p1, p1 + up, p0 + up]), (p0.y + p1.y) * 0.5])
	var hidden: Array[Vector2i] = []
	var half := ACTOR_SIZE_PX.x * 0.5
	for cell in floor_cells():
		var feet := tile_to_px(Vector2(cell) + Vector2(0.5, 0.5))
		var body := PackedVector2Array([feet + Vector2(-half, -ACTOR_SIZE_PX.y), feet + Vector2(half, -ACTOR_SIZE_PX.y),
			feet + Vector2(half, 0), feet + Vector2(-half, 0)])
		for face in faces:
			if face[1] <= feet.y:
				continue
			var area := 0.0
			for piece in Geometry2D.intersect_polygons(body, face[0]):
				area += absf(_signed_area(piece))
			if area >= min_overlap_px:
				hidden.append(cell)
				break
	return hidden


# --- internals --------------------------------------------------------------------------------

static func _signed_area(poly: PackedVector2Array) -> float:
	var sum := 0.0
	for i in poly.size():
		sum += poly[i].cross(poly[(i + 1) % poly.size()])
	return sum * 0.5



static func _canonicalize(points: PackedVector2Array) -> PackedVector2Array:
	var pts: Array[Vector2] = []
	for p in points:
		if pts.is_empty() or not pts[-1].is_equal_approx(p):
			pts.append(p)
	if pts.size() > 1 and pts[0].is_equal_approx(pts[-1]):
		pts.pop_back()
	# Drop collinear points (repeat: removing one can make its neighbour collinear).
	var changed := true
	while changed and pts.size() >= 3:
		changed = false
		for i in pts.size():
			var prev := pts[(i - 1 + pts.size()) % pts.size()]
			var next := pts[(i + 1) % pts.size()]
			if is_zero_approx((pts[i] - prev).cross(next - pts[i])):
				pts.remove_at(i)
				changed = true
				break
	if pts.size() < 4:
		return PackedVector2Array()
	for i in pts.size():
		var d := pts[(i + 1) % pts.size()] - pts[i]
		if not (is_zero_approx(d.x) or is_zero_approx(d.y)):
			return PackedVector2Array()
	var area := 0.0
	for i in pts.size():
		area += pts[i].cross(pts[(i + 1) % pts.size()])
	if area < 0.0:
		pts.reverse()
	var start := 0
	for i in pts.size():
		if pts[i].y < pts[start].y or (is_equal_approx(pts[i].y, pts[start].y) and pts[i].x < pts[start].x):
			start = i
	var out := PackedVector2Array()
	for i in pts.size():
		out.append(pts[(start + i) % pts.size()])
	return out


static func _tile_box(poly: PackedVector2Array) -> Rect2i:
	var lo := poly[0]
	var hi := poly[0]
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2i(Vector2i(floori(lo.x), floori(lo.y)), Vector2i(ceili(hi.x) - floori(lo.x), ceili(hi.y) - floori(lo.y)))


## Unit normal of edge a -> b pointing away from the floor (canonical outlines have positive area,
## so the floor is on the right of a -> b in y-down coordinates: outward is the left).
static func _outward_normal(a: Vector2, b: Vector2) -> Vector2:
	var d := (b - a).normalized()
	return Vector2(d.y, -d.x)


func _face(a: Vector2, b: Vector2) -> StringName:
	var outward := _outward_normal(a, b)
	if is_zero_approx(a.y - b.y):
		return &"N" if outward.y < 0.0 else &"low_S"
	return &"W" if outward.x < 0.0 else &"low_E"
