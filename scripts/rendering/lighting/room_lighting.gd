class_name RoomLighting
extends Resource

## A room's lighting (ADR-026, TLF-083), stored as `metadata/lighting` on the room root. A room
## without it is unlit and looks exactly as today. The pass moves every pixel's palette index
## k = max(0, ambient_steps - lift) steps down its own material ramp; lift comes from the room's
## `RoomLight` nodes (at most 8) and the Elias zone below. Lights never brighten above the art.

## Ambient darkening in ramp steps (ADR-026 per-area values: 1 lounge/street exit/side memory,
## 2 most rooms, 3 maintenance).
@export_range(0, 3) var ambient_steps: int = 2
## Palette indices from this one up never shift (25: clock core, watch, tactile accents, temporal
## VFX, UI cyan). 24 is not allowed: information on index 24 is protected locally (RoomLight with
## `only_indices`), never by lowering the threshold (Sol, TLF-082 §2).
@export_range(25, 32) var exempt_from: int = 25
## Reserved: Bayer dithering across band edges is not accepted yet (Sol, TLF-082 §4); must stay off.
@export var dither: bool = false

@export_group("Elias zone")
## A zone that follows Elias so his whole 32 x 48 sprite stays readable (Sol, TLF-082 §3).
@export var elias_zone: bool = true
## Zone centre relative to the player origin (his feet).
@export var elias_offset: Vector2 = Vector2(0, -20)
## Outer radius of the zone. The inner band (`elias_inner` of it: 24 x 36 px) just covers the
## 32 x 48 sprite and the outer band is a thin 6-9 px ring, so the zone does not read as a
## spotlight moving with him (Sol, TLF-082 §4). Index masking cannot replace it: his trousers use
## 02/03, the floor's terrazzo indices (ART_BIBLE A.2).
@export var elias_radius: Vector2 = Vector2(30, 45)
@export_range(0, 3) var elias_lift_inner: int = 2
@export_range(0, 3) var elias_lift_outer: int = 1
@export_range(0.05, 1.0) var elias_inner: float = 0.8


## Empty when the values are inside the ADR-026 ranges; otherwise one message per problem.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if ambient_steps < 0 or ambient_steps > 3:
		errors.append("ambient_steps %d outside 0..3" % ambient_steps)
	if exempt_from < 25 or exempt_from > 32:
		errors.append("exempt_from %d outside 25..32 (index 24 is protected locally, ADR-026)" % exempt_from)
	if dither:
		errors.append("dither is not accepted yet (ADR-026, Sol TLF-082 §4)")
	if elias_zone:
		if elias_radius.x <= 0.0 or elias_radius.y <= 0.0:
			errors.append("elias_radius must be positive")
		if elias_lift_inner < 0 or elias_lift_inner > 3 or elias_lift_outer < 0 or elias_lift_outer > 3:
			errors.append("Elias zone lifts outside 0..3")
		if elias_lift_outer > elias_lift_inner:
			errors.append("Elias zone outer lift above the inner lift")
		if elias_inner <= 0.0 or elias_inner > 1.0:
			errors.append("elias_inner outside (0, 1]")
	return errors
