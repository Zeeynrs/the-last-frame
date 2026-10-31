extends "res://tests/support/base_test.gd"

## Automated unit tests for JournalScreen per TLF-032.
## Verifies journal entries grouped by category (observation/fact/theory),
## memory fragment titles and bodies, SimClock pausing, and player input blocking.


func test_journal_screen_grouping_by_category() -> void:
	var sess_scene = load("res://scenes/session/GameSession.tscn")
	var session = sess_scene.instantiate() as GameSession
	scene_tree.root.add_child(session)

	var jrn_scene = load("res://scenes/ui/JournalScreen.tscn")
	var screen = jrn_scene.instantiate() as JournalScreen
	scene_tree.root.add_child(screen)

	var player = CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group(&"player")
	scene_tree.root.add_child(player)

	# Populate entries across all 3 categories
	session.narrative_state.add_journal_entry("JRN_CH1_OPERATOR", "observation")
	session.narrative_state.add_journal_entry("JRN_CH1_EVAC_2354", "fact")
	session.narrative_state.add_journal_entry("JRN_CH1_OPERATOR_WARNING", "theory")

	# Add fragment
	session.narrative_state.collect_fragment(&"ch01.fragment.mira_departure")

	_assert_false(screen.is_open, "initially closed")
	_assert_false(session.sim_clock.is_paused, "clock initially unpaused")

	# Open
	screen.open_journal()

	_assert_true(screen.is_open, "journal screen is open")
	_assert_true(screen.visible, "journal screen is visible")
	_assert_true(session.sim_clock.is_paused, "clock paused while journal open")
	_assert_false(player.is_physics_processing(), "player movement paused while journal open")

	# Check journal entries content
	var journal_labels: Array[String] = []
	for child in screen.journal_content.get_children():
		if child is Label:
			journal_labels.append(child.text)

	# Verify category headers are present
	var has_obs_header = false
	var has_fact_header = false
	var has_theory_header = false
	for text in journal_labels:
		if text.begins_with("Observations (1)"):
			has_obs_header = true
		if text.begins_with("Confirmed Facts (1)"):
			has_fact_header = true
		if text.begins_with("Unresolved Theories (1)"):
			has_theory_header = true

	_assert_true(has_obs_header, "Observations category header present")
	_assert_true(has_fact_header, "Confirmed Facts category header present")
	_assert_true(has_theory_header, "Unresolved Theories category header present")

	# Check fragments content
	var fragment_labels: Array[String] = []
	for child in screen.fragments_content.get_children():
		if child is Label:
			fragment_labels.append(child.text)

	var has_frag_title = false
	var has_frag_body = false
	for text in fragment_labels:
		if text == "Memory: The Lounge Bench":
			has_frag_title = true
		if text.contains("Her hand on my sleeve."):
			has_frag_body = true

	_assert_true(has_frag_title, "Memory fragment title resolved from FRAG_MIRA_DEPARTURE_TITLE")
	_assert_true(has_frag_body, "Memory fragment body resolved from FRAG_MIRA_DEPARTURE_BODY")

	# Close
	screen.close_journal()

	_assert_false(screen.is_open, "journal closed")
	_assert_false(session.sim_clock.is_paused, "clock resumed after journal closed")
	_assert_true(player.is_physics_processing(), "player movement resumed after journal closed")

	player.free()
	screen.free()
	session.free()


func test_journal_screen_empty_state() -> void:
	var sess_scene = load("res://scenes/session/GameSession.tscn")
	var session = sess_scene.instantiate() as GameSession
	scene_tree.root.add_child(session)

	var jrn_scene = load("res://scenes/ui/JournalScreen.tscn")
	var screen = jrn_scene.instantiate() as JournalScreen
	scene_tree.root.add_child(screen)

	screen.open_journal()

	var jrn_child = screen.journal_content.get_child(0) as Label
	_assert_true(jrn_child != null, "empty journal label exists")
	_assert_eq(jrn_child.text, "No journal entries recorded.", "empty journal label text matches")

	var frag_child = screen.fragments_content.get_child(0) as Label
	_assert_true(frag_child != null, "empty fragments label exists")
	_assert_eq(frag_child.text, "No memory fragments recovered.", "empty fragments label text matches")

	screen.close_journal()
	screen.free()
	session.free()
