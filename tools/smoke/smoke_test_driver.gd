extends SceneTree
## Automated smoke test driver for exported builds.
##
## Usage:
##   .\build\windows\TheLastFrame.exe -s res://tools/smoke/smoke_test_driver.gd
##
## This driver executes the 5-step smoke test against the live game window:
##   1. Title screen rendering, pixel font, and translated menu text
##   2. New Game transition and Chapter 1 arrival platform rendering
##   3. Checkpoint save creation and persistence to slot 0
##   4. Return to title screen, Continue option enablement, and save reload
##   5. Clean exit

var _stage: int = 0
var _frame: int = 0
var _title_scene: Control = null
var _ch01: Node = null
var _user_data_dir: String = ""
var _out_dir: String = ""

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(640, 360))
	_user_data_dir = OS.get_user_data_dir()
	_out_dir = OS.get_executable_path().get_base_dir()

	# Check for optional --out-dir argument
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out-dir="):
			_out_dir = arg.substr("--out-dir=".length())

	print("SMOKE_USER_DATA_DIR: %s" % _user_data_dir)
	print("SMOKE_OUT_DIR: %s" % _out_dir)

	# Safety check: Never run against real player save directory
	if _user_data_dir.ends_with("The Last Frame"):
		printerr("ERROR: Safety violation: user data dir must NOT be 'The Last Frame'!")
		quit(1)
		return

	change_scene_to_file("res://scenes/ui/title_screen.tscn")

func _process(_delta: float) -> bool:
	_frame += 1

	match _stage:
		0:
			_title_scene = root.find_child("TitleScreen", true, false) as Control
			if _title_scene != null and _frame >= 25:
				var title_lbl: Label = _title_scene.get_node_or_null("Title") as Label
				var new_game_lbl: Label = _title_scene.get_node_or_null("Menu/NewGame") as Label
				var continue_lbl: Label = _title_scene.get_node_or_null("Menu/Continue") as Label
				var quit_lbl: Label = _title_scene.get_node_or_null("Menu/Quit") as Label

				print("SMOKE_CHECK_1_TITLE_TEXT: %s" % (title_lbl.text if title_lbl else "null"))
				print("SMOKE_CHECK_1_NEW_GAME_TEXT: %s" % (new_game_lbl.text if new_game_lbl else "null"))
				print("SMOKE_CHECK_1_CONTINUE_TEXT: %s" % (continue_lbl.text if continue_lbl else "null"))
				print("SMOKE_CHECK_1_QUIT_TEXT: %s" % (quit_lbl.text if quit_lbl else "null"))

				if title_lbl == null or title_lbl.text == "UI_TITLE_GAME" or title_lbl.text.is_empty():
					printerr("ERROR: Title text not translated!")
					quit(1)
					return true

				_save_screenshot("smoke_01_title_screen.png")
				print("SMOKE_STEP_2_STARTING_NEW_GAME")
				_title_scene.activate()
				_stage = 1
				_frame = 0

		1:
			_ch01 = root.find_child("Chapter01", true, false)
			if _ch01 != null and _frame >= 30:
				var player = root.find_child("Player", true, false)
				print("SMOKE_CHECK_2_CH01_LOADED: player=%s" % str(player != null))
				_save_screenshot("smoke_02_chapter1_loaded.png")

				print("SMOKE_STEP_3_WRITING_SAVE")
				var router = _ch01.get_node_or_null("RoomRouter")
				if router != null and router.has_method("save_checkpoint"):
					var err = router.save_checkpoint(&"ch01.arrival_platform")
					print("SMOKE_CHECK_3_SAVE_CHECKPOINT_RESULT: %d" % err)
				elif router != null and router.save_service != null:
					var data = router.capture_save("ch01.arrival_platform")
					var err = router.save_service.write_slot(0, data)
					print("SMOKE_CHECK_3_WRITE_SLOT_RESULT: %d" % err)

				var save_svc = root.get_node_or_null("SaveService")
				if save_svc != null:
					print("SMOKE_CHECK_3_SAVE_WRITTEN: has_slot_0=%s" % str(save_svc.has_slot(0)))

				_stage = 2
				_frame = 0

		2:
			if _frame >= 20:
				print("SMOKE_STEP_4_RETURN_TO_TITLE")
				var router = root.get_node_or_null("SceneRouter")
				if router != null:
					router.return_to_title()
				_stage = 3
				_frame = 0

		3:
			_title_scene = root.find_child("TitleScreen", true, false) as Control
			if _title_scene != null and _frame >= 25:
				_title_scene.refresh()
				var cont_enabled: bool = _title_scene.continue_enabled
				var selected_item = _title_scene.selected_item()
				print("SMOKE_CHECK_4_CONTINUE_ENABLED: %s (selected=%s)" % [str(cont_enabled), str(selected_item)])
				_save_screenshot("smoke_03_title_continue_enabled.png")

				if not cont_enabled:
					printerr("ERROR: Continue was not enabled after save!")
					quit(1)
					return true

				print("SMOKE_STEP_4_ACTIVATE_CONTINUE")
				_title_scene.activate()
				_stage = 4
				_frame = 0

		4:
			_ch01 = root.find_child("Chapter01", true, false)
			if _ch01 != null and _frame >= 30:
				print("SMOKE_CHECK_4_CH01_RESTORED")
				_save_screenshot("smoke_04_chapter1_restored.png")

				print("SMOKE_STEP_5_QUIT")
				print("SMOKE_TEST_COMPLETED_SUCCESSFULLY")
				quit(0)
				return true

	return false

func _save_screenshot(filename: String) -> void:
	var img: Image = root.get_texture().get_image()
	if img != null and not img.is_empty():
		var full_path: String = _out_dir.path_join(filename)
		var err = img.save_png(full_path)
		print("Saved screenshot to %s (err=%d, size=%s)" % [full_path, err, str(img.get_size())])
	else:
		printerr("Failed to grab image for %s" % filename)
