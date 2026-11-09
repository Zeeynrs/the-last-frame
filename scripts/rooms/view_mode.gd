class_name ViewMode
extends RefCounted

## A room's view mode (ADR-025, TLF-074): `metadata/view_mode` (StringName) on the room root.
## RoomRouter reads it on room entry and hands it to the Player, the RoomCamera and DepthSort.
##
## - `iso` (default, every Chapter 1 room): 8-direction movement, 2:1 dimetric art, DepthSort.
## - `side`: a flat side-view scene (`metadata/side_view`, a SideView). Elias walks left/right on
##   one floor line, faces `e` or `w`, uses the side SpriteFrames; the camera only scrolls
##   horizontally; DepthSort is not applied.
## - `topdown`: reserved, not implemented; a room declaring it is treated as `iso`.

const ISO := &"iso"
const SIDE := &"side"
const TOPDOWN := &"topdown"


## The view mode `room` declares; `iso` when it declares none, or one that is not implemented.
static func of(room: Node) -> StringName:
	if room == null or not room.has_meta(&"view_mode"):
		return ISO
	var mode := StringName(str(room.get_meta(&"view_mode")))
	if mode == SIDE:
		return SIDE
	if mode != ISO:
		push_warning("ViewMode: room '%s' declares view_mode '%s', not implemented; using iso." % [room.name, mode])
	return ISO


## The side-view layout of a `side` room: its `metadata/side_view`, or the default one.
static func side_view_of(room: Node) -> SideView:
	if room != null and room.has_meta(&"side_view"):
		var spec := room.get_meta(&"side_view") as SideView
		if spec != null and spec.is_valid():
			return spec
	return SideView.new()
