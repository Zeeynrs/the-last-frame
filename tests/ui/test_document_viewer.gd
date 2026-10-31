extends "res://tests/support/base_test.gd"

## Automated unit tests for DocumentViewer per TLF-032.
## Verifies document opening, paging convention (_BODY_2), SimClock pausing/resuming,
## player input suspension, and Beat 09 journal triggers.


func test_document_viewer_single_page_and_simclock_pause() -> void:
	var sess_scene = load("res://scenes/session/GameSession.tscn")
	var session = sess_scene.instantiate() as GameSession
	scene_tree.root.add_child(session)

	var doc_viewer_scene = load("res://scenes/ui/DocumentViewer.tscn")
	var viewer = doc_viewer_scene.instantiate() as DocumentViewer
	scene_tree.root.add_child(viewer)

	var player = CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group(&"player")
	scene_tree.root.add_child(player)
	player.set_physics_process(true)

	var doc = load("res://data/documents/ch01/doc_evac_notice.tres") as DocumentDef
	_assert_true(doc != null, "doc_evac_notice loads")

	_assert_false(session.sim_clock.is_paused, "SimClock starts unpaused")
	_assert_true(player.is_physics_processing(), "Player starts physics processing")

	viewer.open_document(doc)

	_assert_true(viewer.is_open, "viewer is open")
	_assert_true(viewer.visible, "viewer is visible")
	_assert_true(session.sim_clock.is_paused, "SimClock paused while document is open")
	_assert_false(player.is_physics_processing(), "Player physics paused while document is open")
	_assert_eq(viewer.pages.size(), 1, "doc_evac_notice has 1 page")
	_assert_eq(viewer.title_label.text, "TRANSIT BULLETIN 23:54", "title matches")
	_assert_true(viewer.body_label.text.contains("Emergency evacuation of Elysium-09."), "body matches")

	# Close
	viewer.close_document()

	_assert_false(viewer.is_open, "viewer closed")
	_assert_false(session.sim_clock.is_paused, "SimClock resumed after closing document")
	_assert_true(player.is_physics_processing(), "Player physics resumed after closing document")

	player.free()
	viewer.free()
	session.free()


func test_document_viewer_multipage_paging_and_beat09_journal() -> void:
	var sess_scene = load("res://scenes/session/GameSession.tscn")
	var session = sess_scene.instantiate() as GameSession
	scene_tree.root.add_child(session)

	var doc_viewer_scene = load("res://scenes/ui/DocumentViewer.tscn")
	var viewer = doc_viewer_scene.instantiate() as DocumentViewer
	scene_tree.root.add_child(viewer)

	var doc = load("res://data/documents/ch01/dispatch_terminal.tres") as DocumentDef
	_assert_true(doc != null, "dispatch_terminal loads")

	viewer.open_document(doc)

	_assert_eq(viewer.pages.size(), 2, "dispatch_terminal has 2 pages detected via _BODY_2 convention")
	_assert_eq(viewer.current_page_index, 0, "starts at page 1 (index 0)")
	_assert_true(viewer.body_label.text.contains("BIOMETRIC MATCH - ACCESS GRANTED"), "page 1 body matches")

	# Check journal before page 2
	var has_repeats_before = false
	for entry in session.narrative_state.get_journal():
		if entry.get("key") == "JRN_CH1_REPEATS":
			has_repeats_before = true
	_assert_false(has_repeats_before, "JRN_CH1_REPEATS not added before viewing page 2")

	# Next page
	viewer.next_page()
	_assert_eq(viewer.current_page_index, 1, "navigated to page 2 (index 1)")
	_assert_true(viewer.body_label.text.contains("DIAGNOSTIC LOG"), "page 2 body matches")

	# Check journal after viewing page 2
	var has_repeats_after = false
	var repeats_category = ""
	for entry in session.narrative_state.get_journal():
		if entry.get("key") == "JRN_CH1_REPEATS":
			has_repeats_after = true
			repeats_category = entry.get("category", "")
	_assert_true(has_repeats_after, "JRN_CH1_REPEATS added upon viewing page 2")
	_assert_eq(repeats_category, "theory", "JRN_CH1_REPEATS has category 'theory'")

	# Prev page
	viewer.prev_page()
	_assert_eq(viewer.current_page_index, 0, "navigated back to page 1")

	viewer.close_document()
	viewer.free()
	session.free()
