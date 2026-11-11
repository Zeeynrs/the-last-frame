class_name LightingPass
extends CanvasLayer

## ADR-026 lighting pass (TLF-083): one full-screen palette shader on CanvasLayer 1, above the
## world canvas and under every UI layer (the HUD is on layer 2, the wheel on 15, dialogue on 70).
## RoomRouter hands it the current room on entry (`apply_room`): a room with `metadata/lighting`
## (RoomLighting) is lit by its RoomLight nodes (at most 8) and the Elias zone; a room without it,
## or the `lighting_enabled` setting off, hides the pass, which leaves today's look untouched.
## `reduced_effects` keeps the static lighting (nothing here animates).
##
## The rules live here as pure functions (`shifted_index`, `shift_table`, `lift_at`,
## `output_index`); the shader indexes the same table and mirrors `lift_at`.
##
## ADR-027 (TLF-084): a room with `shadows` gets a shade map baked when it is applied (ShadeBaker,
## world space, rebuilt on every room change, only while the pass is shown) and a contact ellipse
## under Elias that sits below his body. Floor receivers (RECEIVERS, indices 00-05) take the
## room's floor fill (cleared around its light pools) and the shade; the rule is
## k = clamp(A - max(lights, fill) + shade, 0, 3) (`output_index`). Information regions and indices
## from `exempt_from` up never take either.

const LAYER := 1
const MAX_LIGHTS := 8
## Shader slots: the room lights plus the Elias zone.
const SLOTS := MAX_LIGHTS + 1
const SETTING := &"lighting_enabled"
const SHADER := preload("res://scripts/rendering/lighting/palette_lighting.gdshader")
## Indices that take the floor fill and the shade: the terrazzo/void ramp 00-05 (ADR-027).
const RECEIVERS := 0b111111
## Elias's contact shadow (shade 1): an ellipse centred this far from his feet (player origin),
## low enough that no pixel of his iso or side frames lies inside it (ADR-027, readability first).
const ELIAS_CONTACT_OFFSET := Vector2(0, 4)
const ELIAS_CONTACT_RADIUS := Vector2(8, 4)

var lighting: RoomLighting = null
var room: Node = null
var player: Node2D = null
## The room's lights in use (the first MAX_LIGHTS found).
var lights: Array[RoomLight] = []
## The current room's shade map (L8, one texel per world pixel) or null; its world origin.
var shade_image: Image = null
var shade_origin := Vector2.ZERO
## The last bake: time in ms, and how many maps this pass has baked.
var bake_ms := 0.0
var bake_count := 0

var _shade_tex: ImageTexture = null
var _shade_room_id := 0
var _rect: ColorRect
var _material: ShaderMaterial
var _table_exempt := -1


func _init() -> void:
	name = "LightingPass"
	layer = LAYER
	visible = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	var palette: Array = []
	for c in TlfPalette.COLORS:
		palette.append(Vector3(c.r, c.g, c.b))
	_material.set_shader_parameter("palette", palette)
	_rect = ColorRect.new()
	_rect.name = "Pass"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.material = _material
	add_child(_rect)


func _ready() -> void:
	var settings := _settings()
	if settings != null and settings.has_signal(&"setting_changed"):
		settings.setting_changed.connect(_on_setting_changed)
	_update_visibility()


func _process(_delta: float) -> void:
	if visible:
		_refresh()


# --- the rules (pure functions) ----------------------------------------------------------

## `index` moved `k` steps down its own ramp; below the ramp's first entry it falls to 01, then 00
## (ART_BIBLE §4 step -2 shadows). Indices from `exempt_from` up never move.
static func shifted_index(index: int, k: int, exempt_from: int) -> int:
	if index >= exempt_from or k <= 0:
		return index
	var start := TlfPalette.ramp_start(index)
	var j := index - k
	if j >= start:
		return j
	if start == 0:
		return 0
	return 1 if start - j == 1 else 0


## `shifted_index(index, k)` for every index and k 0..3, as `table[index * 4 + k]` (the shader's table).
static func shift_table(exempt_from: int) -> PackedInt32Array:
	var table := PackedInt32Array()
	table.resize(TlfPalette.SIZE * 4)
	for index in TlfPalette.SIZE:
		for k in 4:
			table[index * 4 + k] = shifted_index(index, k, exempt_from)
	return table


## The RoomLight nodes under `root`, in tree order.
static func room_lights(root: Node) -> Array[RoomLight]:
	var out: Array[RoomLight] = []
	if root == null:
		return out
	for node in root.find_children("*", "RoomLight", true, false):
		out.append(node as RoomLight)
	return out


## Empty when the room's lighting is valid: the RoomLighting ranges, at most MAX_LIGHTS lights,
## every light valid and inside `bounds` (ellipse centre / every quad point, in room pixels).
static func validate_room(root: Node, room_lighting: RoomLighting, bounds: Rect2) -> PackedStringArray:
	var errors := PackedStringArray()
	if room_lighting == null:
		return errors
	errors.append_array(room_lighting.validate())
	var found := room_lights(root)
	if found.size() > MAX_LIGHTS:
		errors.append("%d RoomLight nodes, at most %d" % [found.size(), MAX_LIGHTS])
	for light in found:
		errors.append_array(light.validate())
		var points: Array[Vector2] = [light.global_position]
		if light.shape == RoomLight.Shape.QUAD:
			points.clear()
			for q in light.quad:
				points.append(light.global_transform * q)
		for p in points:
			if not bounds.grow(0.5).has_point(p):
				errors.append("%s: %s outside the room bounds %s" % [light.name, p, bounds])
	return errors


# --- applying a room ---------------------------------------------------------------------

## Lights `p_room` with `p_lighting` (null: unlit, the pass hides). Called by RoomRouter on entry.
func apply_room(p_room: Node, p_lighting: RoomLighting, p_player: Node2D) -> void:
	room = p_room
	lighting = p_lighting
	player = p_player
	lights.clear()
	if room != null and lighting != null:
		var found := room_lights(room)
		if found.size() > MAX_LIGHTS:
			push_warning("LightingPass: %s has %d RoomLight nodes; only the first %d are used." % [room.name, found.size(), MAX_LIGHTS])
		for light in found:
			if lights.size() < MAX_LIGHTS:
				lights.append(light)
	_drop_shade()
	_update_visibility()
	if visible:
		_refresh()


func clear() -> void:
	apply_room(null, null, null)


## True when a lit room is applied (whatever the setting says).
func is_active() -> bool:
	return lighting != null and room != null and is_instance_valid(room)


func settings_enabled() -> bool:
	var settings := _settings()
	if settings != null and SETTING in settings:
		return bool(settings.get(SETTING))
	return true


## True when the current room's shade map is in use.
func shadows_active() -> bool:
	return is_active() and lighting.shadows and shade_image != null


## The shade map's texel (0,0) in view pixels and the view pixels per texel.
func shade_screen_rect() -> Vector4:
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	var o := (xf * shade_origin).round()
	var s := xf.get_scale()
	return Vector4(o.x, o.y, s.x, s.y)


## Elias's contact ellipse in view pixels (centre, radius); far off screen when there is none.
func elias_contact() -> Vector4:
	if not shadows_active() or player == null or not is_instance_valid(player):
		return Vector4(-9999, -9999, 1, 1)
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	var c := (xf * (player.global_position + ELIAS_CONTACT_OFFSET)).round()
	var s := xf.get_scale()
	return Vector4(c.x, c.y, ELIAS_CONTACT_RADIUS.x * s.x, ELIAS_CONTACT_RADIUS.y * s.y)


## The lights in view pixels, in shader order (room lights, then the Elias zone). Room lights carry
## "room": true (their pools clear the floor fill); the Elias zone does not.
func screen_lights() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not is_active():
		return out
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	var scale := xf.get_scale()
	for light in lights:
		if not is_instance_valid(light) or not light.is_inside_tree():
			continue
		var entry := {"lift_in": light.lift_inner, "lift_out": light.lift_outer, "inner": light.inner,
			"mask": light.index_mask(), "room": true}
		if light.shape == RoomLight.Shape.QUAD:
			var pts: Array[Vector2] = []
			for q in light.quad:
				pts.append((xf * (light.global_transform * q)).round())
			entry["kind"] = 1
			entry["a"] = Vector4(pts[0].x, pts[0].y, pts[1].x, pts[1].y)
			entry["b"] = Vector4(pts[2].x, pts[2].y, pts[3].x, pts[3].y)
		else:
			var c := (xf * light.global_position).round()
			entry["kind"] = 0
			entry["a"] = Vector4(c.x, c.y, light.radius.x * scale.x, light.radius.y * scale.y)
			entry["b"] = Vector4.ZERO
		out.append(entry)
	if lighting.elias_zone and player != null and is_instance_valid(player):
		var c := (xf * (player.global_position + lighting.elias_offset)).round()
		out.append({"kind": 0, "a": Vector4(c.x, c.y, lighting.elias_radius.x * scale.x, lighting.elias_radius.y * scale.y),
			"b": Vector4.ZERO, "lift_in": lighting.elias_lift_inner, "lift_out": lighting.elias_lift_outer,
			"inner": lighting.elias_inner, "mask": 0, "room": false})
	return out


## The strongest light lift at view pixel `p` for a pixel of palette `index` (the shader's rule,
## without the floor fill).
func lift_at(p: Vector2, index: int, entries: Array[Dictionary] = []) -> int:
	return light_terms(p, index, entries)["lift"]


## The light loop of the shader at view pixel `p` for palette `index`: {lift (strongest light),
## info (an information region restores this pixel), clear (inside a room pool's fill-clear area)}.
func light_terms(p: Vector2, index: int, entries: Array[Dictionary] = []) -> Dictionary:
	if entries.is_empty():
		entries = screen_lights()
	var centre := p.floor() + Vector2(0.5, 0.5)
	var clear_at := lighting.fill_clear if lighting != null else 1.0
	var lift := 0
	var info := false
	var clear := false
	for e in entries:
		var mask: int = e["mask"]
		if mask != 0 and ((mask >> index) & 1) == 0:
			continue
		var a: Vector4 = e["a"]
		var v := 0
		if e["kind"] == 0:
			var d := ((centre - Vector2(a.x, a.y)) / Vector2(a.z, a.w)).length()
			v = e["lift_in"] if d < e["inner"] else (e["lift_out"] if d < 1.0 else 0)
			clear = clear or (e.get("room", true) and d < clear_at)
		elif _in_quad(centre, a, e["b"]):
			v = e["lift_in"]
			info = info or mask != 0
		lift = maxi(lift, v)
	return {"lift": lift, "info": info, "clear": clear}


## The floor fill at view pixel `p` for palette `index`: the room's fill_lift on a receiver outside
## every information region and every pool's clear area, else 0.
func fill_at(p: Vector2, index: int, entries: Array[Dictionary] = []) -> int:
	if not is_active():
		return 0
	return _fill(light_terms(p, index, entries), index)


## The shade (extra ramp steps) at view pixel `p` for palette `index`: the shade map texel under it,
## at least 1 inside Elias's contact ellipse; 0 off the receivers or inside an information region.
func shade_at(p: Vector2, index: int, entries: Array[Dictionary] = []) -> int:
	if not shadows_active():
		return 0
	return _shade(p, index, light_terms(p, index, entries))


## The palette index the pass outputs at view pixel `p` for an input pixel of palette `index`:
## k = clamp(A - max(light lift, fill) + shade, 0, 3) steps down its ramp.
func output_index(p: Vector2, index: int, entries: Array[Dictionary] = []) -> int:
	if not is_active():
		return index
	var terms := light_terms(p, index, entries)
	var lift := maxi(terms["lift"], _fill(terms, index))
	var shade := _shade(p, index, terms) if shadows_active() else 0
	var k := clampi(lighting.ambient_steps - lift + shade, 0, 3)
	return shifted_index(index, k, lighting.exempt_from)


func _fill(terms: Dictionary, index: int) -> int:
	if lighting.fill_lift <= 0 or ((RECEIVERS >> index) & 1) == 0 or terms["info"] or terms["clear"]:
		return 0
	return lighting.fill_lift


func _shade(p: Vector2, index: int, terms: Dictionary) -> int:
	if ((RECEIVERS >> index) & 1) == 0 or terms["info"]:
		return 0
	var centre := p.floor() + Vector2(0.5, 0.5)
	var r := shade_screen_rect()
	var t := ((centre - Vector2(r.x, r.y)) / Vector2(r.z, r.w)).floor()
	var s := 0
	if t.x >= 0 and t.y >= 0 and t.x < shade_image.get_width() and t.y < shade_image.get_height():
		s = shade_image.get_pixel(int(t.x), int(t.y)).r8
	var c := elias_contact()
	if ((centre - Vector2(c.x, c.y)) / Vector2(c.z, c.w)).length() < 1.0:
		s = maxi(s, 1)
	return s


# --- internals -----------------------------------------------------------------------------

func _refresh() -> void:
	if not is_active():
		return
	if lighting.exempt_from != _table_exempt:
		_table_exempt = lighting.exempt_from
		_material.set_shader_parameter("shift_table", shift_table(_table_exempt))
	var entries := screen_lights()
	var kinds := PackedInt32Array()
	var lift_in := PackedInt32Array()
	var lift_out := PackedInt32Array()
	var masks := PackedInt32Array()
	var inners := PackedFloat32Array()
	var a_list: Array = []
	var b_list: Array = []
	for i in SLOTS:
		var e: Dictionary = entries[i] if i < entries.size() else {}
		kinds.append(e.get("kind", 0))
		lift_in.append(e.get("lift_in", 0))
		lift_out.append(e.get("lift_out", 0))
		masks.append(e.get("mask", 0))
		inners.append(e.get("inner", 0.55))
		a_list.append(e.get("a", Vector4(-9999, -9999, 1, 1)))
		b_list.append(e.get("b", Vector4.ZERO))
	_material.set_shader_parameter("ambient_steps", lighting.ambient_steps)
	_material.set_shader_parameter("light_count", entries.size())
	_material.set_shader_parameter("light_kind", kinds)
	_material.set_shader_parameter("light_a", a_list)
	_material.set_shader_parameter("light_b", b_list)
	_material.set_shader_parameter("light_lift_in", lift_in)
	_material.set_shader_parameter("light_lift_out", lift_out)
	_material.set_shader_parameter("light_inner", inners)
	_material.set_shader_parameter("light_mask", masks)
	var room_count := 0
	for e in entries:
		if e.get("room", true):
			room_count += 1
	_material.set_shader_parameter("room_light_count", room_count)
	_material.set_shader_parameter("receivers", RECEIVERS)
	_material.set_shader_parameter("fill_lift", lighting.fill_lift)
	_material.set_shader_parameter("fill_clear", lighting.fill_clear)
	_material.set_shader_parameter("shade_on", 1 if shadows_active() else 0)
	if shadows_active():
		_material.set_shader_parameter("shade_rect", shade_screen_rect())
		_material.set_shader_parameter("shade_size", Vector2i(shade_image.get_width(), shade_image.get_height()))
		_material.set_shader_parameter("actor_shade", elias_contact())
	if is_inside_tree():
		_material.set_shader_parameter("view_size", get_viewport().get_visible_rect().size)


## Bakes the current room's shade map once per room, only while the pass is shown (a hidden pass,
## e.g. the setting off, costs nothing at room entry).
func _ensure_shade() -> void:
	if not visible or not is_active() or not lighting.shadows:
		return
	if shade_image != null and _shade_room_id == room.get_instance_id():
		return
	var r := ShadeBaker.bake(room as Node2D)
	shade_image = r["image"]
	shade_origin = r["origin"]
	bake_ms = r["ms"]
	bake_count += 1
	_shade_room_id = room.get_instance_id()
	_shade_tex = ImageTexture.create_from_image(shade_image)
	_material.set_shader_parameter("shade_map", _shade_tex)


func _drop_shade() -> void:
	shade_image = null
	_shade_tex = null
	_shade_room_id = 0
	_material.set_shader_parameter("shade_map", null)
	_material.set_shader_parameter("shade_on", 0)


func _update_visibility() -> void:
	visible = is_active() and settings_enabled()
	_ensure_shade()


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == SETTING:
		_update_visibility()
		if visible:
			_refresh()


func _settings() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Settings")


static func _in_quad(p: Vector2, a: Vector4, b: Vector4) -> bool:
	var pts := [Vector2(a.x, a.y), Vector2(a.z, a.w), Vector2(b.x, b.y), Vector2(b.z, b.w)]
	var pos := true
	var neg := true
	for i in 4:
		var u: Vector2 = pts[i]
		var v: Vector2 = pts[(i + 1) % 4]
		var c := (v.x - u.x) * (p.y - u.y) - (v.y - u.y) * (p.x - u.x)
		pos = pos and c >= 0.0
		neg = neg and c <= 0.0
	return pos or neg
