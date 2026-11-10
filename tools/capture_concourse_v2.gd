extends SceneTree

## TLF-080: Capture 4 windowed 960x540 screenshots for Concourse West v2.
## 1. arrival_960x540.png   at Vector2(224, 144) (door_entry_west spawn, entry hall)
## 2. gate_960x540.png      at Vector2(320, 192) (turnstile gate, courier, dividers)
## 3. dial_960x540.png      at Vector2(576, 216) (dials, validator, clock, bench)
## 4. east_door_960x540.png at Vector2(640, 352) (east door, commuters, staff door)

const SPOTS: Array = [
	["arrival_960x540.png", Vector2(224, 144)],
	["gate_960x540.png", Vector2(320, 192)],
	["dial_960x540.png", Vector2(576, 216)],
	["east_door_960x540.png", Vector2(640, 352)],
]


func _initialize() -> void:
	var timer := create_timer(30.0)
	timer.timeout.connect(func():
		printerr("TIMEOUT: capture_concourse_v2 exceeded 30 seconds")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "Renderer must be windowed")

	var save = root.get_node_or_null("SaveService")
	if save != null:
		save.save_root = "user://tlf080_capture_saves"

	var ch01_scene: PackedScene = load("res://scenes/chapters/ch01/Chapter01.tscn")
	var ch01: Node = ch01_scene.instantiate()
	root.add_child(ch01)

	for i in range(10):
		await process_frame

	var player: CharacterBody2D = ch01.get_node("Player") as CharacterBody2D
	var router: RoomRouter = ch01.get_node("RoomRouter") as RoomRouter

	# Enter concourse_west
	router.enter_room(&"ch01.concourse_west", &"door_entry_west")
	for i in range(10):
		await process_frame

	var cam: RoomCamera = router.camera as RoomCamera
	assert(cam != null, "RoomCamera must exist on router")

	var diag: DialogueBox = ch01.find_child("DialogueBox", true, false) as DialogueBox
	if diag != null:
		diag.visible = false
		diag.is_active = false
		diag.is_blocking = false

	var out_dir := ProjectSettings.globalize_path("res://docs/handoffs/TLF-080")
	DirAccess.make_dir_recursive_absolute(out_dir)

	for entry in SPOTS:
		var filename: String = entry[0]
		var spot: Vector2 = entry[1]

		player.global_position = spot
		player.velocity = Vector2.ZERO
		cam.snap_now()

		for i in range(10):
			await process_frame
		await RenderingServer.frame_post_draw

		var img := root.get_texture().get_image()
		assert(img.get_size() == Vector2i(960, 540), "Screenshot size must be 960x540 (got %s)" % img.get_size())
		var out_path := out_dir.path_join(filename)
		var err := img.save_png(out_path)
		assert(err == OK, "Failed to save " + out_path)
		print("CAPTURED: %s at %s -> %s" % [filename, str(spot), out_path])

	print("ALL 4 SCREENSHOTS CAPTURED SUCCESSFULLY")
	quit(0)
