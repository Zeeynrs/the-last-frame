extends "res://tests/support/base_test.gd"

## Real-input test at spawn verifying targeting ignores checkpoints and non-targetable triggers (TLF-043).

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_spawn_targeting_saves"
const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"


func _record_real_save_state() -> Dictionary:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	var mtime := FileAccess.get_modified_time(REAL_SAVE_SLOT_0) if exists else 0
	return {"exists": exists, "mtime": mtime}


func _assert_real_save_unchanged(before: Dictionary, context: String) -> void:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	_assert_eq(exists, before["exists"], "%s: real save existence unchanged" % context)
	if before["exists"]:
		var mtime := FileAccess.get_modified_time(REAL_SAVE_SLOT_0)
		_assert_eq(mtime, before["mtime"], "%s: real save modified time unchanged" % context)


func _cleanup_test_save_dir() -> void:
	var dir := DirAccess.open(TEST_SAVE_ROOT)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
		for sub_dir in dir.get_directories():
			dir.remove(sub_dir)
	if DirAccess.dir_exists_absolute(TEST_SAVE_ROOT):
		DirAccess.remove_absolute(TEST_SAVE_ROOT)


func _make_ch01() -> Chapter01:
	_cleanup_test_save_dir()
	var ch01_scene := load(CH01_SCENE_PATH) as PackedScene
	var ch01 := ch01_scene.instantiate() as Chapter01
	var router := ch01.get_node_or_null("RoomRouter") as RoomRouter
	if router != null:
		var store := SaveStore.new()
		store.name = "TestSaveStore"
		store.save_root = TEST_SAVE_ROOT
		router.add_child(store)
		router.save_service = store

	var hud_scene := load("res://scenes/ui/HUD.tscn") as PackedScene
	var hud := hud_scene.instantiate() as HUD
	ch01.add_child(hud)

	_tree().root.add_child(ch01)
	return ch01


func _cleanup_ch01(ch01: Node) -> void:
	if ch01 == null:
		return
	var router: RoomRouter = ch01.get_node_or_null("RoomRouter")
	if router != null and router.current_room != null:
		router._unload_current()
	if ch01.get_parent() != null:
		ch01.get_parent().remove_child(ch01)
	ch01.free()
	_cleanup_test_save_dir()


func test_spawn_targeting_ignores_checkpoint_and_picks_up_watch() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(5)

	var player := ch01.player
	_assert_true(player != null, "Player exists in Chapter 01")
	var pocket_watch: PocketWatch = player.pocket_watch if player != null else null
	_assert_true(pocket_watch != null, "PocketWatch exists on Player")

	# (1) At spawn (352, 160) without moving:
	# Neither player.current_target nor PocketWatch.current_target should be the checkpoint
	var player_target = player.current_target
	var watch_target = pocket_watch.current_target

	var player_target_id: StringName = player_target.object_id if player_target != null else &""
	var watch_target_id: StringName = watch_target.object_id if watch_target != null else &""

	_assert_true(
		player_target_id != &"ch01.arrival_platform.checkpoint",
		"player.current_target at spawn must NOT be checkpoint (got '%s')" % str(player_target_id)
	)
	_assert_true(
		watch_target_id != &"ch01.arrival_platform.checkpoint",
		"PocketWatch.current_target at spawn must NOT be checkpoint (got '%s')" % str(watch_target_id)
	)

	# (2) Real-input walking to the watch pickup at (368, 168)
	var pickup_pos := Vector2(368, 168)
	var arrived := await walk_to(player, "pocket_watch_pickup", pickup_pos, func():
		return player.current_target != null and player.current_target.object_id == &"global.pocket_watch"
	, 180)

	_assert_true(arrived, "Player walked to pocket watch pickup")
	_assert_true(player.current_target != null, "Player has a current_target near pickup")
	if player.current_target != null:
		_assert_eq(player.current_target.object_id, &"global.pocket_watch", "Target is global.pocket_watch")

	# (3) Press interact with real input -> acquires pocket watch
	await tap(&"interact", 2)
	await physics_frames(5)

	var acquired: bool = ch01.session.narrative_state.get_flag(&"ch01.flag.pocket_watch_acquired", false)
	_assert_true(acquired, "ch01.flag.pocket_watch_acquired flag set after interacting with pickup")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_spawn_targeting_ignores_checkpoint_and_picks_up_watch")
