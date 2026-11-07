extends "res://tests/support/ch01_real_input.gd"

## TLF-067: sorting and pivots in Chapter 1, data-driven from the TLF-066 audit
## (docs/reviews/TLF-066/audit.csv, positions from render_manifest.json, canonical pivots from
## design/art/ASSET_METADATA.md). Rooms are the production scenes, loaded by the real
## Chapter01 / RoomRouter, with the real Player (Elias) and the real echo ghost as probes.
##
## Draw order is checked on Godot's sort keys, the way the 2D renderer orders canvas items:
## first the effective z (z_index summed up the z_as_relative chain), then, at equal z, the y of
## the item's sort node. The sort node is the highest node below ChapterRoot whose parent chain
## is all y_sort_enabled (Godot flattens nested y-sort; a child of a non-y-sorted node draws at
## that node's y). Headless runs do not rasterise, so pixels are not compared here; TLF-066 did
## that windowed for the baseline.
##
## Rows: fix_owner = data with severity high or medium (the audit's actionable rows), except the
## two atrium benches held for a Lead decision. Placement rows belong to Flash and are not tested.

const CSV_PATH := "res://docs/reviews/TLF-066/audit.csv"
const MANIFEST_PATH := "res://docs/reviews/TLF-066/render_manifest.json"
const METADATA_PATH := "res://design/art/ASSET_METADATA.md"
const ACTOR_Z := 10
## Lead decision pending (audit rank 7): not changed, not tested.
const HELD := ["visual:YSort_Actors/AtriumBenchE", "visual:YSort_Actors/AtriumBenchW"]
## Upright floor-standing art (ART_BIBLE A.1): ASSET_METADATA lists the gate, door, barrier, hatch,
## shutter and validator in YSort_Actors; the railing and the interior pillar are the audit's
## upright bodies (rank 3, 4). Kept separate from DepthSort's own table on purpose.
const UPRIGHT_ASSETS: Array[String] = ["ch01_prop_platform_gate_", "ch01_prop_staff_door_", "ch01_prop_staff_barrier_",
	"ch01_prop_service_hatch_", "ch01_prop_fire_shutter_", "ch01_prop_ticket_validator_",
	"ch01_env_wall_railing_iron_", "ch01_env_wall_corner_pillar_"]
## Audit probe displacements from the object's contact (room cardinal sides).
const SIDES := {"N": Vector2(16, -8), "S": Vector2(-16, 8), "E": Vector2(16, 8), "W": Vector2(-16, -8)}

var _rows: Array = []        # actionable data rows: {room, object_id, overlaps}
var _anchors: Dictionary = {}  # "room|object_id" -> contact (Vector2) from the manifest
var _pivots: Dictionary = {}   # texture file name -> canonical pivot (Vector2)


func _init() -> void:
	timeout_frames = 3600


func _load_audit() -> bool:
	_rows.clear()
	_anchors.clear()
	_pivots.clear()
	var csv := FileAccess.open(CSV_PATH, FileAccess.READ)
	if not _assert_true(csv != null, "audit CSV readable"):
		return false
	var header := csv.get_csv_line()
	while not csv.eof_reached():
		var line := csv.get_csv_line()
		if line.size() != header.size():
			continue
		var row := {}
		for i in header.size():
			row[header[i]] = line[i]
		if row["fix_owner"] == "data" and row["severity"] in ["high", "medium"] and not HELD.has(row["object_id"]):
			_rows.append({"room": StringName(row["room"]), "object_id": row["object_id"], "overlaps": row["overlaps_elias_from"]})
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	for room in manifest["rooms"]:
		for object in room["objects"]:
			_anchors["ch01.%s|%s" % [room["room"], object["object_id"]]] = Vector2(object["anchor"][0], object["anchor"][1])
	var meta := FileAccess.open(METADATA_PATH, FileAccess.READ)
	var pivot_re := RegEx.create_from_string("^\\(\\s*(-?\\d+),\\s*(-?\\d+)\\)$")
	while not meta.eof_reached():
		var text := meta.get_line()
		if not (text.begins_with("| **") and text.contains(".png")):
			continue
		var file := ""
		var pivot = null
		for cell in text.split("|"):
			var c := cell.strip_edges().trim_prefix("`").trim_suffix("`")
			if c.ends_with(".png") and file.is_empty():
				file = c.get_file()
			var m := pivot_re.search(c)
			if m != null and pivot == null:
				pivot = Vector2(int(m.get_string(1)), int(m.get_string(2)))
		if not file.is_empty() and pivot != null:
			_pivots[file] = pivot
	return _assert_eq(_rows.size(), 37, "37 actionable data rows (39 minus the 2 held benches)")


var _player_layer: int = 0


## Chapter 1 on the arrival platform. Elias is taken off the physics layer the triggers watch, so
## teleporting him to probe spots never fires a door, checkpoint or pickup.
func _start() -> bool:
	if not _load_audit():
		return false
	if not await start_at(&"ch01.arrival_platform", &""):
		return false
	_player_layer = player.collision_layer
	player.collision_layer = 0
	await physics_frames(2)
	return true


func _stop() -> void:
	if player != null and is_instance_valid(player):
		player.collision_layer = _player_layer
	stop()


func _enter(room: StringName) -> void:
	if router.current_room_id != room:
		router.enter_room(room)
	await physics_frames(2)


## The node a row names: a registered object id, or "visual:<path in the room>".
func _object(row: Dictionary) -> Node:
	var id: String = row["object_id"]
	if id.begins_with("visual:"):
		return router.current_room.get_node_or_null(id.trim_prefix("visual:"))
	return resolve(StringName(id))


## The sprites that draw the object (the node itself if it is one).
func _sprites(node: Node) -> Array:
	var out: Array = []
	if node is Sprite2D:
		out.append(node)
	for child in node.find_children("*", "Sprite2D", true, false):
		if (child as Sprite2D).texture != null:
			out.append(child)
	return out


static func effective_z(item: CanvasItem) -> int:
	var z := 0
	var n: Node = item
	while n is CanvasItem:
		z += (n as CanvasItem).z_index
		if not (n as CanvasItem).z_as_relative:
			break
		n = n.get_parent()
	return z


## See the class comment. `root` is ChapterRoot (y-sorted).
static func sort_node(item: Node, root: Node) -> Node2D:
	var path: Array = []
	var n := item
	while n != null and n != root:
		path.push_front(n)
		n = n.get_parent()
	for node in path:
		if not (node is CanvasItem and (node as CanvasItem).y_sort_enabled):
			return node as Node2D
	return item as Node2D


## True when `a` draws after (in front of) `b`; ties count as false.
func _draws_after(a: CanvasItem, b: CanvasItem) -> bool:
	var za := effective_z(a)
	var zb := effective_z(b)
	if za != zb:
		return za > zb
	return sort_node(a, ch01).global_position.y > sort_node(b, ch01).global_position.y


## For every probe side: a probe north or west of the contact (behind the body) is drawn first,
## south or east of it (in front) last. Returns the failing "side: sprite" labels.
func _wrong_sides(probe: Node2D, sprites: Array, contact: Vector2) -> Array:
	var home := probe.global_position
	var wrong: Array = []
	for side in SIDES:
		probe.global_position = contact + SIDES[side]
		for sprite in sprites:
			var probe_in_front := _draws_after(probe, sprite)
			if probe_in_front != (side == "S" or side == "E"):
				wrong.append("%s:%s" % [side, sprite.name])
	probe.global_position = home
	return wrong


## The plan's test: every actionable row that TLF-066 found drawing on the wrong side of Elias,
## probed with Elias and with the echo ghost at the audit's four sides of its contact.
func test_probe_actor_sorts_correctly_at_all_four_sides() -> void:
	if not await _start():
		_stop()
		return
	var ghost: Node2D = player.pocket_watch._ghost_node
	if not _assert_true(ghost != null and ghost.is_inside_tree(), "the echo ghost exists in the chapter"):
		_stop()
		return
	var checked := 0
	for row in _rows:
		if row["overlaps"] in ["none observed", "N/A"]:
			continue
		await _enter(row["room"])
		var node := _object(row)
		var label := "%s %s" % [String(row["room"]).trim_prefix("ch01."), row["object_id"]]
		if not _assert_true(node != null, "%s exists" % label):
			continue
		var key := "%s|%s" % [row["room"], row["object_id"]]
		var contact: Vector2 = _anchors.get(key, Vector2.INF)
		var sprites := _sprites(node)
		_assert_true(not sprites.is_empty(), "%s has a sprite" % label)
		for sprite in sprites:
			_assert_eq(sort_node(sprite, ch01).global_position, contact, "%s: %s sorts at the audited contact" % [label, sprite.name])
		_assert_eq(_wrong_sides(player, sprites, contact), [], "%s: Elias on the right side at N, S, E, W" % label)
		_assert_eq(_wrong_sides(ghost, sprites, contact), [], "%s: the echo ghost on the right side at N, S, E, W" % label)
		checked += 1
	_assert_eq(checked, 30, "30 overlap rows probed (7 objects, 23 railings)")
	_stop()


## The pivot rows (and the overlap rows' sprites): the drawn sprite's contact is the node origin,
## i.e. -get_rect().position equals the asset's canonical pivot, for every texture the presenter
## can show (closed / open / pressed ... states).
func test_actionable_sprites_use_the_canonical_pivot() -> void:
	if not await _start():
		_stop()
		return
	var checked := 0
	for row in _rows:
		await _enter(row["room"])
		var node := _object(row)
		var label := "%s %s" % [String(row["room"]).trim_prefix("ch01."), row["object_id"]]
		if not _assert_true(node != null, "%s exists" % label):
			continue
		for sprite in _sprites(node):
			var textures: Array = [sprite.texture]
			for property in ["tex_closed", "tex_open", "tex_released", "tex_pressed", "tex_idle", "tex_accepted", "tex_buzzing", "textures"]:
				var value = sprite.get(property)
				for texture in (value if value is Array else [value]):
					if texture is Texture2D and not textures.has(texture):
						textures.append(texture)
			var shown: Texture2D = sprite.texture
			for texture in textures:
				var file: String = texture.resource_path.get_file()
				if not _assert_true(_pivots.has(file), "%s: %s has a canonical pivot in ASSET_METADATA" % [label, file]):
					continue
				sprite.texture = texture
				_assert_eq(-sprite.get_rect().position, _pivots[file], "%s: %s drawn at its canonical pivot" % [label, file])
				checked += 1
			sprite.texture = shown
	_assert_true(checked >= 37, "%d sprite textures checked" % checked)
	_stop()


## The rule itself, in all ten rooms: every sprite of an upright floor-standing asset is in the
## actor layer (also the ones the audit could not probe, e.g. the niche grille), and Elias and the
## echo ghost are in the same layer and y-sort space.
func test_upright_bodies_echo_and_elias_share_the_actor_layer_in_every_room() -> void:
	if not await _start():
		_stop()
		return
	var ghost: Node2D = player.pocket_watch._ghost_node
	_assert_eq(effective_z(player), ACTOR_Z, "Elias in the actor layer")
	_assert_eq(effective_z(ghost), ACTOR_Z, "the echo ghost in the actor layer, like Elias")
	_assert_true(sort_node(player, ch01) == player and sort_node(ghost, ch01) == ghost,
		"Elias and the echo ghost each sort by their own feet in ChapterRoot's y-sort")
	var upright := 0
	for room in [&"ch01.arrival_platform", &"ch01.concourse_west", &"ch01.maintenance_bay", &"ch01.security_crossing",
			&"ch01.waiting_lounge", &"ch01.signal_control", &"ch01.upper_vestibule", &"ch01.vestibule_niche",
			&"ch01.station_atrium", &"ch01.street_exit"]:
		await _enter(room)
		for sprite in router.current_room.find_children("*", "Sprite2D", true, false):
			if sprite.texture == null or not UPRIGHT_ASSETS.any(func(stem: String) -> bool: return sprite.texture.resource_path.get_file().begins_with(stem)):
				continue
			upright += 1
			_assert_eq(effective_z(sprite), ACTOR_Z, "%s %s: upright body in the actor layer" % [room, sprite.get_path()])
	_assert_true(upright >= 30, "%d upright sprites found" % upright)
	_stop()
