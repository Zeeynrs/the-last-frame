extends SceneTree

## TLF-076: Capture 5 windowed Forward+ 960x540 screenshots for Beat 06 Mira departure memory:
## 1. doc_mira_side_start.png at Vector2(120, 394)
## 2. doc_mira_side_bench.png at Vector2(520, 394)
## 3. doc_mira_side_mira.png  at Vector2(780, 394)
## 4. doc_mira_side_clock.png at Vector2(1180, 394)
## 5. doc_mira_side_exit.png  at Vector2(1380, 394)

const SPOTS: Array = [
	["doc_mira_side_start.png", Vector2(120, 394)],
	["doc_mira_side_bench.png", Vector2(520, 394)],
	["doc_mira_side_mira.png", Vector2(780, 394)],
	["doc_mira_side_clock.png", Vector2(1180, 394)],
	["doc_mira_side_exit.png", Vector2(1380, 394)],
]


func _initialize() -> void:
	var timer := create_timer(20.0)
	timer.timeout.connect(func():
		printerr("TIMEOUT: capture_mira_memory_side exceeded 20 seconds")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "Renderer must be windowed (Forward+)")

	# Protect user's real saves
	var save = root.get_node_or_null("SaveService")
	if save != null:
		save.save_root = "user://tlf076_capture_saves"

	var ch01_scene: PackedScene = load("res://scenes/chapters/ch01/Chapter01.tscn")
	var ch01: Node = ch01_scene.instantiate()
	root.add_child(ch01)

	# Allow ready and initialization
	for i in range(10):
		await process_frame

	var player: CharacterBody2D = ch01.get_node("Player") as CharacterBody2D
	var router: RoomRouter = ch01.get_node("RoomRouter") as RoomRouter

	# Enter the side memory room
	router.enter_room(&"ch01.side_mira_memory", &"", &"ch01.side_mira_memory.anchor")
	for i in range(5):
		await process_frame

	var cam: RoomCamera = router.camera as RoomCamera
	assert(cam != null, "RoomCamera must exist on router")

	# Dismiss / hide dialogue box if open
	var diag: DialogueBox = ch01.find_child("DialogueBox", true, false) as DialogueBox
	if diag != null:
		diag.visible = false
		diag.is_active = false
		diag.is_blocking = false

	var out_dir := ProjectSettings.globalize_path("res://docs/handoffs/TLF-076")
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
		assert(img.get_size() == Vector2i(960, 540), "Screenshot size must be 960x540")
		var out_path := out_dir.path_join(filename)
		var err := img.save_png(out_path)
		assert(err == OK, "Failed to save " + out_path)
		print("CAPTURED: %s at %s -> %s" % [filename, str(spot), out_path])

	print("ALL 5 SCREENSHOTS CAPTURED SUCCESSFULLY")
	quit(0)
