extends "res://tests/support/base_test.gd"

## Layout and Geometry Tests for PZ-004 in Signal Control (TLF-033 / RISK-018).
## Verifies that:
## 1. Trench railings physically seal lanes against perimeter walls (no bypass gaps).
## 2. Breaker B cannot be targeted or reached from south of the north railing.
## 3. Exit trigger (exit_trigger_vestibule) completely covers the exit door approach.
## 4. The shortest walkable switchback route on real room collision is >= 600 px (300 ticks).

const SIGNAL_SCENE_PATH := "res://scenes/chapters/ch01/rooms/signal_control.tscn"
const W0 := Vector2(176, 152)  # Breaker A standing spot
const W3 := Vector2(528, 184)  # Breaker B standing spot


func _build_nav_grid(sig: Node2D, cell_size: int = 4) -> Dictionary:
	var perim_node := sig.get_node("PerimeterWalls/CollisionPolygon2D") as CollisionPolygon2D
	var perim_poly := perim_node.polygon
	var south_col := sig.get_node("TrenchRailings/SouthRailingCollision") as CollisionShape2D
	var s_seg := south_col.shape as SegmentShape2D
	var north_col := sig.get_node("TrenchRailings/NorthRailingCollision") as CollisionShape2D
	var n_seg := north_col.shape as SegmentShape2D
	var barrier_col := sig.get_node_or_null("TrenchRailings/NorthBarrierCollision") as CollisionPolygon2D
	var barrier_poly: PackedVector2Array = barrier_col.polygon if barrier_col != null else PackedVector2Array()

	var min_x := 100
	var max_x := 600
	var min_y := 40
	var max_y := 320
	var cols := (max_x - min_x) / cell_size
	var rows := (max_y - min_y) / cell_size

	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, cols, rows)
	grid.cell_size = Vector2(cell_size, cell_size)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	grid.update()

	var player_radius := 6.0

	var is_walkable := func(pos: Vector2) -> bool:
		if not Geometry2D.is_point_in_polygon(pos, perim_poly):
			return false
		var n := perim_poly.size()
		for i in n:
			var p1 := perim_poly[i]
			var p2 := perim_poly[(i + 1) % n]
			if Geometry2D.get_closest_point_to_segment(pos, p1, p2).distance_to(pos) < player_radius:
				return false
		if Geometry2D.get_closest_point_to_segment(pos, s_seg.a, s_seg.b).distance_to(pos) < player_radius:
			return false
		if Geometry2D.get_closest_point_to_segment(pos, n_seg.a, n_seg.b).distance_to(pos) < player_radius:
			return false
		if barrier_poly.size() > 2:
			if Geometry2D.is_point_in_polygon(pos, barrier_poly):
				return false
			for i in barrier_poly.size():
				var p1 := barrier_poly[i]
				var p2 := barrier_poly[(i + 1) % barrier_poly.size()]
				if Geometry2D.get_closest_point_to_segment(pos, p1, p2).distance_to(pos) < player_radius:
					return false
		return true

	for c in cols:
		for r in rows:
			var pos := Vector2(min_x + c * cell_size + cell_size / 2.0, min_y + r * cell_size + cell_size / 2.0)
			if not is_walkable.call(pos):
				grid.set_point_solid(Vector2i(c, r), true)

	return {
		"grid": grid,
		"min_x": min_x,
		"min_y": min_y,
		"cols": cols,
		"rows": rows,
		"cell_size": cell_size,
		"n_seg": n_seg,
		"s_seg": s_seg,
		"barrier_poly": barrier_poly,
		"perim_poly": perim_poly
	}


func test_railings_physically_seal_lanes_at_walls() -> void:
	var sig := (load(SIGNAL_SCENE_PATH) as PackedScene).instantiate() as Node2D
	var perim_node := sig.get_node("PerimeterWalls/CollisionPolygon2D") as CollisionPolygon2D
	var perim := perim_node.polygon

	var south_col := sig.get_node("TrenchRailings/SouthRailingCollision") as CollisionShape2D
	var s_seg := south_col.shape as SegmentShape2D
	var north_col := sig.get_node("TrenchRailings/NorthRailingCollision") as CollisionShape2D
	var n_seg := north_col.shape as SegmentShape2D
	var barrier_col := sig.get_node_or_null("TrenchRailings/NorthBarrierCollision") as CollisionPolygon2D

	_assert_true(south_col != null and s_seg != null, "South railing collision shape exists")
	_assert_true(north_col != null and n_seg != null, "North railing collision shape exists")
	_assert_true(barrier_col != null and barrier_col.polygon.size() >= 3, "North barrier collision polygon exists")

	# South railing starts against the NW wall: distance from s_seg.a (192, 128) to NW wall (124, 158 -> 320, 60) <= 5.0 px
	var nw_wall_dist := Geometry2D.get_closest_point_to_segment(s_seg.a, perim[3], perim[0]).distance_to(s_seg.a)
	_assert_true(nw_wall_dist <= 5.0, "South railing starts flush against NW wall (gap %.2f px <= 5.0)" % nw_wall_dist)

	# North railing reaches all the way to SE wall: n_seg intersects SE wall (580, 190 -> 384, 292)
	var inter = Geometry2D.segment_intersects_segment(n_seg.a, n_seg.b, perim[1], perim[2])
	_assert_true(inter != null, "North railing physically intersects SE perimeter wall at %s" % str(inter))

	# North barrier polygon reaches beyond the SE wall to seal the middle-lane corner
	_assert_true(barrier_col.polygon[0].x <= 480.0, "North barrier extends west to seal vulnerable corner")
	_assert_true(barrier_col.polygon[1].x >= 530.0, "North barrier seals junction at SE wall")

	sig.free()


func test_breaker_b_unreachable_from_south_of_north_railing() -> void:
	var sig := (load(SIGNAL_SCENE_PATH) as PackedScene).instantiate() as Node2D
	var nav_data := _build_nav_grid(sig, 4)
	var grid: AStarGrid2D = nav_data["grid"]
	var min_x: int = nav_data["min_x"]
	var min_y: int = nav_data["min_y"]
	var cols: int = nav_data["cols"]
	var rows: int = nav_data["rows"]
	var cell_size: int = nav_data["cell_size"]

	var breaker_b := sig.get_node("breaker_b") as Area2D
	var b_pos := breaker_b.global_position
	var b_col := breaker_b.get_node("CollisionShape2D") as CollisionShape2D
	var b_radius: float = (b_col.shape as CircleShape2D).radius
	var player_detector_radius := 36.0
	var max_interact_reach := b_radius + player_detector_radius

	var min_dist_to_breaker_b := INF
	var vulnerable_cell_count := 0

	for c in cols:
		for r in rows:
			if grid.is_point_solid(Vector2i(c, r)):
				continue
			var pos := Vector2(min_x + c * cell_size + cell_size / 2.0, min_y + r * cell_size + cell_size / 2.0)
			# North railing line: x - 2y - 96 = 0; south of railing means x - 2y < 96
			if (pos.x - 2.0 * pos.y) < 96.0:
				var dist := pos.distance_to(b_pos)
				if dist < min_dist_to_breaker_b:
					min_dist_to_breaker_b = dist
				if dist <= max_interact_reach:
					vulnerable_cell_count += 1

	_assert_eq(vulnerable_cell_count, 0, "No walkable points south of north railing can interact with breaker B")
	_assert_true(min_dist_to_breaker_b > max_interact_reach,
		"Closest walkable point south of railing (%.1f px) is safely beyond interact reach (%.1f px)" % [
			min_dist_to_breaker_b, max_interact_reach])

	sig.free()


func test_exit_trigger_unskippable_on_path_to_door_exit_north() -> void:
	var sig := (load(SIGNAL_SCENE_PATH) as PackedScene).instantiate() as Node2D
	var door := sig.get_node("door_exit_north") as Area2D
	var door_col := door.get_node("CollisionShape2D") as CollisionShape2D
	var door_radius: float = (door_col.shape as CircleShape2D).radius

	var trigger := sig.get_node("exit_trigger_vestibule") as Area2D
	var trig_col := trigger.get_node("CollisionShape2D") as CollisionShape2D
	var trig_size: Vector2 = (trig_col.shape as RectangleShape2D).size

	var door_center := door.global_position
	var trig_center := trigger.global_position

	var trig_rect := Rect2(trig_center - trig_size / 2.0, trig_size)

	# Verify every point of door circle lies inside trigger rectangle
	var num_samples := 32
	var all_samples_enclosed := true
	for i in num_samples:
		var angle := (float(i) / float(num_samples)) * TAU
		var sample_pt := door_center + Vector2(cos(angle), sin(angle)) * door_radius
		if not trig_rect.has_point(sample_pt):
			all_samples_enclosed = false
			break

	_assert_true(all_samples_enclosed, "exit_trigger_vestibule completely encloses door_exit_north collision shape")

	# Verify path approach from W3 (528, 184) to door_exit_north (448, 128) crosses trigger
	var approach_start := W3
	var approach_end := door_center
	var hit_trigger_before_door := false
	for step_idx in 100:
		var t := float(step_idx) / 100.0
		var pt := approach_start.lerp(approach_end, t)
		if trig_rect.has_point(pt):
			hit_trigger_before_door = true
			break

	_assert_true(hit_trigger_before_door, "Direct approach from W3 enters exit_trigger_vestibule before reaching door center")

	sig.free()


func test_shortest_walkable_path_between_breakers_exceeds_600_px() -> void:
	var sig := (load(SIGNAL_SCENE_PATH) as PackedScene).instantiate() as Node2D
	var nav_data := _build_nav_grid(sig, 4)
	var grid: AStarGrid2D = nav_data["grid"]
	var min_x: int = nav_data["min_x"]
	var min_y: int = nav_data["min_y"]
	var cell_size: int = nav_data["cell_size"]

	var start_coord := Vector2i(int((W0.x - min_x) / cell_size), int((W0.y - min_y) / cell_size))
	var goal_coord := Vector2i(int((W3.x - min_x) / cell_size), int((W3.y - min_y) / cell_size))

	_assert_false(grid.is_point_solid(start_coord), "W0 standing spot is walkable")
	_assert_false(grid.is_point_solid(goal_coord), "W3 standing spot is walkable")

	var path := grid.get_point_path(start_coord, goal_coord)
	_assert_true(path.size() > 1, "Walkable path between W0 and W3 exists")

	var total_path_length := 0.0
	for i in path.size() - 1:
		total_path_length += path[i].distance_to(path[i + 1])

	_assert_true(total_path_length >= 600.0,
		"Shortest walkable path (%.1f px) is >= 600.0 px (exceeds 300 ticks at 120 px/s)" % total_path_length)

	sig.free()
