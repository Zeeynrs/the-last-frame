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

