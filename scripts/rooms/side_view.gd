class_name SideView
extends Resource

## Layout of a side-view scene (ADR-025, TLF-074), stored as `metadata/side_view` on a room root
## whose `metadata/view_mode` is `&"side"`. Composition per ASSET_METADATA 13.1: a 960 x 540 canvas
## with 90 px letterbox bars and the walkable floor line at screen y 394. A scene wider than the
## screen scrolls horizontally (RoomCamera.horizontal_only).
##
## Elias's feet stay on `floor_y`; he walks between walk_min_x() and walk_max_x(). Everything that
## places him in the scene (doors, anchors, checkpoints, load) goes through snap().

## Canvas height of every side scene: the 960 x 540 view (no vertical scroll).
const HEIGHT := 540.0

## The walkable floor line (feet y), in scene pixels.
@export var floor_y: float = 394.0
## Scene width in pixels from x = 0; at least the 960 px view.
@export var width: float = 960.0
## Elias's feet stay this far from the left and right scene edges.
@export var walk_margin: float = 16.0


func is_valid() -> bool:
	return width > 2.0 * walk_margin and floor_y > 0.0 and floor_y < HEIGHT


## Camera bounds: the whole scene, 540 px tall.
func bounds_px() -> Rect2:
	return Rect2(0.0, 0.0, width, HEIGHT)


func walk_min_x() -> float:
	return walk_margin


func walk_max_x() -> float:
	return width - walk_margin


## `p` moved onto the floor line, inside the walkable range.
func snap(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, walk_min_x(), walk_max_x()), floor_y)
