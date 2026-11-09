extends SceneTree
## TLF-072: how the 960x540 canvas lands in a window smaller than 1920x1080. Run in a renamed scratch
## copy: godot --path . --resolution 1280x720 -s tools/capture_tlf072_window.gd
## Prints the stretch numbers and saves the whole window (borders included) as shot_12.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var title: Node = (load("res://scenes/ui/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var win := DisplayServer.window_get_size()
	print("WINDOW size %s  content_scale_mode %d  aspect %d  stretch %d  content_scale_size %s" % [win, root.content_scale_mode, root.content_scale_aspect, root.content_scale_stretch, root.content_scale_size])
	print("VISIBLE rect %s  final transform %s" % [root.get_visible_rect(), root.get_final_transform()])
	var pos := DisplayServer.window_get_position()
	var screen := DisplayServer.window_get_current_screen()
	var img := DisplayServer.screen_get_image(screen)
	if img != null:
		var origin := pos - DisplayServer.screen_get_position(screen)
		var shot := img.get_region(Rect2i(origin, win))
		shot.save_png(ProjectSettings.globalize_path("res://docs/handoffs/TLF-072/shot_12_window_1280x720.png"))
		print("CAPTURED window %s at %s" % [shot.get_size(), origin])
	quit(0)
