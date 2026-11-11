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

## How the floor fill meets the room's light pools (ADR-027, owner: "fill, keep the focal").
## ADD: on the floor a pool adds the fill (lift = pool + fill), so every pool stays one step above
## the filled floor and nothing gets darker than the fill (no ring). CLEAR: the fill is left out
## inside `fill_clear` outer radii of every pool, so pools keep their ADR-026 contrast against an
## unfilled surround (a dark ring between the pool and the filled floor).
enum FillMode { ADD, CLEAR }

@export_group("Shadows and floor fill (ADR-027)")
## Bake the room's shade map at entry (AO strips, contact and cast shadows; ShadeBaker) and draw
## Elias's contact shadow. Every lit room has it on (ADR-027); off keeps the ADR-026 look.
@export var shadows: bool = false
## Floor fill: lift on the floor receivers (indices 00-05 inside the room's floor: the iso floor
## polygon or the side platform strip, ShadeBaker.floor_shapes) so the open floor and its shadows
## read at A 2 (owner: "fill, keep the focal"). 0 = no fill. The fill never lifts the open floor
## back to its unlit value: at A 1 or 0 it is not applied (effective_fill), so a pool keeps a step.
@export_range(0, 1) var fill_lift: int = 0
@export var fill_mode: FillMode = FillMode.ADD
## CLEAR only: the fill is left out inside this many outer radii of every room light pool that
## lifts the floor, so the focal and helper pools keep their full contrast against the darker floor.
@export_range(1.0, 3.0, 0.05) var fill_clear: float = 1.5

@export_group("Elias zone")
## A small zone that follows Elias so his body stays readable without a spotlight around him
## (Sol, TLF-083 visual review b71c0a9; default for A 2 rooms).
@export var elias_zone: bool = true
## Zone centre relative to the player origin (his feet).
@export var elias_offset: Vector2 = Vector2(0, -20)
## Outer radius of the zone. With `elias_inner` 0.85 every body pixel of the iso and side sheets
## (outline 00 and shadow 01 aside) lies inside the inner band (normalized distance <= 0.82), and
## lifts 1/0 keep the body one ramp step down at A 2 with a small, weak floor footprint. Index
## masking cannot replace the zone: his trousers use 02/03, the floor's terrazzo (ART_BIBLE A.2).
## A 1 rooms keep 1/0; A 3 (maintenance) needs lift 2 and its own proof (Sol, TLF-082 §3).
@export var elias_radius: Vector2 = Vector2(18, 28)
@export_range(0, 3) var elias_lift_inner: int = 1
@export_range(0, 3) var elias_lift_outer: int = 0
@export_range(0.05, 1.0) var elias_inner: float = 0.85


## The fill the pass applies: `fill_lift`, at most A - 1 (TLF-084 r2, Fable P2-3: at A 1 a fill of
## 1 would return every floor pixel to its unlit value and leave no step for a light pool).
func effective_fill() -> int:
	return mini(fill_lift, maxi(ambient_steps - 1, 0))


## Empty when the values are inside the ADR-026 ranges; otherwise one message per problem.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if ambient_steps < 0 or ambient_steps > 3:
		errors.append("ambient_steps %d outside 0..3" % ambient_steps)
	if exempt_from < 25 or exempt_from > 32:
		errors.append("exempt_from %d outside 25..32 (index 24 is protected locally, ADR-026)" % exempt_from)
	if dither:
		errors.append("dither is not accepted yet (ADR-026, Sol TLF-082 §4)")
	if fill_lift < 0 or fill_lift > 1:
		errors.append("fill_lift %d outside 0..1 (ADR-027)" % fill_lift)
	if fill_clear < 1.0 or fill_clear > 3.0:
		errors.append("fill_clear %.2f outside 1..3 (the clear area covers at least the pool)" % fill_clear)
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
