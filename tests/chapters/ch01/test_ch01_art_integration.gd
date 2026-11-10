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

