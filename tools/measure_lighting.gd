extends SceneTree

## TLF-083 / ADR-026: what the lighting pass costs on THIS machine (the owner's A/B gate).
##   godot --path . -s tools/measure_lighting.gd
## Safe to run in any copy: it does not start a chapter and writes no save, settings or log.
## It draws a full 960 x 540 backdrop, puts the pass on it with the worst case (8 room lights plus
## the Elias zone, an information quad among them), and measures the viewport GPU time with the pass
## hidden and visible. ADR-026: above 1 ms per frame, replace the shader's 32-colour search by a
## 32^3 index LUT.

const FRAMES := 300
const BUDGET_MS := 1.0
const BACKDROP := "res://assets/environments/ch01/ch01_env_arrival_platform_target_sheet.png"


func _initialize() -> void:
	var timer := create_timer(100.0)
	timer.timeout.connect(func():
		printerr("TIMEOUT: measure_lighting exceeded 100 s")
		quit(1))
	call_deferred("_run")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _measure() -> Array:
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	await _frames(20)
	var samples: Array[float] = []
	for i in FRAMES:
		await process_frame
		samples.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
	samples.sort()
	var total := 0.0
	for s in samples:
		total += s
	return [total / samples.size(), samples[int(samples.size() * 0.95)]]


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Run this windowed (no --headless): it measures the GPU.")
		quit(2)
		return
	var room := Node2D.new()
	room.name = "MeasureRoom"
	root.add_child(room)
	var backdrop := TextureRect.new()
	backdrop.texture = load(BACKDROP)
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.size = Vector2(960, 540)
	room.add_child(backdrop)
	for i in 7:
		var l := RoomLight.new()
		l.name = "Light%d" % i
		l.position = Vector2(80 + i * 130, 200 + (i % 3) * 90)
		l.radius = Vector2(96, 48)
		room.add_child(l)
	var board := RoomLight.new()
	board.name = "BoardInfo"
	board.shape = RoomLight.Shape.QUAD
	board.quad = PackedVector2Array([Vector2(64, 148), Vector2(223, 71), Vector2(223, 100), Vector2(64, 177)])
	board.only_indices = PackedInt32Array([24])
	room.add_child(board)
	var elias := Node2D.new()
	elias.position = Vector2(480, 300)
	room.add_child(elias)
	var pass_node := LightingPass.new()
	root.add_child(pass_node)
	pass_node.apply_room(room, RoomLighting.new(), elias)
	pass_node.visible = false
	var off: Array = await _measure()
	pass_node.visible = true
	var on: Array = await _measure()
	var delta: float = on[0] - off[0]
	print("GPU:     %s" % RenderingServer.get_video_adapter_name())
	print("Window:  %s, viewport %s" % [DisplayServer.window_get_size(), root.get_visible_rect().size])
	print("Lights:  %d room lights + Elias zone" % pass_node.lights.size())
	print("Without the pass: %.3f ms average, %.3f ms p95 (%d frames)" % [off[0], off[1], FRAMES])
	print("With the pass:    %.3f ms average, %.3f ms p95" % [on[0], on[1]])
	print("PASS COST: %.3f ms per frame -> %s (budget %.1f ms, ADR-026)" % [delta, "OK" if delta <= BUDGET_MS else "OVER BUDGET: use the 32^3 LUT", BUDGET_MS])
	quit(0)
