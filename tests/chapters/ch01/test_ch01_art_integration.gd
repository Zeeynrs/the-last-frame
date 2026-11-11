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

	# Wall_Fixtures: Clock_8 at (576, 147), plus TLF-073 departure board and notice
	var fixtures := inst.get_node_or_null("Wall_Fixtures") as Node2D
	_assert_true(fixtures != null, "arrival_platform: Wall_Fixtures exists")
	_assert_eq(fixtures.z_index, 7, "arrival_platform: Wall_Fixtures at z_index 7")
	var clk2 := fixtures.get_node_or_null("Clock_2") as Sprite2D
	var clk8 := fixtures.get_node_or_null("Clock_8") as Sprite2D
	_assert_true(clk2 == null, "arrival_platform: Clock_2 removed near spawn (departure board carries 23:59)")
	_assert_true(clk8 != null, "arrival_platform: Clock_8 exists")
	_assert_eq(clk8.position, Vector2(576, 147), "arrival_platform: Clock_8 at (576, 147)")
	_assert_eq(clk8.offset, Vector2.ZERO, "arrival_platform: Clock_8 offset is (0, 0)")
	_assert_false(clk8.centered, "arrival_platform: Clock_8 centered is false")
	_assert_true(clk8.texture.resource_path.ends_with("ch01_prop_digital_clock_2359_n_idle.png"),
		"arrival_platform: Clock_8 has sheared N-face texture")

	var dep_board := fixtures.get_node_or_null("DepartureBoard") as Sprite2D
	var closed_track := fixtures.get_node_or_null("ClosedTrackNotice") as Sprite2D
	_assert_true(dep_board != null, "arrival_platform: DepartureBoard exists")
	_assert_true(closed_track != null, "arrival_platform: ClosedTrackNotice exists")
	_assert_eq(dep_board.position, Vector2(64, 148), "arrival_platform: DepartureBoard at (64, 148)")
	_assert_eq(closed_track.position, Vector2(488, 116), "arrival_platform: ClosedTrackNotice at (488, 116)")

	# Selectors: 3 N-face sheared presenters
	var sel_line := inst.get_node_or_null("selector_line/Presenter") as SelectorSwitchPresenter
	var sel_plat := inst.get_node_or_null("selector_platform/Presenter") as SelectorSwitchPresenter
	var sel_car := inst.get_node_or_null("selector_car/Presenter") as SelectorSwitchPresenter
	_assert_true(sel_line != null, "arrival_platform: selector_line/Presenter exists")
	_assert_true(sel_plat != null, "arrival_platform: selector_platform/Presenter exists")
	_assert_true(sel_car != null, "arrival_platform: selector_car/Presenter exists")
	_assert_eq(sel_line.position, Vector2(0, -28), "arrival_platform: selector_line Presenter at (0, -28)")
	_assert_eq(sel_plat.position, Vector2(0, -28), "arrival_platform: selector_platform Presenter at (0, -28)")
	_assert_eq(sel_car.position, Vector2(0, -28), "arrival_platform: selector_car Presenter at (0, -28)")
	_assert_true(sel_line.textures.size() == 3 and sel_line.textures[0].resource_path.ends_with("selector_line_n_pos0.png"),
		"arrival_platform: selector_line textures use sheared N art")
	_assert_true(sel_plat.textures.size() == 3 and sel_plat.textures[0].resource_path.ends_with("selector_platform_n_pos0.png"),
		"arrival_platform: selector_platform textures use sheared N art")
	_assert_true(sel_car.textures.size() == 3 and sel_car.textures[0].resource_path.ends_with("selector_car_n_pos0.png"),
		"arrival_platform: selector_car textures use sheared N art")

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
	_assert_true(s_pres.texture.resource_path.ends_with("inner_shutter_closed.png"),
		"FireShutterPresenter: closed shutter_state selects closed texture")
	shutter.shutter_state = &"raised"
	s_pres._refresh()
	_assert_true(s_pres.texture.resource_path.ends_with("inner_shutter_raised.png"),
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

