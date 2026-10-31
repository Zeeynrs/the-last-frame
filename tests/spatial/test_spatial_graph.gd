extends "res://tests/support/base_test.gd"

## SpatialGraph / SpatialService / DoorwayPresenter (ADR-009 + clarification) against the
## CH1-PZ-005 graph (design/ch01/puzzles/CH1-PZ-005.md §4).

const SIG := &"ch01.signal_control"
const VEST := &"ch01.upper_vestibule"
const NICHE := &"ch01.vestibule_niche"
const ATRIUM := &"ch01.station_atrium"

const STATE_0 := [
	[SIG, &"door_exit_north", VEST, &"door_south"],
	[VEST, &"door_north", VEST, &"door_west"],
	[VEST, &"door_east", NICHE, &"door_in"],
	[NICHE, &"door_out", ATRIUM, &"door_entry_south", false],
]
## Lever A: uncouple the west loop (State 0 -> 1).
const T_A_UNCOUPLE := [[VEST, &"door_west", VEST, &"door_east"], [VEST, &"door_north", NICHE, &"door_in"]]
## Lever B: route north to the atrium (State 1 -> 2).
const T_B_ATRIUM := [[VEST, &"door_north", ATRIUM, &"door_entry_south"], [NICHE, &"door_in", NICHE, &"door_out", false]]
## Reverses.
const T_A_COUPLE := [[VEST, &"door_north", VEST, &"door_west"], [VEST, &"door_east", NICHE, &"door_in"]]
const T_B_NICHE := [[VEST, &"door_north", NICHE, &"door_in"], [NICHE, &"door_out", ATRIUM, &"door_entry_south", false]]


func _graph() -> SpatialGraph:
	var g := SpatialGraph.new()
	g.add_room(SIG, [&"door_exit_north"])
	g.add_room(VEST, [&"door_south", &"door_west", &"door_east", &"door_north"])
	g.add_room(NICHE, [&"door_in", &"door_out"])
	g.add_room(ATRIUM, [&"door_entry_south"])
	g.add_critical_pair(SIG, VEST)
	_assert_true(g.set_initial_pairs(STATE_0)["ok"], "State 0 valid")
	return g


func _dest(g: SpatialGraph, room: StringName, door: StringName) -> Array:
	var d := g.get_destination(room, door)
	return [d.get("room_id"), d.get("door_id")]


func test_pz005_01_state0_north_loops_to_west() -> void:
	_assert_eq(_dest(_graph(), VEST, &"door_north"), [VEST, &"door_west"], "north -> west loop")


func test_pz005_02_lever_b_first_is_rejected_without_side_effects() -> void:
	var g := _graph()
	var fired: Array = []
	g.changed.connect(func(r): fired.append(r))
	var before := g.export_pairs()
	_assert_eq(g.apply(T_B_ATRIUM)["reason"], &"invalid_graph", "I-1 rejected (west/east left dangling)")
	_assert_eq(g.export_pairs(), before, "graph unchanged")
	_assert_eq(fired, [], "changed not emitted")


func test_pz005_03_lever_a_then_b_reaches_atrium() -> void:
	var g := _graph()
	var fired: Array = []
	g.changed.connect(func(r): fired.append(r))
	_assert_true(g.apply(T_A_UNCOUPLE)["ok"], "A ok")
	_assert_true(g.apply(T_B_ATRIUM)["ok"], "B ok")
	_assert_eq(fired.size(), 2, "changed twice")
	_assert_eq(fired[0], [VEST, NICHE], "lever A affects vestibule + niche")
	_assert_eq(_dest(g, VEST, &"door_north"), [ATRIUM, &"door_entry_south"], "north -> atrium")
	_assert_eq(_dest(g, ATRIUM, &"door_entry_south"), [VEST, &"door_north"], "symmetric")


func test_pz005_04_severing_the_entry_is_critical_path_unreachable() -> void:
	var g := _graph()
	var before := g.export_pairs()
	# Fully paired but disconnected: signal_control loops to itself.
	var sever := [[SIG, &"door_exit_north", SIG, &"door_exit_north"], [VEST, &"door_south", VEST, &"door_north"], [VEST, &"door_west", VEST, &"door_west"]]
	_assert_eq(g.apply(sever)["reason"], &"critical_path_unreachable", "I-4 rejected")
	_assert_eq(g.export_pairs(), before, "graph unchanged")


func test_i2_relooping_while_routed_to_atrium_is_rejected() -> void:
	var g := _graph()
	g.apply(T_A_UNCOUPLE)
	g.apply(T_B_ATRIUM)
	_assert_eq(g.apply(T_A_COUPLE)["reason"], &"invalid_graph", "I-2 rejected (atrium/niche left dangling)")
	_assert_eq(_dest(g, VEST, &"door_north"), [ATRIUM, &"door_entry_south"], "still State 2")


func test_levers_reverse_back_to_state0() -> void:
	var g := _graph()
	var initial := g.export_pairs()
	g.apply(T_A_UNCOUPLE)
	g.apply(T_B_ATRIUM)
	_assert_true(g.apply(T_B_NICHE)["ok"], "B back")
	_assert_true(g.apply(T_A_COUPLE)["ok"], "A back")
	_assert_eq(g.export_pairs(), initial, "exactly State 0 again")


func test_i3_unknown_duplicate_and_dangling_are_invalid() -> void:
	var g := _graph()
	_assert_eq(g.apply([[VEST, &"door_up", VEST, &"door_west"]])["reason"], &"invalid_graph", "unknown doorway")
	_assert_eq(g.apply([[VEST, &"door_north", VEST, &"door_west"], [VEST, &"door_north", NICHE, &"door_in"]])["reason"], &"invalid_graph", "doorway paired twice")
	var g2 := SpatialGraph.new()
	g2.add_room(VEST, [&"door_a", &"door_b"])
	_assert_eq(g2.set_initial_pairs([])["reason"], &"invalid_graph", "dangling initial doorways")


func test_reachability_respects_non_traversable_edges() -> void:
	var g := _graph()
	_assert_false(g.is_reachable(SIG, ATRIUM), "State 0: atrium only behind the grille")
	_assert_true(g.is_reachable(SIG, NICHE), "State 0: niche via east door")
	g.apply(T_A_UNCOUPLE)
	g.apply(T_B_ATRIUM)
	_assert_true(g.is_reachable(SIG, ATRIUM), "State 2: atrium reachable")
	_assert_eq(g.get_unreachable_rooms(SIG), [NICHE], "State 2: niche sealed off")


func test_pz005_05_player_stranded_in_niche_is_relocated() -> void:
	var spatial := SpatialService.new()
	spatial.set_graph(_graph(), SIG)
	spatial.set_relocation_anchor(NICHE, &"ch01.upper_vestibule.safe_anchor_center")
	var requests: Array = []
	spatial.relocate_requested.connect(func(actor, anchor): requests.append([actor, anchor]))
	spatial.apply_transform(T_A_UNCOUPLE)
	spatial.set_actor_room(&"player", NICHE)
	_assert_eq(requests, [], "niche still reachable in State 1")
	_assert_true(spatial.apply_transform(T_B_ATRIUM).ok, "B ok")
	_assert_eq(requests, [[&"player", &"ch01.upper_vestibule.safe_anchor_center"]], "relocated out of the sealed niche")
	spatial.free()


func test_player_in_vestibule_is_not_relocated() -> void:
	var spatial := SpatialService.new()
	spatial.set_graph(_graph(), SIG)
	spatial.set_relocation_anchor(NICHE, &"ch01.upper_vestibule.safe_anchor_center")
	spatial.set_actor_room(&"player", VEST)
	var requests: Array = []
	spatial.relocate_requested.connect(func(a, b): requests.append([a, b]))
	spatial.apply_transform(T_A_UNCOUPLE)
	spatial.apply_transform(T_B_ATRIUM)
	_assert_eq(requests, [], "no needless teleport")
	spatial.free()


func test_doorway_presenter_reports_destination_and_blocks_grille() -> void:
	var s := make_session()
	s.spatial_service.set_graph(_graph(), SIG)
	var north := DoorwayPresenter.new()
	north.room_id = VEST
	north.door_id = &"door_north"
	spawn(s, north, &"ch01.upper_vestibule.door_north")
	var grille := DoorwayPresenter.new()
	grille.room_id = NICHE
	grille.door_id = &"door_out"
	spawn(s, grille, &"ch01.vestibule_niche.door_out")
	var log: Array = []
	north.traversed.connect(func(a, d): log.append([a, d["room_id"], d["door_id"]]))
	grille.blocked.connect(func(a): log.append([a, "blocked"]))
	s.interaction_service.trigger_enter(&"echo.0", north.object_id)
	s.interaction_service.trigger_enter(&"player", north.object_id)
	s.interaction_service.trigger_exit(&"player", north.object_id)
	_assert_eq(s.spatial_service.get_actor_room(&"player"), VEST, "loop keeps player in vestibule")
	s.spatial_service.apply_transform(T_A_UNCOUPLE)
	s.spatial_service.apply_transform(T_B_ATRIUM)
	s.interaction_service.trigger_enter(&"player", north.object_id)
	s.interaction_service.trigger_enter(&"player", grille.object_id)
	_assert_eq(log, [[&"player", VEST, &"door_west"], [&"player", ATRIUM, &"door_entry_south"], [&"player", "blocked"]], "echo ignored; loop, atrium, grille")
	_assert_eq(s.spatial_service.get_actor_room(&"player"), ATRIUM, "player now in atrium")
	free_session(s)


func test_spatial_state_survives_save_and_load() -> void:
	var a := make_session()
	a.spatial_service.set_graph(_graph(), SIG)
	a.spatial_service.apply_transform(T_A_UNCOUPLE)
	a.spatial_service.apply_transform(T_B_ATRIUM)
	var save := SaveService.new()
	var data := save.capture(a, "ch01", "ch01.cp.upper_vestibule")
	var expected := a.spatial_service.graph.export_pairs()
	free_session(a)
	var b := make_session()
	b.spatial_service.set_graph(_graph(), SIG)          # fresh scene: State 0
	_assert_true(save.apply(b, save.upgrade(data)["data"])["ok"], "apply ok")
	_assert_eq(b.spatial_service.graph.export_pairs(), expected, "State 2 restored")
	_assert_false(save.apply(b, _with_bad_spatial(data))["ok"], "invalid spatial data refused")
	_assert_eq(b.spatial_service.graph.export_pairs(), expected, "refused import leaves graph intact")
	save.free()
	free_session(b)


func _with_bad_spatial(data: Dictionary) -> Dictionary:
	var bad := data.duplicate(true)
	bad["spatial"]["pairs"] = [[String(VEST), "door_north", String(VEST), "door_west"]]  # leaves others dangling
	return bad
