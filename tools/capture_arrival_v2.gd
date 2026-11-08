extends SceneTree

## TLF-069: Re-capture 4 windowed Forward+ screenshots for Arrival Platform v2.
## 1. doc_arrival_v2_spawn.png     at Vector2(160, 224)
## 2. doc_arrival_v2_watch.png     at Vector2(240, 232)
## 3. doc_arrival_v2_pit_edge.png  at Vector2(512, 288)
## 4. doc_arrival_v2_gate.png      at Vector2(720, 328)

const SPOTS: Array = [
	["doc_arrival_v2_spawn.png", Vector2(160, 224)],
	["doc_arrival_v2_watch.png", Vector2(240, 232)],
	["doc_arrival_v2_pit_edge.png", Vector2(512, 288)],
	["doc_arrival_v2_gate.png", Vector2(720, 328)],
]


func _initialize() -> void:
	# Safety timeout: quit after 15 seconds if anything hangs
	var timer := create_timer(15.0)
	timer.timeout.connect(func():
		printerr("TIMEOUT: capture_arrival_v2 exceeded 15 seconds")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "Renderer must be windowed (Forward+)")

	# Protect user's real saves
	var save = root.get_node_or_null("SaveService")
	if save != null:
		save.save_root = "user://tlf069_capture_saves"

	var ch01_scene: PackedScene = load("res://scenes/chapters/ch01/Chapter01.tscn")
	var ch01: Node = ch01_scene.instantiate()
	root.add_child(ch01)

	# Allow ready and enter_room to run
	for i in range(10):
		await process_frame

	var player: CharacterBody2D = ch01.get_node("Player") as CharacterBody2D
	var router: RoomRouter = ch01.get_node("RoomRouter") as RoomRouter
	var cam: RoomCamera = router.camera as RoomCamera
	assert(cam != null, "RoomCamera must exist on router")

	# Dismiss / hide dialogue box if open
	var diag: DialogueBox = ch01.find_child("DialogueBox", true, false) as DialogueBox
	if diag != null:
		diag.visible = false
		diag.is_active = false
		diag.is_blocking = false

	var out_dir := ProjectSettings.globalize_path("res://docs/handoffs/TLF-069")
	DirAccess.make_dir_recursive_absolute(out_dir)

	for entry in SPOTS:
		var filename: String = entry[0]
		var spot: Vector2 = entry[1]

		player.global_position = spot
		player.velocity = Vector2.ZERO
		cam.snap_now()

		# Render several frames so animations, shaders, and camera settle
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw

		var img := root.get_texture().get_image()
		assert(img.get_size() == Vector2i(640, 360), "Screenshot size must be 640x360")
		var out_path := out_dir.path_join(filename)
		var err := img.save_png(out_path)
		assert(err == OK, "Failed to save " + out_path)
		print("CAPTURED: %s at %s -> %s" % [filename, str(spot), out_path])

	print("ALL 4 SCREENSHOTS CAPTURED SUCCESSFULLY")
	quit(0)
