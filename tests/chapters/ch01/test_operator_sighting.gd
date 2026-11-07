extends "res://tests/support/base_test.gd"

## Automated Test Suite for TLF-058 (Operator Sighting on Arrival Platform).
## Verifies Story Bible Ch1 Event 7 / ADR-022 D3 / OPERATOR_MYSTERY_GUIDELINES:
## 1. Node placement, geometry, textures, foot pivot, and non-blocking collision.
## 2. Dormancy before pocket watch pickup; appearance on watch acquired.
## 3. 4-frame watch-check animation cadence (0.25 / 0.25 / 1.00 / 0.25 s).
## 4. Reduced effects accessibility: static F3 pose, suppressed VFX ring, instant cut.
## 5. Approach trigger: audio sting hook, seen flag, journal entry JRN_CH1_FIGURE, fadeout.
## 6. Full save/load persistence across all states.
## 7. Zero input lock, zero dialogue popups, mystery guidelines invariants.

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const ARRIVAL_SCENE_PATH := "res://scenes/chapters/ch01/rooms/arrival_platform.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_op_saves"
const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"


func _record_real_save_state() -> Dictionary:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	var mtime := FileAccess.get_modified_time(REAL_SAVE_SLOT_0) if exists else 0
	return {"exists": exists, "mtime": mtime}


func _assert_real_save_unchanged(before: Dictionary, context: String) -> void:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	_assert_eq(exists, before["exists"], "%s: real save existence unchanged" % context)
	if before["exists"]:
		var mtime := FileAccess.get_modified_time(REAL_SAVE_SLOT_0)
		_assert_eq(mtime, before["mtime"], "%s: real save modified time unchanged" % context)


func _cleanup_test_save_dir() -> void:
	var dir := DirAccess.open(TEST_SAVE_ROOT)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
		for sub_dir in dir.get_directories():
			dir.remove(sub_dir)
	if DirAccess.dir_exists_absolute(TEST_SAVE_ROOT):
		DirAccess.remove_absolute(TEST_SAVE_ROOT)


func _make_ch01() -> Chapter01:
	_cleanup_test_save_dir()
	var ch01_scene := load(CH01_SCENE_PATH) as PackedScene
	var ch01 := ch01_scene.instantiate() as Chapter01
	var router := ch01.get_node_or_null("RoomRouter") as RoomRouter
	if router != null:
		var store := SaveStore.new()
		store.name = "TestSaveStore"
		store.save_root = TEST_SAVE_ROOT
		router.add_child(store)
		router.save_service = store

	var hud_scene := load("res://scenes/ui/HUD.tscn") as PackedScene
	var hud := hud_scene.instantiate() as HUD
	ch01.add_child(hud)

	_tree().root.add_child(ch01)
	return ch01


func _cleanup_ch01(ch01: Node) -> void:
	if ch01 == null:
		return
	var router: RoomRouter = ch01.get_node_or_null("RoomRouter")
	if router != null and router.current_room != null:
		router._unload_current()
	if ch01.get_parent() != null:
		ch01.get_parent().remove_child(ch01)
	ch01.free()
	_cleanup_test_save_dir()


# -------------------------------------------------------------------------------------------------
# 1. Placement, Geometry, and Visual Properties
# -------------------------------------------------------------------------------------------------
func test_operator_sighting_node_and_visual_properties() -> void:
	var scene := load(ARRIVAL_SCENE_PATH) as PackedScene
	_assert_true(scene != null, "arrival_platform.tscn loads cleanly")
	var inst := scene.instantiate() as Node2D
	_assert_true(inst != null, "arrival_platform.tscn instantiates cleanly")

	var op := inst.get_node_or_null("operator_sighting") as OperatorSighting
	_assert_true(op != null, "operator_sighting node exists on arrival_platform")
	_assert_eq(op.position, Vector2(432, 152), "Operator placed at proposed tile (9, 2) -> (432, 152)")

	# Check child nodes
	var figure := op.get_node_or_null("FigureSprite") as Sprite2D
	_assert_true(figure != null, "FigureSprite child exists")
	_assert_eq(figure.z_index, 10, "FigureSprite at z_index 10 (YSort_Actors)")
	_assert_eq(figure.hframes, 4, "FigureSprite has 4 horizontal frames")
	_assert_eq(figure.offset, Vector2(-16, -44), "FigureSprite foot pivot offset (-16, -44)")
	_assert_false(figure.centered, "FigureSprite uses centered = false for foot pivot")

	var ring := op.get_node_or_null("GroundRing") as Sprite2D
	_assert_true(ring != null, "GroundRing child exists")
	_assert_eq(ring.z_index, 8, "GroundRing at z_index 8 (YSort_Props)")
	_assert_eq(ring.offset, Vector2(-16, -44), "GroundRing foot pivot offset (-16, -44)")
	_assert_false(ring.centered, "GroundRing uses centered = false for foot pivot")

	var trigger := op.get_node_or_null("ApproachTrigger") as TriggerZone
	_assert_true(trigger != null, "ApproachTrigger child exists")
	_assert_eq(trigger.object_id, &"ch01.arrival_platform.operator_approach_trigger", "ApproachTrigger has canonical object_id")
	_assert_false(trigger.accepts_echoes, "ApproachTrigger does not accept echoes")
	_assert_eq(trigger.position, Vector2(-12, 8), "ApproachTrigger offset (-12, 8) -> global (420, 160)")

	var col_shape := trigger.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_assert_true(col_shape != null, "ApproachTrigger has CollisionShape2D")
	_assert_true(col_shape.shape is CircleShape2D, "ApproachTrigger uses CircleShape2D")
	var circle := col_shape.shape as CircleShape2D
	_assert_eq(circle.radius, 32.0, "ApproachTrigger radius is 32.0 px")

	var audio := op.get_node_or_null("AudioSting") as AudioStreamPlayer2D
	_assert_true(audio != null, "AudioSting hook player exists for TLF-064")

	# Operator has NO physical blocking collider
	var bodies: Array[StaticBody2D] = []
	for child in op.get_children():
		if child is StaticBody2D:
			bodies.append(child)
	_assert_eq(bodies.size(), 0, "Operator has zero StaticBody2D colliders (does not block any path)")

	inst.free()


# -------------------------------------------------------------------------------------------------
# 2. Dormancy before Watch Pickup & Appearance on Watch Acquired
# -------------------------------------------------------------------------------------------------
func test_operator_sighting_dormant_before_pickup_and_appears_on_watch() -> void:
	var real_save := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)

	var session := ch01.session
	var room := ch01.room_router.current_room
	var op := room.get_node_or_null("operator_sighting") as OperatorSighting
	_assert_true(op != null, "operator_sighting present in current room")

	# Before pickup: figure is hidden and dormant
	_assert_false(session.narrative_state.get_flag(&"ch01.flag.pocket_watch_acquired", false), "watch not acquired yet")
	_assert_false(op.is_figure_active(), "figure is not active before watch pickup")
	_assert_false(op.visible, "figure is invisible before watch pickup")

	# Stepping on approach trigger before watch pickup does nothing
	var trigger := op.approach_trigger
	trigger.actor_entered.emit(&"player")
	await physics_frames(2)
	_assert_false(session.narrative_state.get_flag(&"ch01.flag.operator_sighting_seen", false), "seen flag NOT set before watch pickup")
	_assert_false(op.is_seen(), "op not marked seen before watch pickup")

	# Now acquire the pocket watch
	session.narrative_state.set_flag(&"ch01.flag.pocket_watch_acquired", true)
	await physics_frames(2)

	_assert_true(op.visible, "figure becomes visible on watch pickup")
	_assert_true(op.is_figure_active(), "figure is active on watch pickup")
	_assert_eq(op.modulate.a, 1.0, "figure fully opaque on watch pickup")
	_assert_true(op.ground_ring.visible, "ground ring visible in standard mode")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save, "test_operator_sighting_dormant_before_pickup")


# -------------------------------------------------------------------------------------------------
# 3. Watch-Check Animation Cadence (0.25 / 0.25 / 1.00 / 0.25 s)
# -------------------------------------------------------------------------------------------------
func test_operator_sighting_animation_cadence() -> void:
	var op := OperatorSighting.new()
	var figure := Sprite2D.new()
	figure.hframes = 4
	var ring := Sprite2D.new()
	op.figure_sprite = figure
	op.ground_ring = ring
	op.add_child(figure)
	op.add_child(ring)
	_tree().root.add_child(op)

	# Simulate active state without session
	op._is_active = true
	op.visible = true
	op.set_process(true)

	# t = 0.10s -> F1 (frame 0)
	op._process(0.10)
	_assert_eq(figure.frame, 0, "cadence t=0.10s is Frame 0 (F1)")

	# t = 0.30s (0.10 + 0.20) -> F2 (frame 1, lifts watch)
	op._process(0.20)
	_assert_eq(figure.frame, 1, "cadence t=0.30s is Frame 1 (F2 lifts watch)")

	# t = 0.60s (0.30 + 0.30) -> F3 (frame 2, checks watch)
	op._process(0.30)
	_assert_eq(figure.frame, 2, "cadence t=0.60s is Frame 2 (F3 checks watch)")

	# t = 1.40s (0.60 + 0.80) -> F3 (frame 2, holds watch check for 1.00s)
	op._process(0.80)
	_assert_eq(figure.frame, 2, "cadence t=1.40s remains Frame 2 (F3 hold)")

	# t = 1.60s (1.40 + 0.20) -> F4 (frame 3, lowers watch)
	op._process(0.20)
	_assert_eq(figure.frame, 3, "cadence t=1.60s is Frame 3 (F4 lowers watch)")

	# t = 1.80s (1.60 + 0.20) -> wraps past 1.75s to 0.05s -> F1 (frame 0)
	op._process(0.20)
	_assert_eq(figure.frame, 0, "cadence t=1.80s loops back to Frame 0 (F1)")

	op.free()


# -------------------------------------------------------------------------------------------------
# 4. Accessibility: Reduced Effects Mode
# -------------------------------------------------------------------------------------------------
func test_operator_sighting_reduced_effects_mode() -> void:
	var settings_node = _tree().root.get_node_or_null("Settings")
	var orig_reduced: bool = false
	if settings_node != null and "reduced_effects" in settings_node:
		orig_reduced = settings_node.reduced_effects
		settings_node.reduced_effects = true

	var op := OperatorSighting.new()
	var figure := Sprite2D.new()
	figure.hframes = 4
	var ring := Sprite2D.new()
	op.figure_sprite = figure
	op.ground_ring = ring
	op.add_child(figure)
	op.add_child(ring)
	_tree().root.add_child(op)

	op._is_active = true
	op.visible = true
	op.set_process(true)
	op._apply_reduced_effects_state()

	# Under reduced_effects: static F3 (frame 2), ring suppressed
	_assert_eq(figure.frame, 2, "reduced_effects locks to Frame 2 (F3 check watch)")
	_assert_false(ring.visible, "reduced_effects suppresses ground ring")

	# Stepping process delta does not advance frame
	op._process(0.50)
	_assert_eq(figure.frame, 2, "reduced_effects stays static on Frame 2 after time advance")
	_assert_false(ring.visible, "ground ring remains suppressed")

	# Vanish under reduced_effects is instant static cut (no 0.5s tween)
	op._trigger_vanish()
	_assert_false(op.visible, "reduced_effects vanish is an immediate static cut")
	_assert_false(op.is_figure_active(), "figure inactive immediately")

	op.free()

	if settings_node != null and "reduced_effects" in settings_node:
		settings_node.reduced_effects = orig_reduced


# -------------------------------------------------------------------------------------------------
# 5. Approach Trigger: Audio Sting Hook, Seen Flag, Journal Entry, Fadeout
# -------------------------------------------------------------------------------------------------
func test_operator_sighting_vanishes_on_approach() -> void:
	var real_save := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)

	var session := ch01.session
	var room := ch01.room_router.current_room
	var op := room.get_node_or_null("operator_sighting") as OperatorSighting
	_assert_true(op != null, "operator_sighting node found")

	session.narrative_state.set_flag(&"ch01.flag.pocket_watch_acquired", true)
	await physics_frames(2)
	_assert_true(op.is_figure_active(), "figure active after watch pickup")

	# Connect audio sting tracker
	var audio_stung: Array[bool] = [false]
	op.audio_sting_requested.connect(func() -> void: audio_stung[0] = true)

	# Player enters approach trigger
	op.approach_trigger.actor_entered.emit(&"player")

	_assert_true(audio_stung[0], "audio_sting_requested emitted on approach")
	_assert_true(session.narrative_state.get_flag(&"ch01.flag.operator_sighting_seen", false), "operator_sighting_seen flag set")

	# Verify journal entry
	var has_journal: bool = false
	for entry in session.narrative_state.get_journal():
		if entry["key"] == "JRN_CH1_FIGURE" and entry["category"] == "observation":
			has_journal = true
			break
	_assert_true(has_journal, "JRN_CH1_FIGURE journal observation entry added")

	# Wait for fadeout tween (0.5 s = ~30 frames)
	await physics_frames(35)
	_assert_false(op.visible, "figure invisible after 0.5s fadeout")
	_assert_false(op.is_figure_active(), "figure inactive after fadeout")
	_assert_true(op.is_seen(), "op marked as seen")

	# Entering trigger again does nothing (idempotent, no duplicate journal)
	var journal_count_before: int = session.narrative_state.get_journal().size()
	op.approach_trigger.actor_entered.emit(&"player")
	await physics_frames(2)
	_assert_eq(session.narrative_state.get_journal().size(), journal_count_before, "no duplicate journal on repeat entry")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save, "test_operator_sighting_vanishes_on_approach")


# -------------------------------------------------------------------------------------------------
# 6. Save/Load Lifecycle Persistence
# -------------------------------------------------------------------------------------------------
func test_operator_sighting_save_load_lifecycle() -> void:
	var real_save := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)

	var session := ch01.session
	var router := ch01.room_router
	var store: Node = _tree().root.get_node_or_null("SaveService")
	var created_store := false
	if store == null:
		store = (load("res://scripts/save/save_service.gd") as GDScript).new()
		created_store = true

	# Case A: Save before watch pickup
	var save_a: Dictionary = store.capture(session, "ch01", "safe_anchor_spawn")
	_assert_false(save_a["narrative_flags"].get("ch01.flag.pocket_watch_acquired", false), "Save A: watch not acquired")
	_assert_false(save_a["narrative_flags"].get("ch01.flag.operator_sighting_seen", false), "Save A: sighting not seen")

	# Case B: Pick up watch, then save before approaching figure
	session.narrative_state.set_flag(&"ch01.flag.pocket_watch_acquired", true)
	await physics_frames(2)
	var op := router.current_room.get_node("operator_sighting") as OperatorSighting
	_assert_true(op.is_figure_active(), "figure active before approach")

	var save_b: Dictionary = store.capture(session, "ch01", "safe_anchor_spawn")
	_assert_true(save_b["narrative_flags"].get("ch01.flag.pocket_watch_acquired", false), "Save B: watch acquired")
	_assert_false(save_b["narrative_flags"].get("ch01.flag.operator_sighting_seen", false), "Save B: sighting not yet seen")

	# Case C: Approach figure -> vanishes -> save
	op.trigger_approach()
	await physics_frames(35)
	_assert_false(op.visible, "figure vanished")
	_assert_true(session.narrative_state.get_flag(&"ch01.flag.operator_sighting_seen", false), "sighting seen")

	var save_c: Dictionary = store.capture(session, "ch01", "safe_anchor_spawn")
	_assert_true(save_c["narrative_flags"].get("ch01.flag.operator_sighting_seen", false), "Save C: sighting seen")

	# --- Test Loading Save A (before watch pickup) ---
	store.apply(session, save_a)
	op.refresh_state()
	_assert_false(op.is_figure_active(), "Loading Save A: figure remains dormant")
	_assert_false(op.visible, "Loading Save A: figure remains invisible")

	# --- Test Loading Save B (watch picked up, figure present) ---
	store.apply(session, save_b)
	op.refresh_state()
	_assert_true(op.is_figure_active(), "Loading Save B: figure reappears active")
	_assert_true(op.visible, "Loading Save B: figure is visible at far end of platform")

	# --- Test Loading Save C (sighting seen) ---
	store.apply(session, save_c)
	op.refresh_state()
	_assert_false(op.is_figure_active(), "Loading Save C: figure never appears again")
	_assert_false(op.visible, "Loading Save C: figure stays hidden")

	if created_store:
		store.free()
	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save, "test_operator_sighting_save_load_lifecycle")


# -------------------------------------------------------------------------------------------------
# 7. Operator Mystery Guidelines Invariants
# -------------------------------------------------------------------------------------------------
func test_operator_mystery_guidelines_invariants() -> void:
	var real_save := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)

	var session := ch01.session
	var room := ch01.room_router.current_room
	var op := room.get_node_or_null("operator_sighting") as OperatorSighting
	var hud := ch01.get_node_or_null("HUD") as HUD

	# Advance opening Beat 01 monologue if active
	if hud != null and hud.dialogue_box != null:
		while hud.dialogue_box.is_active:
			hud.dialogue_box.advance_line()
	await physics_frames(2)

	session.narrative_state.set_flag(&"ch01.flag.pocket_watch_acquired", true)
	await physics_frames(2)

	# Trigger vanish
	op.trigger_approach()
	await physics_frames(5)

	# Rule 3: No dialogue box popped up
	if hud != null and hud.dialogue_box != null:
		_assert_false(hud.dialogue_box.is_active, "No dialogue popups during Operator sighting or vanish")

	# No input lock / player freeze
	var player := ch01.get_node_or_null("Player") as Player
	if player != null:
		_assert_false(player._input_blocked, "Player input remains free and unlocked throughout sighting")

	# Localization key exists and contains valid text
	var journal_text := tr("JRN_CH1_FIGURE")
	_assert_true(journal_text.length() > 0, "JRN_CH1_FIGURE is localized")
	_assert_false(journal_text == "JRN_CH1_FIGURE", "JRN_CH1_FIGURE has translation text")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save, "test_operator_mystery_guidelines_invariants")
