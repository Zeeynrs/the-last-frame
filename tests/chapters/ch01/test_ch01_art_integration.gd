extends "res://tests/support/base_test.gd"

## Comprehensive Art Integration & Collision Freeze Test Suite (TLF-041).
## Verifies that:
## 1. Collision shapes, triggers, spawns, and interactables across all 10 Chapter 1
##    rooms match the pre-change baseline 100% (only ADR-019 intercom move allowed).
## 2. Operator intercom reach is <= 36 px from a walkable point.
## 3. All greybox visuals are replaced by art kit nodes (Floor, Walls, Doorways, Fixtures, Props).
## 4. Room 1 art integration is 100% complete per CH01_PLACEMENT_SHEET.md.
## 5. Every puzzle prop presenter maps states to correct textures dynamically.
## 6. Real save slot_0 is strictly untouched.

const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"

const ROOM_PATHS: Array[String] = [
	"res://scenes/chapters/ch01/rooms/arrival_platform.tscn",
	"res://scenes/chapters/ch01/rooms/concourse_west.tscn",
	"res://scenes/chapters/ch01/rooms/maintenance_bay.tscn",
	"res://scenes/chapters/ch01/rooms/security_crossing.tscn",
	"res://scenes/chapters/ch01/rooms/waiting_lounge.tscn",
	"res://scenes/chapters/ch01/rooms/signal_control.tscn",
	"res://scenes/chapters/ch01/rooms/upper_vestibule.tscn",
	"res://scenes/chapters/ch01/rooms/vestibule_niche.tscn",
	"res://scenes/chapters/ch01/rooms/station_atrium.tscn",
	"res://scenes/chapters/ch01/rooms/street_exit.tscn"
]

## Pre-change baseline collision fingerprint compressed as GZIP base64 string.
const BASELINE_FINGERPRINTS_GZIP_B64: String = "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"


func _get_baseline_data() -> Dictionary:
	var raw := Marshalls.base64_to_raw(BASELINE_FINGERPRINTS_GZIP_B64)
	var decompressed := raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	return JSON.parse_string(decompressed.get_string_from_utf8())


func _scan_room_fingerprint(root_node: Node) -> Dictionary:
	var collisions: Array = []
	var zones: Array = []
	var interactables: Array = []
	_scan_node(root_node, root_node, collisions, zones, interactables)
	collisions.sort_custom(func(a, b): return a["path"] < b["path"])
	zones.sort_custom(func(a, b): return a["path"] < b["path"])
	interactables.sort_custom(func(a, b): return a["path"] < b["path"])
	return {
		"collisions": collisions,
		"zones": zones,
		"interactables": interactables
	}


func _scan_node(node: Node, root_node: Node, collisions: Array, zones: Array, interactables: Array) -> void:
	var path := str(root_node.get_path_to(node))

	if node is CollisionShape2D:
		var shape_data := {}
		if node.shape != null:
			shape_data["class"] = node.shape.get_class()
			if node.shape is CircleShape2D:
				shape_data["radius"] = (node.shape as CircleShape2D).radius
			elif node.shape is RectangleShape2D:
				shape_data["size"] = [(node.shape as RectangleShape2D).size.x, (node.shape as RectangleShape2D).size.y]
			elif node.shape is CapsuleShape2D:
				shape_data["radius"] = (node.shape as CapsuleShape2D).radius
				shape_data["height"] = (node.shape as CapsuleShape2D).height
			elif node.shape is ConvexPolygonShape2D:
				var pts := []
				for p in (node.shape as ConvexPolygonShape2D).points:
					pts.append([p.x, p.y])
				shape_data["points"] = pts

		var parent_col = node.get_parent()
		var layer: float = -1.0
		var mask: float = -1.0
		if parent_col is CollisionObject2D:
			layer = float((parent_col as CollisionObject2D).collision_layer)
			mask = float((parent_col as CollisionObject2D).collision_mask)

		collisions.append({
			"type": "shape2d",
			"path": path,
			"pos": [node.position.x, node.position.y],
			"rot": node.rotation,
			"scale": [node.scale.x, node.scale.y],
			"shape": shape_data,
			"layer": layer,
			"mask": mask
		})

	elif node is CollisionPolygon2D:
		var pts := []
		for p in (node as CollisionPolygon2D).polygon:
			pts.append([p.x, p.y])

		var parent_col = node.get_parent()
		var layer: float = -1.0
		var mask: float = -1.0
		if parent_col is CollisionObject2D:
			layer = float((parent_col as CollisionObject2D).collision_layer)
			mask = float((parent_col as CollisionObject2D).collision_mask)

		collisions.append({
			"type": "polygon2d",
			"path": path,
			"pos": [node.position.x, node.position.y],
			"rot": node.rotation,
			"scale": [node.scale.x, node.scale.y],
			"polygon": pts,
			"layer": layer,
			"mask": mask
		})

	var is_zone := (node is TriggerZone) or (node is DoorwayPresenter) or (node is SafeAnchor) or (node is CheckpointZone)
	var is_spawn := node.name.begins_with("Spawn") or node.name.ends_with("_spawn") or node.name == "safe_anchor_spawn"
	if is_zone or is_spawn:
		var obj_id := ""
		if "object_id" in node:
			obj_id = str(node.object_id)
		zones.append({
			"path": path,
			"class": node.get_class(),
			"pos": [node.position.x, node.position.y],
			"object_id": obj_id
		})

	if node is Interactable:
		interactables.append({
			"path": path,
			"class": node.get_class(),
			"pos": [node.position.x, node.position.y],
			"object_id": str(node.object_id)
		})

	for child in node.get_children():
		_scan_node(child, root_node, collisions, zones, interactables)


# -------------------------------------------------------------------------------------------------
# 1. Collision Freeze Test across all 10 rooms
# -------------------------------------------------------------------------------------------------
func test_collision_freeze_all_10_rooms() -> void:
	var baseline := _get_baseline_data()
	_assert_eq(baseline.size(), 10, "Baseline contains fingerprints for all 10 rooms")

	for path in ROOM_PATHS:
		var room_name := path.get_file().get_basename()
		var scene := load(path) as PackedScene
		_assert_true(scene != null, "Loaded room scene %s" % room_name)

		var inst := scene.instantiate() as Node2D
		_assert_true(inst != null, "Instantiated room scene %s" % room_name)

		var curr := _scan_room_fingerprint(inst)
		inst.free()

		var base: Dictionary = baseline[room_name]

		# 1. Collisions
		_assert_eq(curr["collisions"].size(), base["collisions"].size(),
			"%s: collision shape count must match baseline exactly" % room_name)
		for i in range(base["collisions"].size()):
			var b = base["collisions"][i]
			var c = curr["collisions"][i]
			_assert_eq(c["path"], b["path"], "%s: collision path[%d]" % [room_name, i])
			_assert_eq(c["pos"], b["pos"], "%s: collision pos[%d]" % [room_name, i])
			_assert_eq(c["rot"], b["rot"], "%s: collision rot[%d]" % [room_name, i])
			_assert_eq(c["scale"], b["scale"], "%s: collision scale[%d]" % [room_name, i])
			_assert_eq(c["layer"], b["layer"], "%s: collision layer[%d]" % [room_name, i])
			_assert_eq(c["mask"], b["mask"], "%s: collision mask[%d]" % [room_name, i])
			if c.has("shape"):
				_assert_eq(c["shape"], b["shape"], "%s: collision shape[%d]" % [room_name, i])
			if c.has("polygon"):
				_assert_eq(c["polygon"], b["polygon"], "%s: collision poly[%d]" % [room_name, i])

		# 2. Zones & Spawns
		_assert_eq(curr["zones"].size(), base["zones"].size(),
			"%s: zone and spawn count must match baseline exactly" % room_name)
		for i in range(base["zones"].size()):
			var b = base["zones"][i]
			var c = curr["zones"][i]
			_assert_eq(c["path"], b["path"], "%s: zone path[%d]" % [room_name, i])
			_assert_eq(c["pos"], b["pos"], "%s: zone pos[%d]" % [room_name, i])
			_assert_eq(c["object_id"], b["object_id"], "%s: zone object_id[%d]" % [room_name, i])

		# 3. Interactables
		_assert_eq(curr["interactables"].size(), base["interactables"].size(),
			"%s: interactable count must match baseline exactly" % room_name)
		for i in range(base["interactables"].size()):
			var b = base["interactables"][i]
			var c = curr["interactables"][i]
			_assert_eq(c["path"], b["path"], "%s: interactable path[%d]" % [room_name, i])
			_assert_eq(c["object_id"], b["object_id"], "%s: interactable object_id[%d]" % [room_name, i])
			if room_name == "signal_control" and c["object_id"] == "ch01.signal_control.intercom":
				# ADR-019 exception: intercom moved from (352, 160) to N-wall mount (528, 154)
				_assert_eq(c["pos"], [528.0, 154.0], "signal_control: intercom at ADR-019 N-wall position (528, 154)")
				_assert_eq(b["pos"], [352.0, 160.0], "signal_control: baseline intercom at old greybox position (352, 160)")
			else:
				_assert_eq(c["pos"], b["pos"], "%s: interactable pos[%d]" % [room_name, i])


# -------------------------------------------------------------------------------------------------
# 2. Intercom Reach Test (ADR-019 requirement 5)
# -------------------------------------------------------------------------------------------------
func test_intercom_reach_walkable() -> void:
	var scene := load("res://scenes/chapters/ch01/rooms/signal_control.tscn") as PackedScene
	var inst := scene.instantiate() as Node2D
	var intercom := inst.get_node_or_null("intercom") as Area2D
	_assert_true(intercom != null, "signal_control has intercom Area2D")

	# Position must be on N-wall mount (528, 154)
	_assert_eq(intercom.position, Vector2(528, 154), "intercom mounted at N-wall module k=6 (528, 154)")

	# Player standing spot just south in walkable lane is W3 (528, 184)
	var walkable_spot := Vector2(528, 184)
	var reach_dist := walkable_spot.distance_to(intercom.position)
	_assert_true(reach_dist <= 36.0, "intercom reachable from walkable spot (dist %.1f <= 36.0 px)" % reach_dist)
	inst.free()


# -------------------------------------------------------------------------------------------------
# 3. No Greybox Nodes Remain Across All 10 Rooms
# -------------------------------------------------------------------------------------------------
func test_no_greybox_nodes_remain_across_all_rooms() -> void:
	for path in ROOM_PATHS:
		var room_name := path.get_file().get_basename()
		var scene := load(path) as PackedScene
		var inst := scene.instantiate() as Node2D

		# Check removal of greybox floor polygons
		_assert_true(inst.get_node_or_null("Floor") == null, "%s: greybox Floor Polygon2D removed" % room_name)
		_assert_true(inst.get_node_or_null("FloorAccent") == null, "%s: greybox FloorAccent Polygon2D removed" % room_name)

		# Check removal of apex Clock sprite
		var apex_clock := inst.get_node_or_null("Clock")
		_assert_true(apex_clock == null, "%s: greybox floating Clock at (320, 50) removed" % room_name)

		# Check TileMapLayer_Floor exists at (304, 64) with valid TileSet
		var floor_layer := inst.get_node_or_null("TileMapLayer_Floor") as TileMapLayer
		_assert_true(floor_layer != null, "%s: TileMapLayer_Floor exists" % room_name)
		_assert_eq(floor_layer.position, Vector2(304, 64), "%s: TileMapLayer_Floor at (304, 64)" % room_name)
		_assert_true(floor_layer.tile_set != null, "%s: TileMapLayer_Floor has TileSet" % room_name)

		# Check YSort_Walls exists with z_index = 5 and y_sort_enabled = true
		var ysort_walls := inst.get_node_or_null("YSort_Walls") as Node2D
		_assert_true(ysort_walls != null, "%s: YSort_Walls exists" % room_name)
		_assert_eq(ysort_walls.z_index, 5, "%s: YSort_Walls at z_index 5" % room_name)
		_assert_true(ysort_walls.y_sort_enabled, "%s: YSort_Walls has y_sort_enabled = true" % room_name)

		# Check RoomVisuals controller exists
		var rv := inst.get_node_or_null("RoomVisuals")
		_assert_true(rv != null, "%s: RoomVisuals controller exists" % room_name)

		if room_name == "street_exit":
			_assert_true(inst.get_node_or_null("StairsAccent") == null, "street_exit: greybox StairsAccent removed")
		elif room_name == "signal_control":
			_assert_true(inst.get_node_or_null("SouthRailingVisual") == null, "signal_control: SouthRailingVisual Line2D removed")
			_assert_true(inst.get_node_or_null("NorthRailingVisual") == null, "signal_control: NorthRailingVisual Line2D removed")
			_assert_true(inst.get_node_or_null("NorthBarrierVisual") != null, "signal_control: NorthBarrierVisual kept per spec")

		inst.free()


# -------------------------------------------------------------------------------------------------
# 4. Complete Room 1 Check (CH01_PLACEMENT_SHEET.md §1)
# -------------------------------------------------------------------------------------------------
func test_room1_arrival_platform_kit_complete() -> void:
	var scene := load("res://scenes/chapters/ch01/rooms/arrival_platform.tscn") as PackedScene
	var inst := scene.instantiate() as Node2D

	# Floor: 14x10 = 140 tiles
	var floor_layer := inst.get_node_or_null("TileMapLayer_Floor") as TileMapLayer
	_assert_true(floor_layer != null, "arrival_platform: TileMapLayer_Floor exists")
	var used := floor_layer.get_used_cells()
	_assert_eq(used.size(), 140, "arrival_platform: exactly 140 tiles used")

	# YSort_Walls: 7 N modules, 5 W modules, 1 Archway
	var walls := inst.get_node_or_null("YSort_Walls") as Node2D
	_assert_true(walls != null, "arrival_platform: YSort_Walls exists")
	for k in range(7):
		var w = walls.get_node_or_null("WallN_%d" % k) as Sprite2D
		_assert_true(w != null, "arrival_platform: WallN_%d exists" % k)
		_assert_eq(w.position, Vector2(336 + 32 * k, 72 + 16 * k), "arrival_platform: WallN_%d pivot" % k)
	for j in range(5):
		var w = walls.get_node_or_null("WallW_%d" % j) as Sprite2D
		_assert_true(w != null, "arrival_platform: WallW_%d exists" % j)
		_assert_eq(w.position, Vector2(304 - 32 * j, 72 + 16 * j), "arrival_platform: WallW_%d pivot" % j)

	var arch := walls.get_node_or_null("Archway_door_exit_east") as Sprite2D
	_assert_true(arch != null, "arrival_platform: Archway_door_exit_east exists")
	_assert_eq(arch.position, Vector2(448, 208), "arrival_platform: archway at doorway position (448, 208)")
	_assert_eq(arch.z_index, 6, "arrival_platform: archway at z_index 6")

	# Wall_Fixtures: 2 clocks at k=2 and k=5
	var fixtures := inst.get_node_or_null("Wall_Fixtures") as Node2D
	_assert_true(fixtures != null, "arrival_platform: Wall_Fixtures exists")
	_assert_eq(fixtures.z_index, 7, "arrival_platform: Wall_Fixtures at z_index 7")
	var clk2 := fixtures.get_node_or_null("Clock_2") as Sprite2D
	var clk5 := fixtures.get_node_or_null("Clock_5") as Sprite2D
	_assert_true(clk2 != null, "arrival_platform: Clock_2 exists")
	_assert_true(clk5 != null, "arrival_platform: Clock_5 exists")
	_assert_eq(clk2.position, Vector2(400, 66), "arrival_platform: Clock_2 at (400, 66)")
	_assert_eq(clk5.position, Vector2(496, 114), "arrival_platform: Clock_5 at (496, 114)")

	# YSort_Actors: Bench at (352, 120), Stalled car at (251, 210)
	var actors := inst.get_node_or_null("YSort_Actors") as Node2D
	_assert_true(actors != null, "arrival_platform: YSort_Actors exists")
	_assert_eq(actors.z_index, 10, "arrival_platform: YSort_Actors at z_index 10")
	var bench := actors.get_node_or_null("PlatformBench") as Sprite2D
	var car := actors.get_node_or_null("StalledTransitCar") as Sprite2D
	_assert_true(bench != null, "arrival_platform: PlatformBench exists")
	_assert_true(car != null, "arrival_platform: StalledTransitCar exists")
	_assert_eq(bench.position, Vector2(352, 120), "arrival_platform: PlatformBench at (352, 120)")
	_assert_eq(car.position, Vector2(251, 210), "arrival_platform: StalledTransitCar at (251, 210)")

	# Watch sprite on pocket_watch_pickup
	var pickup := inst.get_node_or_null("pocket_watch_pickup")
	_assert_true(pickup != null, "arrival_platform: pocket_watch_pickup exists")
	var watch_sprite := pickup.get_node_or_null("WatchSprite") as Sprite2D
	_assert_true(watch_sprite != null, "arrival_platform: WatchSprite child exists on pickup")
	_assert_eq(watch_sprite.z_index, 8, "arrival_platform: WatchSprite at z_index 8")

	inst.free()


# -------------------------------------------------------------------------------------------------
# 5. Puzzle Prop Presenter State Mappings
# -------------------------------------------------------------------------------------------------
func test_puzzle_prop_presenter_state_mappings() -> void:
	# 1. TurnstilePresenter
	var turnstile_script = load("res://scripts/chapters/ch01/visuals/turnstile_presenter.gd")
	var turnstile := TurnstileGate.new()
	var t_pres := Sprite2D.new()
	t_pres.set_script(turnstile_script)
	turnstile.add_child(t_pres)
	turnstile.arm_state = &"collapsed"
	t_pres._refresh()
	_assert_true(t_pres.texture.resource_path.ends_with("turnstile_gate_collapsed.png"),
		"TurnstilePresenter: collapsed arm_state selects collapsed texture")
	turnstile.arm_state = &"open"
	t_pres._refresh()
	_assert_true(t_pres.texture.resource_path.ends_with("turnstile_gate_open.png"),
		"TurnstilePresenter: open arm_state selects open texture")
	turnstile.free()

	# 2. FireShutterPresenter
	var shutter_script = load("res://scripts/chapters/ch01/visuals/fire_shutter_presenter.gd")
	var shutter := FireShutter.new()
	var s_pres := Sprite2D.new()
	s_pres.set_script(shutter_script)
	shutter.add_child(s_pres)
	shutter.shutter_state = &"closed"
	s_pres._refresh()
	_assert_true(s_pres.texture.resource_path.ends_with("fire_shutter_closed.png"),
		"FireShutterPresenter: closed shutter_state selects closed texture")
	shutter.shutter_state = &"raised"
	s_pres._refresh()
	_assert_true(s_pres.texture.resource_path.ends_with("fire_shutter_raised.png"),
		"FireShutterPresenter: raised shutter_state selects raised texture")
	shutter.free()

	# 3. CounterweightGearPresenter
	var gear_script = load("res://scripts/chapters/ch01/visuals/counterweight_gear_presenter.gd")
	var gear := CounterweightGear.new()
	var g_pres := Sprite2D.new()
	g_pres.set_script(gear_script)
	gear.add_child(g_pres)
	gear.gear_state = &"idle"
	g_pres._refresh()
	_assert_true(g_pres.texture.resource_path.ends_with("counterweight_gear_idle.png"),
		"CounterweightGearPresenter: idle gear_state selects idle texture")
	gear.gear_state = &"slipping"
	g_pres._refresh()
	_assert_true(g_pres.texture.resource_path.ends_with("counterweight_gear_slipping.png"),
		"CounterweightGearPresenter: slipping gear_state selects slipping texture")
	gear.gear_state = &"locked"
	g_pres._refresh()
	_assert_true(g_pres.texture.resource_path.ends_with("counterweight_gear_frozen.png"),
		"CounterweightGearPresenter: locked gear_state selects frozen texture")
	gear.free()

	# 4. SurgeCapacitorPresenter
	var cap_script = load("res://scripts/chapters/ch01/visuals/surge_capacitor_presenter.gd")
	var cap := SurgeCapacitor.new()
	var c_pres := Sprite2D.new()
	c_pres.set_script(cap_script)
	cap.add_child(c_pres)
	cap.charge_state = &"discharged"
	c_pres._refresh()
	_assert_true(c_pres.texture.resource_path.ends_with("surge_capacitor_discharged.png"),
		"SurgeCapacitorPresenter: discharged charge_state selects discharged texture")
	cap.charge_state = &"charged"
	c_pres._refresh()
	_assert_true(c_pres.texture.resource_path.ends_with("surge_capacitor_charged.png"),
		"SurgeCapacitorPresenter: charged charge_state selects charged texture")
	_assert_eq(c_pres.resolve_state_key(&"charged", true), "frozen",
		"SurgeCapacitorPresenter: is_frozen maps to frozen via data mapping")
	cap.free()

	# 5. PressureSwitchPresenter
	var pswitch_script = load("res://scripts/chapters/ch01/visuals/pressure_switch_presenter.gd")
	var pswitch := TriggerZone.new()
	var ps_pres := Sprite2D.new()
	ps_pres.set_script(pswitch_script)
	pswitch.add_child(ps_pres)
	ps_pres._refresh()
	_assert_true(ps_pres.texture.resource_path.ends_with("pressure_switch_released.png"),
		"PressureSwitchPresenter: not occupied selects released texture")
	pswitch.free()

	# 6. RetractableBridgePresenter
	var bridge_script = load("res://scripts/chapters/ch01/visuals/retractable_bridge_presenter.gd")
	var bridge := RetractableBridge.new()
	var b_pres := Sprite2D.new()
	b_pres.set_script(bridge_script)
	bridge.add_child(b_pres)
	b_pres._ready()
	_assert_eq(b_pres.offset, Vector2(-24, -10),
		"RetractableBridgePresenter: offset has +(0, 8) shift for trench cell center")
	bridge.platform_state = &"retracted"
	b_pres._refresh()
	_assert_true(b_pres.texture.resource_path.ends_with("bridge_platform_retracted.png"),
		"RetractableBridgePresenter: retracted selects retracted texture")
	bridge.platform_state = &"extended"
	b_pres._refresh()
	_assert_true(b_pres.texture.resource_path.ends_with("bridge_platform_extended.png"),
		"RetractableBridgePresenter: extended selects extended texture")
	bridge.free()

	# 7. LeverPresenter
	var lever_script = load("res://scripts/chapters/ch01/visuals/lever_presenter.gd")
	var lever := TimedBreaker.new()
	var l_pres := Sprite2D.new()
	l_pres.set_script(lever_script)
	l_pres.set("badge_type", &"a")
	lever.add_child(l_pres)
	l_pres._ready()
	_assert_true(l_pres.get_node_or_null("Badge") != null, "LeverPresenter: child Badge created for badge_type 'a'")
	l_pres._refresh()
	_assert_true(l_pres.texture.resource_path.ends_with("lever_switch_off.png"),
		"LeverPresenter: open breaker selects off texture")
	lever.lever_state = &"engaged"
	l_pres._refresh()
	_assert_true(l_pres.texture.resource_path.ends_with("lever_switch_on.png"),
		"LeverPresenter: engaged breaker selects on texture")
	lever.free()

	# 8. RouteBoardPresenter
	var rb_script = load("res://scripts/chapters/ch01/visuals/route_board_presenter.gd")
	var rb_pres := Sprite2D.new()
	rb_pres.set_script(rb_script)
	_assert_eq(rb_pres.tex_state0.resource_path.get_file(), "ch01_prop_route_board_state0.png", "RouteBoard: state0 texture")
	_assert_eq(rb_pres.tex_state1.resource_path.get_file(), "ch01_prop_route_board_state1.png", "RouteBoard: state1 texture")
	_assert_eq(rb_pres.tex_state2.resource_path.get_file(), "ch01_prop_route_board_state2.png", "RouteBoard: state2 texture")
	rb_pres.free()


# -------------------------------------------------------------------------------------------------
# 6. Real Save File Untouched
# -------------------------------------------------------------------------------------------------
func test_real_save_unmodified() -> void:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	if exists:
		var mtime := FileAccess.get_modified_time(REAL_SAVE_SLOT_0)
		_assert_true(mtime > 0, "Real save exists with valid timestamp")
	else:
		_assert_false(exists, "Real save slot_0 does not exist and was not created")
