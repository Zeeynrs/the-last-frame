class_name RoomLight
extends Marker2D

## One motivated light of a lit room (ADR-026, TLF-083): a marker node under the room root.
## ELLIPSE: a pool centred on the node, `lift_inner` inside `inner` of the radius, `lift_outer` up
## to the radius (iso floor pools use 2:1 radii). QUAD: a convex region given by 4 local points,
## lifting `lift_inner` everywhere inside it; with `only_indices` it is an information region that
## restores only those palette indices (e.g. the departure-board LED glyphs, index 24) and never
## the floor, dado or wall around them. Lifts never add up: the strongest one at a pixel wins.

enum Shape { ELLIPSE, QUAD }

@export var shape: Shape = Shape.ELLIPSE
## ELLIPSE: outer radius in pixels.
@export var radius: Vector2 = Vector2(64, 32)
@export_range(0, 3) var lift_inner: int = 2
## ELLIPSE only; never above `lift_inner`.
@export_range(0, 3) var lift_outer: int = 1
## ELLIPSE: inner band edge as a fraction of the radius.
@export_range(0.05, 1.0) var inner: float = 0.55
## QUAD: four points relative to this node, in order around a convex area.
@export var quad: PackedVector2Array = PackedVector2Array()
## Palette indices this light may lift; empty = every index.
@export var only_indices: PackedInt32Array = PackedInt32Array()


## Bit i set = index i may be lifted; 0 = every index.
func index_mask() -> int:
	var mask := 0
	for i in only_indices:
		if i >= 0 and i < TlfPalette.SIZE:
			mask |= 1 << i
	return mask


## Empty when valid; otherwise one message per problem.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if lift_inner < 0 or lift_inner > 3 or lift_outer < 0 or lift_outer > 3:
		errors.append("%s: lifts outside 0..3" % name)
	for i in only_indices:
		if i < 0 or i >= TlfPalette.SIZE:
			errors.append("%s: only_indices has %d, outside 0..31" % [name, i])
	if shape == Shape.ELLIPSE:
		if radius.x <= 0.0 or radius.y <= 0.0:
			errors.append("%s: radius must be positive" % name)
		if lift_outer > lift_inner:
			errors.append("%s: outer lift above the inner lift" % name)
		if inner <= 0.0 or inner > 1.0:
			errors.append("%s: inner outside (0, 1]" % name)
	elif not is_convex_quad(quad):
		errors.append("%s: quad needs 4 points around a convex area" % name)
	elif not only_indices.is_empty() and lift_inner < 1:
		errors.append("%s: an information region (quad with only_indices) lifts at least 1 (ADR-027: never below the floor fill)" % name)
	return errors


static func is_convex_quad(points: PackedVector2Array) -> bool:
	if points.size() != 4:
		return false
	var sign := 0
	for i in 4:
		var a := points[i]
		var b := points[(i + 1) % 4]
		var c := points[(i + 2) % 4]
		var cross := (b - a).cross(c - b)
		if is_zero_approx(cross):
			return false
		var s := 1 if cross > 0.0 else -1
		if sign == 0:
			sign = s
		elif s != sign:
			return false
	return true
