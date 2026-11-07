class_name DepthSort
extends RefCounted

## One sorting rule for upright bodies (ART_BIBLE A.1, ADR-019; TLF-066 audit, TLF-067).
##
## Anything that stands upright on the floor (gate, door, barrier, hatch, shutter, validator
## console, railing, interior pillar) draws in the actor layer (ACTOR_Z, the YSort_Actors z) and
## is Y-sorted with Elias, his echo and the NPCs at its floor contact: the position of the node
## that sorts it (an interactable's own position for its presenter, the sprite's position for a
## loose sprite). Elias then draws behind such a body when he stands north or west of its
## contact and in front of it when he stands south or east, like with every other actor.
## Wall modules and wall-mounted fixtures (z 5 / 7) and floor surfaces (plates, bridge, trench,
## z 8) are not upright bodies and keep their layers.
##
## The rule is keyed by art asset, not by object: every sprite showing an upright asset gets it,
## in every room, also ones placed later. RoomVisuals applies it when a room has finished loading.

## The actor layer: Elias, the echo ghost, NPCs and YSort_Actors (ADR-019).
const ACTOR_Z := 10

## Upright floor-standing art, by asset file name prefix. ASSET_METADATA lists the first six in
## YSort_Actors; the railing (listed with YSort_Props) and the corner pillar used as a free-standing
## interior pillar are upright bodies per ART_BIBLE A.1 (TLF-066 audit ranks 3 and 4).
const UPRIGHT_ASSETS: Array[String] = [
	"ch01_prop_platform_gate_",
	"ch01_prop_staff_door_",
	"ch01_prop_staff_barrier_",
	"ch01_prop_service_hatch_",
	"ch01_prop_fire_shutter_",
	"ch01_prop_ticket_validator_",
	"ch01_env_wall_railing_iron_",
	"ch01_env_wall_corner_pillar_",
]


static func is_upright_texture(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var file := texture.resource_path.get_file()
	for prefix in UPRIGHT_ASSETS:
		if file.begins_with(prefix):
			return true
	return false


## Puts every sprite under `root` that shows an upright asset into the actor layer. Returns how
## many sprites it moved. Presenters swap textures between states of the same asset, so the
## layer stays right after open/close, Rewind or Freeze.
static func apply(root: Node) -> int:
	var moved := 0
	for node in root.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if not is_upright_texture(sprite.texture):
			continue
		if sprite.z_as_relative or sprite.z_index != ACTOR_Z:
			sprite.z_as_relative = false
			sprite.z_index = ACTOR_Z
			moved += 1
	return moved
