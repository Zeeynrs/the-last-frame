extends SceneTree

const ROOM := &"ch01.maintenance_bay"

const SHOTS := [
	["arrival_960x540", Vector2(272, 120), "idle_se"],
	["hatch_960x540", Vector2(384, 144), "idle_se"],
	["gear_bay_960x540", Vector2(512, 176), "idle_ne"],
	["gear_stand_spot_960x540", Vector2(496, 184), "idle_ne"],
	["pocket_safe_anchor_east_960x540", Vector2(544, 240), "idle_se"],
	["east_door_960x540", Vector2(640, 288), "idle_se"]
]

var _ch01: Node2D
var _router: RoomRouter
var _player: Player
var _out: String = "docs/handoffs/TLF-085"


func _initialize() -> void:
	create_timer(110.0).timeout.connect(func():
		printerr("TIMEOUT: capture exceeded 110s")
		quit(1))
	call_deferred("_run")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _grab() -> Image:
	await _frames(5)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _run() -> void:
	print("Starting capture for maintenance_bay v2...")
	var env_out := OS.get_environment("TLF_OUT")
	if not env_out.is_empty():
		_out = env_out

	DirAccess.make_dir_recursive_absolute(_out)

	_ch01 = (load("res://scenes/chapters/ch01/Chapter01.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(_ch01)
	await _frames(30)

	_router = _ch01.get_node("RoomRouter") as RoomRouter
	_player = _ch01.get_node("Player") as Player
	_player.set_physics_process(false)

	var diag := _ch01.call("get_dialogue_box") as DialogueBox
	if diag != null and diag.is_active:
		diag.finish_sequence()

	_router.enter_room(ROOM, &"door_entry_west")
	await _frames(20)

	for entry in SHOTS:
		var shot_name: String = entry[0]
		var pos: Vector2 = entry[1]
		var anim: String = entry[2]

		_player.global_position = pos
		if _player.sprite != null:
			_player.sprite.play(anim)
			_player.sprite.pause()
			_player.sprite.frame = 0

		_router.camera.snap_now()
		var img := await _grab()
		var file_path := _out.path_join(shot_name + ".png")
		img.save_png(file_path)
		print("SAVED %s (%dx%d) at %s" % [file_path, img.get_width(), img.get_height(), pos])

	print("ALL CAPTURES COMPLETED")
	quit(0)
