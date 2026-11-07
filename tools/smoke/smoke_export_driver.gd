extends SceneTree

## TLF-060 smoke driver for the EXPORTED PCK. It is not part of the build: export_presets.cfg
## excludes tools/*, and Godot loads this file from disk with -s. The official export templates
## have no -s, so it runs on the exported PCK with the official 4.7.2 editor binary; run_smoke.ps1
## plays the release exe itself through its window. run_smoke.ps1 runs it; by hand:
##   Godot_v4.7.2-stable_win64.exe --main-pack <build>/TheLastFrame.pck -s <abs path>/smoke_export_driver.gd
##       -- --phase=new|continue --out=<dir>
##
## It boots the project's main scene (Boot -> title), plays with keyboard input only and checks
## each step. Input is InputEventKey with the physical keycode the exported InputMap binds to the
## action, through Input.parse_input_event (the same path as a key press). Screenshots are the
## exported build's own viewport. Lines start with "SMOKE " for the wrapper.
##
## new:      title (no save, Continue disabled) -> Enter = New Game -> Chapter 1 -> walk to the
##           pocket watch, E picks it up, walk back into the arrival checkpoint -> autosave.
## continue: title (Continue enabled and selected) -> Enter = Continue -> Chapter 1 restored with
##           the watch flag -> walk a little.
## The driver never quits on success: it prints "SMOKE READY_TO_CLOSE" and the wrapper closes the
## window with WM_CLOSE (the window's X button). On a failed check it prints "SMOKE FAIL" and
## quits with exit code 1.

const ARRIVAL := &"ch01.arrival_platform"
const CHECKPOINT := &"ch01.cp.arrival"
const WATCH_FLAG := &"ch01.flag.pocket_watch_acquired"
const CHECKPOINT_POS := Vector2(352, 160)   # checkpoint zone (28 x 16) = new-game spawn
const OUTSIDE_POS := Vector2(318, 140)      # north-west of the zone, on the platform
const WATCH_STAND := Vector2(352, 176)      # pocket_watch_pickup (368,168) is the interact target here
const FONT_PATH := "res://assets/ui/fonts/tlf_pixel_mono.ttf"
const KEY_PATTERN := "^[A-Z][A-Z0-9]*_[A-Z0-9_]+$"

var phase: String = ""
var out_dir: String = ""
var failed: bool = false
var _held: Array[StringName] = []
var _shot: int = 0
var _key_regex := RegEx.create_from_string(KEY_PATTERN)


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	_log("phase=%s out=%s" % [phase, out_dir])
	_log("executable=%s" % OS.get_executable_path())
	_log("version=%s debug_build=%s display=%s renderer=%s" % [Engine.get_version_info()["string"],
		OS.is_debug_build(), DisplayServer.get_name(), RenderingServer.get_current_rendering_driver_name()])
	var user_dir := OS.get_user_data_dir()
	_log("user_data_dir=%s" % user_dir)
	_check(not user_dir.replace("\\", "/").ends_with("/The Last Frame"), "user dir is not the real 'The Last Frame' folder")
	_check(user_dir.contains("TLF Smoke"), "user dir belongs to the renamed smoke project")
	if failed or not (phase in ["new", "continue"]) or out_dir.is_empty():
		_fail("bad arguments or user dir")
		return

	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	var title: Control = await _wait_for_scene("TitleScreen", 300)
	if title == null:
		_fail("title screen did not open from %s" % ProjectSettings.get_setting("application/run/main_scene"))
		return
	await _frames(30)
	var store := root.get_node_or_null("/root/SaveService") as SaveStore
	_log("save_root=%s -> %s" % [store.save_root, ProjectSettings.globalize_path(store.save_root)])
	_check(store.save_root == SaveStore.DEFAULT_ROOT, "the exported game uses the player save root %s" % SaveStore.DEFAULT_ROOT)
	_check_title(title)
	if phase == "new":
		await _phase_new(title, store)
	else:
		await _phase_continue(title, store)
	_release_all()
	if failed:
		_fail("phase %s had failed checks" % phase)
		return
	_log("PASS phase=%s" % phase)
	_log("READY_TO_CLOSE")


func _phase_new(title: Control, store: SaveStore) -> void:
	_check(not store.has_slot(0), "fresh user dir: no save in slot 0")
	_check(not title.continue_enabled, "Continue disabled without a save")
	_check(title.selected_item() == &"new_game", "New Game selected")
	await _screenshot("title_new_game")
	await _tap(&"confirm")
	var ch01: Node = await _wait_for_scene("Chapter01", 300)
	if not _check(ch01 != null, "New Game loads Chapter01"):
		return
	await _frames(60)
	var router: RoomRouter = ch01.room_router
	var player: Node2D = ch01.player
	_check(router.current_room_id == ARRIVAL, "new game starts on the arrival platform (%s)" % router.current_room_id)
	_log("player at %s" % player.global_position)
	_check_labels("chapter 1 start")
	await _screenshot("ch01_new_game")
	await _dismiss_blocking(ch01)

	var saves := [0]
	router.checkpoint_reached.connect(func(id: StringName, error: Error) -> void:
		_log("checkpoint_reached %s error=%d" % [id, error])
		if id == CHECKPOINT and error == OK:
			saves[0] += 1)
	var start := Time.get_ticks_msec()
	await _walk(player, OUTSIDE_POS, "out of the checkpoint")
	await _walk(player, WATCH_STAND, "to the pocket watch")
	var watch: Node = ch01.session.id_registry.resolve(&"global.pocket_watch")
	await _frames(2)
	_check(player.current_target == watch, "the pocket watch is the interact target")
	await _tap(&"interact")
	await _until(func() -> bool: return bool(ch01.session.narrative_state.get_flag(WATCH_FLAG)), 30)
	_check(bool(ch01.session.narrative_state.get_flag(WATCH_FLAG)), "E on the watch picks it up")
	await _frames(20)
	_log("HUD feedback '%s', dialogue '%s'" % [player.hud.feedback_label.text, ch01.get_dialogue_box().text_label.text])
	_check_labels("after the watch pickup")
	await _screenshot("ch01_watch_pickup")
	await _dismiss_blocking(ch01)
	await _wander(player)
	await _walk(player, OUTSIDE_POS, "out of the checkpoint again")
	saves[0] = 0
	await _walk(player, CHECKPOINT_POS, "into the checkpoint")
	await _until(func() -> bool: return saves[0] > 0, 60)
	_log("real input for %.1f s" % ((Time.get_ticks_msec() - start) / 1000.0))
	_check(saves[0] > 0, "walking into %s writes the autosave" % CHECKPOINT)
	var read := store.read_slot(0)
	_check(read.get("ok", false), "slot 0 reads back (%s)" % read.get("reason", ""))
	if read.get("ok", false):
		var data: Dictionary = read["data"]
		_check(data["checkpoint_id"] == String(CHECKPOINT), "the save's checkpoint is %s" % CHECKPOINT)
		_check(bool(data["narrative_flags"].get(String(WATCH_FLAG), data["narrative_flags"].get(WATCH_FLAG, false))),
			"the save holds the watch flag")
	_log("save file %s exists=%s" % [ProjectSettings.globalize_path(store.save_root.path_join("slot_0.json")),
		FileAccess.file_exists(store.save_root.path_join("slot_0.json"))])
	await _frames(20)
	await _screenshot("ch01_checkpoint_saved")


func _phase_continue(title: Control, store: SaveStore) -> void:
	_check(store.has_slot(0), "the save from the new-game run is in slot 0")
	_check(title.continue_enabled, "Continue enabled")
	_check(title.selected_item() == &"continue", "Continue selected by default")
	await _screenshot("title_continue")
	await _tap(&"confirm")
	var ch01: Node = await _wait_for_scene("Chapter01", 300)
	if not _check(ch01 != null, "Continue loads Chapter01"):
		return
	await _frames(60)
	var router: RoomRouter = ch01.room_router
	var player: Node2D = ch01.player
	_check(router.current_room_id == ARRIVAL, "Continue restores the arrival platform (%s)" % router.current_room_id)
	_check(bool(ch01.session.narrative_state.get_flag(WATCH_FLAG)), "Continue restores the watch flag")
	_check(ch01.session.ability_unlocks.is_unlocked(&"trace"), "Trace available after Continue")
	_log("player at %s (checkpoint %s)" % [player.global_position, CHECKPOINT_POS])
	_check(player.global_position.distance_to(CHECKPOINT_POS) < 24.0, "respawn at the checkpoint")
	_check_labels("after Continue")
	await _screenshot("ch01_continued")
	await _dismiss_blocking(ch01)
	var start := Time.get_ticks_msec()
	await _wander(player)
	await _walk(player, OUTSIDE_POS, "away from the checkpoint")
	await _walk(player, CHECKPOINT_POS, "back to the checkpoint")
	_log("real input for %.1f s" % ((Time.get_ticks_msec() - start) / 1000.0))
	await _frames(20)
	await _screenshot("ch01_continue_walk")


# --- checks ---------------------------------------------------------------------------------

func _check_title(title: Control) -> void:
	var label: Label = title.title_label
	_log("title text '%s', menu '%s' / '%s' / '%s'" % [label.text, title.get_node("Menu/NewGame").text,
		title.get_node("Menu/Continue").text, title.get_node("Menu/Quit").text])
	_check(label.text != "UI_TITLE_GAME" and not label.text.is_empty(), "the title is translated")
	var font := label.get_theme_font(&"font")
	_log("title font %s name='%s'" % [font.resource_path if font != null else "null", font.get_font_name() if font != null else ""])
	_check(font != null and font.resource_path == FONT_PATH, "the title uses the pixel font %s" % FONT_PATH)
	_check_labels("title")


## Every visible Label in the tree shows text, not a translation key.
func _check_labels(where: String) -> void:
	var shown := 0
	for node in root.find_children("*", "Label", true, false):
		var label := node as Label
		if not label.is_visible_in_tree() or label.text.strip_edges().is_empty():
			continue
		shown += 1
		var bare := label.text.strip_edges().trim_prefix("> ").trim_suffix(" <")
		if _key_regex.search(bare) != null:
			_check(false, "%s: label %s shows the key '%s'" % [where, label.get_path(), label.text])
	_log("%s: %d visible labels checked for translation keys" % [where, shown])


# --- input ----------------------------------------------------------------------------------

func _key_for(action: StringName) -> Key:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode != KEY_NONE:
			return event.physical_keycode
	return KEY_NONE


func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = _key_for(action)
	event.pressed = pressed
	Input.parse_input_event(event)


func _tap(action: StringName) -> void:
	_log("key %s (%s)" % [OS.get_keycode_string(_key_for(action)), action])
	_send(action, true)
	await _frames(3)
	_send(action, false)
	await _frames(3)


func _hold(actions: Array[StringName]) -> void:
	for action in _held.duplicate():
		if not actions.has(action):
			_send(action, false)
			_held.erase(action)
	for action in actions:
		if not _held.has(action):
			_send(action, true)
			_held.append(action)


func _release_all() -> void:
	_hold([])


## Advances a blocking dialogue line (Beat 01 at boot, memory lines) with E, as a player would.
func _dismiss_blocking(ch01: Node) -> void:
	var diag: DialogueBox = ch01.get_dialogue_box()
	for i in 20:
		if diag == null or not (diag.is_active and diag.is_blocking):
			return
		await _tap(&"interact")
		await _frames(10)
	_check(false, "blocking dialogue still open after 20 taps")


## About 4 s of free movement on the platform: each key combination held for 40 physics frames.
func _wander(player: Node2D) -> void:
	var legs: Array = [[&"move_left"], [&"move_up"], [&"move_right"], [&"move_down"],
		[&"move_up", &"move_left"], [&"move_down", &"move_right"]]
	var travelled := 0.0
	var last := player.global_position
	for leg in legs:
		var keys: Array[StringName] = []
		keys.assign(leg)
		_hold(keys)
		for i in 40:
			await physics_frame
			travelled += player.global_position.distance_to(last)
			last = player.global_position
	_hold([])
	_log("wandered %d legs, %.0f px, now at %s" % [legs.size(), travelled, player.global_position])
	_check(travelled > 100.0, "the keys move the player (%.0f px)" % travelled)


## Holds the arrow/WASD keys that head most directly to `target` until the player is there.
func _walk(player: Node2D, target: Vector2, label: String, max_frames: int = 600) -> bool:
	for i in max_frames:
		if player.global_position.distance_to(target) <= 3.0:
			_hold([])
			_log("walked %s: %s" % [label, player.global_position])
			return true
		var delta := target - player.global_position
		var best: Array[StringName] = []
		var best_score := -INF
		for x in [-1, 0, 1]:
			for y in [-1, 0, 1]:
				if x == 0 and y == 0:
					continue
				var score: float = Player.compute_movement_vector(Vector2(x, y)).dot(delta.normalized())
				if score > best_score:
					best_score = score
					best = []
					if x < 0: best.append(&"move_left")
					if x > 0: best.append(&"move_right")
					if y < 0: best.append(&"move_up")
					if y > 0: best.append(&"move_down")
		_hold(best)
		await physics_frame
	_hold([])
	_check(false, "walk %s: did not reach %s (player at %s)" % [label, target, player.global_position])
	return false


# --- helpers --------------------------------------------------------------------------------

func _wait_for_scene(scene_name: String, max_frames: int) -> Node:
	for i in max_frames:
		if current_scene != null and current_scene.name == scene_name:
			return current_scene
		await process_frame
	return null


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _until(condition: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await physics_frame
	return condition.call()


func _screenshot(label: String) -> void:
	await RenderingServer.frame_post_draw
	_shot += 1
	var path := out_dir.path_join("%s_%02d_%s.png" % [phase, _shot, label])
	var image := root.get_texture().get_image()
	var error := image.save_png(path) if image != null else ERR_CANT_CREATE
	_log("screenshot %s size=%s error=%d" % [path, image.get_size() if image != null else Vector2i.ZERO, error])
	_check(error == OK, "screenshot %s saved" % label)


func _check(ok: bool, what: String) -> bool:
	_log("%s %s" % ["CHECK ok  " if ok else "CHECK FAIL", what])
	if not ok:
		failed = true
	return ok


func _fail(why: String) -> void:
	_release_all()
	_log("FAIL %s" % why)
	quit(1)


func _log(line: String) -> void:
	print("SMOKE %s" % line)
