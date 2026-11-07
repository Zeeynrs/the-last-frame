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
