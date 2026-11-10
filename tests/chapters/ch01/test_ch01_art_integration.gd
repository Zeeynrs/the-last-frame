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

