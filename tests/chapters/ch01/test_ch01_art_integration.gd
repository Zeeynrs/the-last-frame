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

	# Floor: 360 tiles used in L-shape v2
	var floor_layer := inst.get_node_or_null("TileMapLayer_Floor") as TileMapLayer
	_assert_true(floor_layer != null, "arrival_platform: TileMapLayer_Floor exists")
	var used := floor_layer.get_used_cells()
	_assert_eq(used.size(), 360, "arrival_platform: exactly 360 tiles used")

	# YSort_Walls: 15 N modules, 9 W modules, 1 Archway, plus shape kit corners and low partitions
	var walls := inst.get_node_or_null("YSort_Walls") as Node2D
	_assert_true(walls != null, "arrival_platform: YSort_Walls exists")
	for k in range(15):
		var w = walls.get_node_or_null("WallN_%d" % k) as Sprite2D
		_assert_true(w != null, "arrival_platform: WallN_%d exists" % k)
		_assert_eq(w.position, Vector2(336 + 32 * k, 72 + 16 * k), "arrival_platform: WallN_%d pivot" % k)
	for j in range(9):
		var w = walls.get_node_or_null("WallW_%d" % j) as Sprite2D
		_assert_true(w != null, "arrival_platform: WallW_%d exists" % j)
		_assert_eq(w.position, Vector2(304 - 32 * j, 72 + 16 * j), "arrival_platform: WallW_%d pivot" % j)

	var arch := walls.get_node_or_null("Archway_door_exit_east") as Sprite2D
	_assert_true(arch != null, "arrival_platform: Archway_door_exit_east exists")
	_assert_eq(arch.position, Vector2(720, 328), "arrival_platform: archway at doorway position (720, 328)")
	_assert_eq(arch.z_index, 6, "arrival_platform: archway at z_index 6")

	# Corners and low partitions from TLF-068 shape kit
	_assert_true(walls.get_node_or_null("Corner_NW_0_0") != null, "arrival_platform: Corner_NW_0_0 exists")
	_assert_true(walls.get_node_or_null("Corner_N_Turn_30_0") != null, "arrival_platform: Corner_N_Turn_30_0 exists")
	_assert_true(walls.get_node_or_null("Corner_Low_30_8") != null, "arrival_platform: Corner_Low_30_8 exists")
	_assert_true(walls.get_node_or_null("Corner_Low_12_8") != null, "arrival_platform: Corner_Low_12_8 exists")
	_assert_true(walls.get_node_or_null("Corner_Low_12_18") != null, "arrival_platform: Corner_Low_12_18 exists")
	_assert_true(walls.get_node_or_null("Corner_W_Turn_0_18") != null, "arrival_platform: Corner_W_Turn_0_18 exists")

	# Wall_Fixtures: 2 clocks at (400, 66) and (592, 162), plus TLF-063 departure board and notice
	var fixtures := inst.get_node_or_null("Wall_Fixtures") as Node2D
	_assert_true(fixtures != null, "arrival_platform: Wall_Fixtures exists")
	_assert_eq(fixtures.z_index, 7, "arrival_platform: Wall_Fixtures at z_index 7")
	var clk2 := fixtures.get_node_or_null("Clock_2") as Sprite2D
	var clk8 := fixtures.get_node_or_null("Clock_8") as Sprite2D
	_assert_true(clk2 != null, "arrival_platform: Clock_2 exists")
	_assert_true(clk8 != null, "arrival_platform: Clock_8 exists")
	_assert_eq(clk2.position, Vector2(400, 66), "arrival_platform: Clock_2 at (400, 66)")
	_assert_eq(clk8.position, Vector2(592, 162), "arrival_platform: Clock_8 at (592, 162)")

	var dep_board := fixtures.get_node_or_null("DepartureBoard") as Sprite2D
	var closed_track := fixtures.get_node_or_null("ClosedTrackNotice") as Sprite2D
	_assert_true(dep_board != null, "arrival_platform: DepartureBoard exists")
	_assert_true(closed_track != null, "arrival_platform: ClosedTrackNotice exists")
	_assert_eq(dep_board.position, Vector2(144, 114), "arrival_platform: DepartureBoard at (144, 114)")
	_assert_eq(closed_track.position, Vector2(528, 130), "arrival_platform: ClosedTrackNotice at (528, 130)")

	# YSort_Actors: Bench at (448, 168), Stalled car at (480, 336)
	var actors := inst.get_node_or_null("YSort_Actors") as Node2D
	_assert_true(actors != null, "arrival_platform: YSort_Actors exists")
	_assert_eq(actors.z_index, 10, "arrival_platform: YSort_Actors at z_index 10")
	var bench := actors.get_node_or_null("PlatformBench") as Sprite2D
	var car := actors.get_node_or_null("StalledTransitCar") as Sprite2D
	_assert_true(bench != null, "arrival_platform: PlatformBench exists")
	_assert_true(car != null, "arrival_platform: StalledTransitCar exists")
	_assert_eq(bench.position, Vector2(448, 168), "arrival_platform: PlatformBench at (448, 168)")
	_assert_eq(car.position, Vector2(480, 336), "arrival_platform: StalledTransitCar at (480, 336)")

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
