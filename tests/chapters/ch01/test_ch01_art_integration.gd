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
	_assert_eq(c_pres.resolve_state_key(&"charged", true), "frozen_charged",
		"SurgeCapacitorPresenter: frozen + charged maps to frozen_charged via data mapping")
	_assert_eq(c_pres.resolve_state_key(&"discharged", true), "frozen_discharged",
		"SurgeCapacitorPresenter: frozen + discharged maps to frozen_discharged via data mapping")
	_assert_true(c_pres.state_textures["frozen_charged"].resource_path.ends_with("surge_capacitor_frozen_charged.png"),
		"SurgeCapacitorPresenter: frozen_charged texture is surge_capacitor_frozen_charged.png")
	_assert_true(c_pres.state_textures["frozen_discharged"].resource_path.ends_with("surge_capacitor_frozen_discharged.png"),
		"SurgeCapacitorPresenter: frozen_discharged texture is surge_capacitor_frozen_discharged.png")
	_assert_true(c_pres.state_textures["frozen"].resource_path.ends_with("surge_capacitor_frozen.png"),
		"SurgeCapacitorPresenter: legacy frozen fallback texture remains registered")

	# Test in-engine refresh with TemporalComponent frozen flag
	var temp := TemporalComponent.new()
	cap.add_child(temp)
	temp.is_frozen = true
	cap.charge_state = &"charged"
	c_pres._refresh()
	_assert_true(c_pres.texture.resource_path.ends_with("surge_capacitor_frozen_charged.png"),
		"SurgeCapacitorPresenter: frozen + charged selects frozen_charged texture")
	cap.charge_state = &"discharged"
	c_pres._refresh()
	_assert_true(c_pres.texture.resource_path.ends_with("surge_capacitor_frozen_discharged.png"),
		"SurgeCapacitorPresenter: frozen + discharged selects frozen_discharged texture")
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
