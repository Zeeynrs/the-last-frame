extends SceneTree

## TLF-072: windowed 960 x 540 evidence screenshots (ADR-023 addendum 3).
## Run it in a renamed scratch copy, never in a worktree (it writes a playtest log and an autosave):
##   godot --path . -s tools/capture_tlf072.gd
## Output: res://docs/handoffs/TLF-072/shot_*.png, each the 960 x 540 viewport image.

const OUT := "res://docs/handoffs/TLF-072"

var _ch01: Node = null


func _initialize() -> void:
	var timer := create_timer(90.0)
	timer.timeout.connect(func():
		printerr("TIMEOUT: capture_tlf072 exceeded 90 seconds")
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


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "Renderer must be windowed (Forward+)")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var save = root.get_node_or_null("SaveService")
	if save != null:
		save.save_root = "user://tlf072_capture_saves"

	# 1. Title screen.
	var title: Node = (load("res://scenes/ui/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await _shot("shot_01_title.png")
	title.free()

	# 2. Chapter 1 at boot: the pilot room (30 x 18) with Beat 01's first line and the HUD.
	_ch01 = (load("res://scenes/chapters/ch01/Chapter01.tscn") as PackedScene).instantiate()
	root.add_child(_ch01)
	for i in range(30):
		await process_frame
	var player := _ch01.get_node("Player") as CharacterBody2D
	var router := _ch01.get_node("RoomRouter") as RoomRouter
	var cam := router.camera
	await _shot("shot_02_dialogue_line_arrival.png")
	var diag := _ch01.call("get_dialogue_box") as DialogueBox
	if diag != null and diag.is_active:
		diag.finish_sequence()
	await _shot("shot_03_arrival_spawn.png")
	player.global_position = Vector2(720, 328)
	cam.snap_now()
	await _shot("shot_04_arrival_gate.png")
	print("CAMERA arrival: bounds %s centre %s view %s" % [cam.bounds, cam.get_screen_center_position(), cam.view_rect()])

	# 3. Ability wheel and a feedback line (HUD).
	var wheel := root.find_child("AbilityWheel", true, false)
	if wheel != null:
		wheel.call("open_wheel")
		await _wait(0.4)
		await _shot("shot_05_ability_wheel.png")
		wheel.call("close_wheel", false)
		await _wait(0.3)
	var hud := root.find_child("HUD", true, false)
	if hud != null:
		hud.call("show_feedback", &"no_history", &"watch")
		await _shot("shot_06_feedback_line.png")
		hud.call("hide_feedback")

	# 4. Document viewer: the arrival platform's last-service notice.
	var doc_node := _ch01.find_child("doc_last_service", true, false)
	var viewer := _ch01.call("get_document_viewer") as DocumentViewer
	if doc_node != null and viewer != null and doc_node.get("document") != null:
		viewer.open_document(doc_node.get("document"))
		await _shot("shot_07_document_viewer.png")
		viewer.close_document()
		await _wait(0.2)

	# 5. Old rooms (no metadata/room_shape): centred with the margin around them.
	for id in [&"ch01.maintenance_bay", &"ch01.signal_control"]:
		router.enter_room(id)
		var anchors := router.current_room.find_children("*", "SafeAnchor", true, false)
		if not anchors.is_empty():
			player.global_position = (anchors[0] as Node2D).global_position
			cam.snap_now()
		await _wait(0.2)
		if diag != null and diag.is_active:
			diag.finish_sequence()
		await _shot("shot_08_old_room_%s.png" % String(id).get_slice(".", 1))
		print("CAMERA %s: bounds %s centre %s view %s" % [id, cam.bounds, cam.get_screen_center_position(), cam.view_rect()])

	# 6. Beat 10 cinematic, letterboxed: start (pan 0, first line) and end (pan -320, "Again.").
	router.enter_room(&"ch01.street_exit")
	await _wait(0.2)
	if diag != null and diag.is_active:
		diag.finish_sequence()
	_ch01.call("_trigger_beat10_outro")
	var outro := root.find_child("Ch01Outro", true, false) as Ch01Outro
	await _wait(0.8)
	print("OUTRO start pan x %s plate %s" % [outro.get_current_pan_x(), outro.plate_container.position])
	await _shot("shot_09_cinematic_start.png")
	await _wait(7.6)
	print("OUTRO end pan x %s plate %s" % [outro.get_current_pan_x(), outro.plate_container.position])
	await _shot("shot_10_cinematic_end.png")
	print("OUTRO end line %d active %s" % [diag.current_line_index if diag != null else -2, diag.is_active if diag != null else false])

	# 7. Chapter-complete overlay (the cinematic ends by itself after its 1.2 s hold) with the
	# SceneRouter hint.
	await _wait(2.0)
	print("OUTRO finished: %s" % [not is_instance_valid(outro)])
	var scene_router := root.get_node_or_null("SceneRouter")
	if scene_router != null:
		scene_router.call("_show_complete_hint")   # shown by SceneRouter when it launched the chapter
	await _shot("shot_11_chapter_complete.png")

	print("ALL TLF-072 SCREENSHOTS CAPTURED")
	quit(0)
