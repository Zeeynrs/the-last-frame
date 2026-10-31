extends "res://tests/support/base_test.gd"

## TLF-040 acceptance tests:
## 1. Font scan: TLF Pixel Mono everywhere and sizes in {8, 16, 24} (and {16, 32, 48} at text_scale=2.0 live).
## 2. Static scan: No theme_override_font_sizes outside {8, 16, 24} in scenes/**/*.tscn (excl. scenes/test/).
## 3. Dynamic input glyphs: First key wins, confirm -> [Enter], follows Settings remap, joypad mode.
## 4. Clipping check: Longest dialogue line and document page fit in their panels at 8 px and 16 px.

const TEST_SAVE_ROOT := "user://tlf_test_theme_saves"
const UI_SCENES: Array[String] = [
	"res://scenes/ui/title_screen.tscn",
	"res://scenes/ui/DialogueBox.tscn",
	"res://scenes/ui/DocumentViewer.tscn",
	"res://scenes/ui/HUD.tscn",
	"res://scenes/ui/JournalScreen.tscn",
]
const CHAPTER01_SCENE := "res://scenes/chapters/ch01/Chapter01.tscn"

var _store: SaveStore = null
var _original_root: String = ""


func _init() -> void:
	timeout_frames = 1200


func _begin() -> void:
	UITheme.ensure_initialized()
	_store = _tree().root.get_node_or_null("SaveService") as SaveStore
	if _store != null:
		_original_root = _store.save_root
		_store.save_root = TEST_SAVE_ROOT
	_remove_test_root()


func _end() -> void:
	release_all_input()
	_tree().unload_current_scene()
	await physics_frames(2)
	var settings = _tree().root.get_node_or_null("Settings")
	if settings != null:
		settings.text_scale = 1.0
		settings.reset_to_defaults()
	InputPrompts.set_joypad_mode(false)
	if _store != null:
		_store.save_root = _original_root
	_remove_test_root()
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root removed")


func _remove_test_root() -> void:
	var dir := DirAccess.open(TEST_SAVE_ROOT)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	if DirAccess.dir_exists_absolute(TEST_SAVE_ROOT):
		DirAccess.remove_absolute(TEST_SAVE_ROOT)


func _collect_text_controls(node: Node, result: Array[Control]) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is Label or node is RichTextLabel or node is Button:
		result.append(node as Control)
	for child in node.get_children():
		_collect_text_controls(child, result)


func _get_control_font(node: Control) -> Font:
	if node is RichTextLabel:
		var rf = node.get_theme_font(&"normal_font")
		if rf != null:
			return rf
	return node.get_theme_font(&"font")


func _get_control_font_size(node: Control) -> int:
	if node is RichTextLabel:
		var rsz = node.get_theme_font_size(&"normal_font_size")
		if rsz > 0:
			return rsz
	return node.get_theme_font_size(&"font_size")


func test_action_glyph_first_key_and_confirm() -> void:
	InputPrompts.set_joypad_mode(false)
	var confirm_glyph = InputPrompts.get_action_glyph(&"confirm")
	_assert_eq(confirm_glyph, "[Enter]", "confirm action glyph should be [Enter]")

	var interact_glyph = InputPrompts.get_action_glyph(&"interact")
	_assert_eq(interact_glyph, "[E]", "interact action glyph should be [E]")

	var settings = _tree().root.get_node_or_null("Settings")
	if settings != null:
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_F
		settings.remap_action(&"interact", &"keyboard", ev)
		var remapped_glyph = InputPrompts.get_action_glyph(&"interact")
		_assert_eq(remapped_glyph, "[F]", "interact action glyph follows settings remapping")
		settings.reset_to_defaults()

	InputPrompts.set_joypad_mode(true)
	var joy_confirm = InputPrompts.get_action_glyph(&"confirm")
	_assert_eq(joy_confirm, "[A]", "joypad confirm action glyph should be [A]")
	InputPrompts.set_joypad_mode(false)


func test_static_scene_font_size_overrides() -> void:
	var disallowed_found: Array[String] = []
	var scenes_to_check: Array[String] = []

	var dir_queue: Array[String] = ["res://scenes"]
	while not dir_queue.is_empty():
		var current_dir = dir_queue.pop_front()
		var dir = DirAccess.open(current_dir)
		if dir == null:
			continue
		for file in dir.get_files():
			if file.ends_with(".tscn") and not current_dir.begins_with("res://scenes/test"):
				scenes_to_check.append(current_dir + "/" + file)
		for sub in dir.get_directories():
			if sub != "." and sub != "..":
				dir_queue.append(current_dir + "/" + sub)

	var allowed_sizes := [8, 16, 24]
	for sc_path in scenes_to_check:
		var file = FileAccess.open(sc_path, FileAccess.READ)
		if file == null:
			continue
		var line_no := 0
		while not file.eof_reached():
			line_no += 1
			var line = file.get_line()
			if "theme_override_font_sizes/font_size" in line:
				var parts = line.split("=")
				if parts.size() == 2:
					var sz = parts[1].strip_edges().to_int()
					if not (sz in allowed_sizes):
						disallowed_found.append("%s:%d (font_size=%d)" % [sc_path, line_no, sz])

	_assert_eq(disallowed_found.size(), 0, "No disallowed font size overrides found: %s" % str(disallowed_found))


func test_font_scan_ui_and_chapter01() -> void:
	var settings = _tree().root.get_node_or_null("Settings")
	if settings != null:
		settings.text_scale = 1.0

	var scenes := UI_SCENES.duplicate()
	scenes.append(CHAPTER01_SCENE)

	for sc_path in scenes:
		var packed = load(sc_path) as PackedScene
		_assert_true(packed != null, "Scene must load: " + sc_path)
		var instance = packed.instantiate()
		_assert_true(instance != null, "Scene must instantiate: " + sc_path)
		_tree().root.add_child(instance)
		if instance is CanvasItem:
			(instance as CanvasItem).visible = true
		elif instance is CanvasLayer:
			(instance as CanvasLayer).visible = true
		await physics_frames(1)

		# Make sure panels in UI scenes are visible for scanning
		var panel = instance.get_node_or_null("Panel")
		if panel is CanvasItem:
			(panel as CanvasItem).visible = true
		var echo_panel = instance.get_node_or_null("EchoPanel")
		if echo_panel is CanvasItem:
			(echo_panel as CanvasItem).visible = true
		var fb_panel = instance.get_node_or_null("FeedbackPanel")
		if fb_panel is CanvasItem:
			(fb_panel as CanvasItem).visible = true

		var controls: Array[Control] = []
		_collect_text_controls(instance, controls)
		_assert_true(controls.size() > 0, "Scene %s should have text controls" % sc_path)

		for ctrl in controls:
			var font = _get_control_font(ctrl)
			_assert_true(font != null, "Control %s in %s must have a theme font" % [ctrl.name, sc_path])
			if font != null:
				var f_path = font.resource_path
				_assert_true(f_path.ends_with("tlf_pixel_mono.ttf"), "Control %s in %s font (%s) must be tlf_pixel_mono.ttf" % [ctrl.name, sc_path, f_path])
			var sz = _get_control_font_size(ctrl)
			_assert_true(sz in [8, 16, 24], "Control %s in %s font_size (%d) must be in [8, 16, 24]" % [ctrl.name, sc_path, sz])

		# Test live text scale multiplier
		if settings != null:
			settings.text_scale = 2.0
			await physics_frames(1)
			for ctrl in controls:
				var sz2 = _get_control_font_size(ctrl)
				_assert_true(sz2 in [16, 32, 48], "Control %s in %s scaled font_size (%d) must be in [16, 32, 48]" % [ctrl.name, sc_path, sz2])
			settings.text_scale = 1.0
			await physics_frames(1)

		instance.queue_free()
		await physics_frames(1)


func test_panel_clipping_dialogue_and_documents() -> void:
	# Test DialogueBox with longest Ch1 line
	var diag_packed = load("res://scenes/ui/DialogueBox.tscn") as PackedScene
	var diag = diag_packed.instantiate()
	_tree().root.add_child(diag)
	diag.visible = true
	var panel = diag.get_node("Panel") as PanelContainer
	panel.visible = true
	await physics_frames(2)
	var text_label = diag.get_node("Panel/Margin/VBox/TextLabel") as Label

	# Longest Chapter 1 dialogue line
	var longest_line := "You are listening to an automated dispatch broadcast on loop. If this channel is active, the terminal has been evacuated under Protocol 7."
	text_label.text = longest_line

	# Check at 8 px
	await physics_frames(2)
	var line_count_8 = text_label.get_line_count()
	var line_height_8 = text_label.get_line_height()
	var total_text_h_8 = line_count_8 * line_height_8
	_assert_true(total_text_h_8 <= panel.size.y, "Dialogue text at 8px (h=%d) fits panel (h=%d)" % [total_text_h_8, panel.size.y])

	# Check at 16 px (text_scale = 2.0)
	var settings = _tree().root.get_node_or_null("Settings")
	if settings != null:
		settings.text_scale = 2.0
		await physics_frames(2)
		var line_count_16 = text_label.get_line_count()
		var line_height_16 = text_label.get_line_height()
		var total_text_h_16 = line_count_16 * line_height_16
		_assert_true(total_text_h_16 <= panel.size.y, "Dialogue text at 16px (h=%d) fits panel (h=%d)" % [total_text_h_16, panel.size.y])
		settings.text_scale = 1.0

	diag.queue_free()
	await physics_frames(1)

	# Test DocumentViewer with longest document page
	var doc_packed = load("res://scenes/ui/DocumentViewer.tscn") as PackedScene
	var doc = doc_packed.instantiate()
	_tree().root.add_child(doc)
	doc.visible = true
	var doc_panel = doc.get_node("Panel") as PanelContainer
	doc_panel.visible = true
	await physics_frames(2)
	var body_label = doc.get_node("Panel/Margin/VBox/BodyLabel") as Label
	var longest_doc := "BIOMETRIC MATCH - ACCESS GRANTED\nEVENT: CONTAINMENT PROTOCOL\nSTATUS: EXECUTED 23:59:00\nAUTHORIZATION: LEVEL-0\nUSER: ELIAS\nLOCATION: THIS TERMINAL"
	body_label.text = longest_doc
	await physics_frames(2)
	var doc_lines_8 = body_label.get_line_count()
	var doc_line_h_8 = body_label.get_line_height()
	var doc_total_h_8 = doc_lines_8 * doc_line_h_8
	_assert_true(doc_total_h_8 <= doc_panel.size.y, "Document text at 8px (h=%d) fits panel (h=%d)" % [doc_total_h_8, doc_panel.size.y])

	if settings != null:
		settings.text_scale = 2.0
		await physics_frames(2)
		var doc_lines_16 = body_label.get_line_count()
		var doc_line_h_16 = body_label.get_line_height()
		var doc_total_h_16 = doc_lines_16 * doc_line_h_16
		_assert_true(doc_total_h_16 <= doc_panel.size.y, "Document text at 16px (h=%d) fits panel (h=%d)" % [doc_total_h_16, doc_panel.size.y])
		settings.text_scale = 1.0

	doc.queue_free()
	await physics_frames(1)
