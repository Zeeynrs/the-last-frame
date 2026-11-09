extends "res://tests/support/base_test.gd"

## TLF-072 (ADR-023 addendum 3): the UI at the 960 x 540 canvas. Every panel keeps its pixel size
## (no UI scale) and sits where it sat on the 640 x 360 screen relative to the screen edges and
## centre: nothing is left at a 640 x 360 position.

const VIEW := Rect2(0, 0, 960, 540)


func _add(path: String) -> Node:
	var node := (load(path) as PackedScene).instantiate()
	_tree().root.add_child(node)
	return node


func test_root_view_is_960_x_540() -> void:
	_assert_eq(_tree().root.get_visible_rect(), VIEW, "the root viewport shows the 960 x 540 canvas")


func test_dialogue_box_sits_at_the_bottom_centre() -> void:
	var diag := _add("res://scenes/ui/DialogueBox.tscn") as DialogueBox
	diag.play_sequence(&"tlf072_layout", [["SPK_ELIAS", "EL_B01_01"]], false)
	await physics_frames(2)
	var rect := (diag.get_node("Panel") as Control).get_global_rect()
	# 600 x 92 as before; 12 px above the bottom edge, centred (was (20, 256) on the 640 x 360 screen).
	_assert_eq(rect, Rect2(180, 436, 600, 92), "dialogue panel at the bottom centre")
	_assert_true(VIEW.encloses(rect), "dialogue panel inside the view")
	diag.free()


func test_chapter_complete_text_is_centred() -> void:
	var overlay := _add("res://scenes/ui/chapter_complete_overlay.tscn")
	await physics_frames(2)
	var rect := (overlay.get_node("VBox") as Control).get_global_rect()
	_assert_eq(rect.get_center().x, 480.0, "overlay text block centred horizontally")
	_assert_eq(rect.size.x, 600.0, "overlay text block keeps its 600 px width")
	_assert_true(VIEW.encloses(rect), "overlay text block inside the view")
	overlay.free()


func test_centred_panels_are_centred() -> void:
	var doc := _add("res://scenes/ui/DocumentViewer.tscn")
	var wheel := _add("res://scenes/ui/ability_wheel.tscn")
	var journal := _add("res://scenes/ui/JournalScreen.tscn")
	await physics_frames(2)
	for pair in [[doc, "Panel"], [wheel, "WheelContainer"], [journal, "Panel"]]:
		var rect := (pair[0].get_node(pair[1]) as Control).get_global_rect()
		_assert_eq(rect.get_center(), Vector2(480, 270), "%s/%s centred in the view" % [pair[0].name, pair[1]])
	# Mouse aiming measures from the wheel's real centre, not the old (320, 180).
	_assert_eq(wheel.call("_wheel_center"), Vector2(480, 270), "ability wheel mouse centre")
	doc.free()
	wheel.free()
	journal.free()


func test_hud_feedback_and_title_follow_the_edges() -> void:
	var hud := _add("res://scenes/ui/HUD.tscn")
	await physics_frames(2)
	var fb := (hud.get_node("FeedbackPanel") as Control).get_global_rect()
	_assert_eq(fb.get_center().x, 480.0, "feedback panel centred horizontally")
	_assert_eq(fb.end.y, 540.0 - 28.0, "feedback panel 28 px above the bottom edge")
	var ability := (hud.get_node("AbilityPanel") as Control).get_global_rect()
	_assert_eq(ability.position, Vector2(12, 12), "ability panel in the top-left corner")
	hud.free()
	var title := _add("res://scenes/ui/title_screen.tscn")
	await physics_frames(2)
	_assert_eq((title.get_node("Menu") as Control).get_global_rect().get_center().x, 480.0, "title menu centred")
	_assert_eq((title.get_node("Title") as Control).get_global_rect().size.x, 960.0, "title label spans the view")
	title.free()
