class_name RoomCamera
extends Camera2D

## Follow camera for the current room (ADR-023 R1). It centres on `target`, clamped so the view
## never leaves `bounds`, at whole-pixel positions only (no sub-pixel scroll, no smoothing).
##
## Per axis: when the bounds are wider (taller) than the view, the centre follows the target and is
## clamped to the bounds; when they fit in the view, the centre is fixed at the value closest to
## the legacy screen centre (320, 180) that still shows all of the bounds. A room that fits the
## screen therefore keeps exactly today's view (camera at (320, 180) = no transform), and a small
## room off that position is shown whole without scrolling.
## RoomRouter calls set_bounds() and snap_now() after every placement (room entry, door, restore).

var target: Node2D = null
var bounds: Rect2 = Rect2()


func _init() -> void:
	name = "RoomCamera"
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	position_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	ignore_rotation = true
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	bounds = Rect2(Vector2.ZERO, view_size())


## The internal canvas (ADR-003: 640 x 360), independent of the window size.
static func view_size() -> Vector2:
	return Vector2(ProjectSettings.get_setting("display/window/size/viewport_width", 640),
		ProjectSettings.get_setting("display/window/size/viewport_height", 360))


func set_bounds(r: Rect2) -> void:
	bounds = r if r.has_area() else Rect2(Vector2.ZERO, view_size())


## Whole-pixel camera centre for a target at `point` inside `bounds`.
func centre_for(point: Vector2) -> Vector2:
	var view := view_size()
	var legacy := view * 0.5
	return Vector2(_axis(point.x, bounds.position.x, bounds.end.x, view.x, legacy.x),
		_axis(point.y, bounds.position.y, bounds.end.y, view.y, legacy.y))


## Puts the camera on the target now and applies it on this frame (room entry, restore).
func snap_now() -> void:
	if target != null and is_instance_valid(target):
		position = centre_for(target.global_position)
	if is_inside_tree():
		reset_smoothing()
		force_update_scroll()


## The rectangle of the world the view shows with the camera at its current position.
func view_rect() -> Rect2:
	var view := view_size()
	return Rect2(position - view * 0.5, view)


func _physics_process(_delta: float) -> void:
	if target != null and is_instance_valid(target):
		position = centre_for(target.global_position)


static func _axis(p: float, lo: float, hi: float, view: float, legacy: float) -> float:
	var half := view * 0.5
	var low := lo + half    # smallest centre that keeps the view inside [lo, hi]
	var high := hi - half   # largest one
	if high >= low:
		return _clamp_whole(roundf(p), low, high)
	# The bounds fit in the view: any centre in [high, low] shows them whole; prefer the legacy one.
	return _clamp_whole(legacy, high, low)


## Clamps `value` to the whole numbers in [a, b]; the nearest whole number to the middle when the
## range holds none.
static func _clamp_whole(value: float, a: float, b: float) -> float:
	var lo := ceilf(a)
	var hi := floorf(b)
	if lo > hi:
		return roundf((a + b) * 0.5)
	return clampf(roundf(value), lo, hi)
