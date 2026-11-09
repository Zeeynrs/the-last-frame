extends SceneTree

## TLF-079: windowed 960 x 540 screenshots of the history dial readout in Concourse West.
## Run it in a renamed scratch copy, never in a worktree (it writes a playtest log and an autosave):
##   godot --path . -s tools/capture_tlf079.gd
## Setup only (SO-01 and PZ-001 marked SOLVED, Rewind unlocked, Elias placed on the dial_line
## stand spot from the playthrough); the Rewind itself goes through PocketWatch.activate_watch().
## Output: res://docs/handoffs/TLF-079/shot_*.png, each the 960 x 540 viewport image.

const OUT := "res://docs/handoffs/TLF-079"

var _ch01: Node = null


func _initialize() -> void:
	var timer := create_timer(60.0)
	timer.timeout.connect(func():
		printerr("TIMEOUT: capture_tlf079 exceeded 60 seconds")
		quit(1)
	)
	call_deferred("_run")


func _shot(name: String) -> void:
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	assert(img.get_size() == Vector2i(960, 540), "Screenshot size must be 960x540")
	var path := ProjectSettings.globalize_path(OUT).path_join(name)
	assert(img.save_png(path) == OK, "Failed to save " + path)
	print("CAPTURED: %s" % name)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _report(hud: HUD, dial: HistoryDial, label: String) -> void:
	print("%s: dial %s index %d key %s | readout visible %s text '%s' rect %s | feedback visible %s text '%s' rect %s" % [
		label, dial.name, dial.index, dial.label_key(), hud.readout_panel.visible, hud.readout_label.text,
		hud.readout_panel.get_global_rect(), hud.feedback_panel.visible, hud.feedback_label.text,
		hud.feedback_panel.get_global_rect()])


func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "Renderer must be windowed (Forward+)")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var save = root.get_node_or_null("SaveService")
	if save != null:
		save.save_root = "user://tlf079_capture_saves"

	_ch01 = (load("res://scenes/chapters/ch01/Chapter01.tscn") as PackedScene).instantiate()
	root.add_child(_ch01)
	await _frames(30)
	var session := _ch01.get_node("GameSession") as GameSession
	var router := _ch01.get_node("RoomRouter") as RoomRouter
	var player := _ch01.get_node("Player") as Player
	var diag := _ch01.call("get_dialogue_box") as DialogueBox
	if diag != null and diag.is_active:
		diag.finish_sequence()
	for puzzle_id in [&"CH1-SO-01", &"CH1-PZ-001"]:
		session.puzzle_service.mark_solved(puzzle_id)
	session.narrative_state.set_flag(&"ch01.npc.n05.traced")
	router.enter_room(&"ch01.concourse_west", &"door_entry_west")
	await _frames(10)
	if diag != null and diag.is_active:
		diag.finish_sequence()

	var watch := player.pocket_watch
	while watch.selected_ability != &"rewind":
		watch.next_ability()
	player.global_position = Vector2(432, 152)
	router.camera.snap_now()
	await _frames(10)
	var hud := player.hud
	hud.hide_feedback()   # the "Rewind unlocked." toast from the setup flag
	await _frames(2)
	var line := session.id_registry.resolve(&"ch01.concourse_west.dial_line") as HistoryDial
	print("TARGETS: watch %s, interact %s" % [watch.current_target, player.current_target])

	_report(hud, line, "INDEX 5")
	await _shot("shot_01_dial_line_index5.png")

	var result := watch.activate_watch()
	print("REWIND: ok %s reason %s" % [result.ok, result.reason])
	await _frames(10)
	_report(hud, line, "INDEX 4")
	await _shot("shot_02_dial_line_index4.png")

	# A refusal while the readout is up: the feedback line stays below it, unchanged.
	hud.show_feedback(&"no_history", &"watch")
	await _frames(2)
	_report(hud, line, "WITH FEEDBACK")
	await _shot("shot_03_readout_with_feedback.png")

	# Blur: Elias walks off (placed back by the turnstile), the readout is gone.
	hud.hide_feedback()
	player.global_position = Vector2(304, 136)
	await _frames(10)
	_report(hud, line, "BLUR")
	await _shot("shot_04_blur_no_readout.png")

	print("ALL TLF-079 SCREENSHOTS CAPTURED")
	quit(0)
