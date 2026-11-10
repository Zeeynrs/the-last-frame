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

const LAYER := 1
const MAX_LIGHTS := 8
## Shader slots: the room lights plus the Elias zone.
const SLOTS := MAX_LIGHTS + 1
const SETTING := &"lighting_enabled"
const SHADER := preload("res://scripts/rendering/lighting/palette_lighting.gdshader")

var lighting: RoomLighting = null
var room: Node = null
var player: Node2D = null
## The room's lights in use (the first MAX_LIGHTS found).
var lights: Array[RoomLight] = []

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


## The lights in view pixels, in shader order (room lights, then the Elias zone).
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
			"mask": light.index_mask()}
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
			"inner": lighting.elias_inner, "mask": 0})
	return out


## The strongest lift at view pixel `p` for a pixel of palette `index` (the shader's rule).
func lift_at(p: Vector2, index: int, entries: Array[Dictionary] = []) -> int:
	if entries.is_empty():
		entries = screen_lights()
	var centre := p.floor() + Vector2(0.5, 0.5)
	var lift := 0
	for e in entries:
		var mask: int = e["mask"]
		if mask != 0 and ((mask >> index) & 1) == 0:
			continue
		var a: Vector4 = e["a"]
		var v := 0
		if e["kind"] == 0:
			var d := ((centre - Vector2(a.x, a.y)) / Vector2(a.z, a.w)).length()
			v = e["lift_in"] if d < e["inner"] else (e["lift_out"] if d < 1.0 else 0)
		elif _in_quad(centre, a, e["b"]):
			v = e["lift_in"]
		lift = maxi(lift, v)
	return lift


## The palette index the pass outputs at view pixel `p` for an input pixel of palette `index`.
func output_index(p: Vector2, index: int, entries: Array[Dictionary] = []) -> int:
	if not is_active():
		return index
	var k := clampi(lighting.ambient_steps - lift_at(p, index, entries), 0, 3)
	return shifted_index(index, k, lighting.exempt_from)


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
	if is_inside_tree():
		_material.set_shader_parameter("view_size", get_viewport().get_visible_rect().size)


func _update_visibility() -> void:
	visible = is_active() and settings_enabled()


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
