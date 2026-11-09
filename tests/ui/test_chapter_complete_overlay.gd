extends "res://tests/support/base_test.gd"

## Automated unit tests for ChapterCompleteOverlay layout per TLF-051.
## Verifies:
## 1. Overlay labels stay inside the 960x540 view minus 12 px safe margins (ART_BIBLE §8).
## 2. Font sizes are strictly in {8, 16, 24} (and {16, 32, 48} at text_scale=2.0).
## 3. No overlay element overlaps the SceneRouter return-to-title hint (y=500..520).
## 4. Backwards compatibility: hidden TitleLabel contains both complete & title text.
## 5. Overlay functions cleanly with and without playtest telemetry summary.

const OVERLAY_SCENE_PATH := "res://scenes/ui/chapter_complete_overlay.tscn"
## The 960 x 540 view (ADR-023 addendum 3) minus 12 px on every side.
const SAFE_RECT := Rect2(12.0, 12.0, 936.0, 516.0)
## SceneRouter's hint label: centre-bottom anchors, offsets x -200..200, y -40..-20.
const HINT_RECT := Rect2(280.0, 500.0, 400.0, 20.0)


func _collect_visible_labels(node: Node, out: Array[Label]) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is Label:
		out.append(node as Label)
	for child in node.get_children():
		_collect_visible_labels(child, out)


func _get_label_effective_font_size(label: Label) -> int:
	var sz := label.get_theme_font_size(&"font_size")
	if sz > 0:
		return sz
	var theme = label.get_theme()
	if theme != null:
		return theme.default_font_size
	return 8


func _make_sample_summary() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("Total active time: 5:30 (paused: 0:12)")
	lines.append("PZ-001: 0:45   PZ-002: 1:50   PZ-003: 2:55")
	lines.append("PZ-004: not solved   PZ-005: not solved")
	lines.append("Log: user://playtest/ch01_test_sample.json")
	return lines


func test_overlay_layout_and_safe_margins() -> void:
	UITheme.ensure_initialized()
	var settings = _tree().root.get_node_or_null("Settings")
	if settings != null:
		settings.text_scale = 1.0

	var packed := load(OVERLAY_SCENE_PATH) as PackedScene
	_assert_true(packed != null, "Overlay scene loads")
	var overlay = packed.instantiate()
	_assert_true(overlay != null, "Overlay scene instantiates")

	overlay.setup(_make_sample_summary())
	_tree().root.add_child(overlay)
	await physics_frames(3)

	var labels: Array[Label] = []
	_collect_visible_labels(overlay, labels)
	_assert_true(labels.size() >= 3, "At least Title, ChapterName and PlaytestSummary visible")

	var allowed_sizes := [8, 16, 24]
	for lbl in labels:
		var rect := lbl.get_global_rect()
		_assert_true(rect.position.x >= SAFE_RECT.position.x, "Label '%s' x (%.1f) >= safe left (12)" % [lbl.name, rect.position.x])
		_assert_true(rect.position.y >= SAFE_RECT.position.y, "Label '%s' y (%.1f) >= safe top (12)" % [lbl.name, rect.position.y])
		_assert_true(rect.end.x <= SAFE_RECT.end.x, "Label '%s' end x (%.1f) <= safe right (948)" % [lbl.name, rect.end.x])
		_assert_true(rect.end.y <= SAFE_RECT.end.y, "Label '%s' end y (%.1f) <= safe bottom (528)" % [lbl.name, rect.end.y])

		var font_sz := _get_label_effective_font_size(lbl)
		_assert_true(font_sz in allowed_sizes, "Label '%s' font size %d in [8, 16, 24]" % [lbl.name, font_sz])

		_assert_false(rect.intersects(HINT_RECT), "Label '%s' does not overlap SceneRouter hint rect" % lbl.name)

	# Check panel does not overlap hint
	var panel := overlay.find_child("SummaryPanel", true, false) as PanelContainer
	if _assert_true(panel != null, "SummaryPanel exists with summary"):
		var p_rect := panel.get_global_rect()
		_assert_false(p_rect.intersects(HINT_RECT), "SummaryPanel does not overlap SceneRouter hint")
		_assert_true(p_rect.end.y <= HINT_RECT.position.y, "SummaryPanel ends before SceneRouter hint y (500)")

	overlay.free()


func test_overlay_text_scale_2() -> void:
	UITheme.ensure_initialized()
	var settings = _tree().root.get_node_or_null("Settings")
	if settings != null:
		settings.text_scale = 2.0

	var packed := load(OVERLAY_SCENE_PATH) as PackedScene
	var overlay = packed.instantiate()
	overlay.setup(_make_sample_summary())
	_tree().root.add_child(overlay)
	await physics_frames(3)

	var labels: Array[Label] = []
	_collect_visible_labels(overlay, labels)
	var allowed_sizes_2x := [16, 32, 48]

	for lbl in labels:
		var rect := lbl.get_global_rect()
		_assert_true(rect.position.x >= SAFE_RECT.position.x, "2x: Label '%s' x (%.1f) >= safe left" % [lbl.name, rect.position.x])
		_assert_true(rect.position.y >= SAFE_RECT.position.y, "2x: Label '%s' y (%.1f) >= safe top" % [lbl.name, rect.position.y])
		_assert_true(rect.end.x <= SAFE_RECT.end.x, "2x: Label '%s' end x (%.1f) <= safe right" % [lbl.name, rect.end.x])
		_assert_true(rect.end.y <= SAFE_RECT.end.y, "2x: Label '%s' end y (%.1f) <= safe bottom" % [lbl.name, rect.end.y])

		var font_sz := _get_label_effective_font_size(lbl)
		_assert_true(font_sz in allowed_sizes_2x, "2x: Label '%s' font size %d in [16, 32, 48]" % [lbl.name, font_sz])

		_assert_false(rect.intersects(HINT_RECT), "2x: Label '%s' does not overlap SceneRouter hint" % lbl.name)

	var panel := overlay.find_child("SummaryPanel", true, false) as PanelContainer
	if panel != null:
		var p_rect := panel.get_global_rect()
		_assert_false(p_rect.intersects(HINT_RECT), "2x: SummaryPanel does not overlap SceneRouter hint")

	overlay.free()

	if settings != null:
		settings.text_scale = 1.0
		settings.reset_to_defaults()
	await physics_frames(1)


func test_overlay_without_summary() -> void:
	UITheme.ensure_initialized()
	var packed := load(OVERLAY_SCENE_PATH) as PackedScene
	var overlay = packed.instantiate()
	overlay.setup(PackedStringArray())
	_tree().root.add_child(overlay)
	await physics_frames(2)

	_assert_true(overlay.find_child("PlaytestSummary", true, false) == null, "No PlaytestSummary node when summary is empty")
	_assert_true(overlay.find_child("SummaryPanel", true, false) == null, "No SummaryPanel node when summary is empty")

	var title_lbl := overlay.find_child("Title", true, false) as Label
	var ch_lbl := overlay.find_child("ChapterName", true, false) as Label
	_assert_true(title_lbl != null and title_lbl.visible, "Title visible without summary")
	_assert_true(ch_lbl != null and ch_lbl.visible, "ChapterName visible without summary")

	var t_rect := title_lbl.get_global_rect()
	var c_rect := ch_lbl.get_global_rect()
	_assert_false(t_rect.intersects(HINT_RECT), "Title does not overlap hint")
	_assert_false(c_rect.intersects(HINT_RECT), "ChapterName does not overlap hint")

	overlay.free()


func test_overlay_compat_title_label() -> void:
	var packed := load(OVERLAY_SCENE_PATH) as PackedScene
	var overlay = packed.instantiate()
	overlay.setup(PackedStringArray())
	_tree().root.add_child(overlay)
	await physics_frames(1)

	var compat_lbl := overlay.find_child("TitleLabel", true, false) as Label
	_assert_true(compat_lbl != null, "TitleLabel exists for backwards compatibility")
	_assert_false(compat_lbl.visible, "TitleLabel is hidden")
	_assert_true(compat_lbl.text.contains(tr("UI_CHAPTER_COMPLETE")), "TitleLabel contains UI_CHAPTER_COMPLETE")
	_assert_true(compat_lbl.text.contains(tr("UI_CHAPTER_01_TITLE")), "TitleLabel contains UI_CHAPTER_01_TITLE")

	overlay.free()
