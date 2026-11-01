extends "res://tests/support/base_test.gd"

## TraceMemory (TLF-050, CH01_EXPANSION.md 0.1): Trace reveals a memory. Real input: Trace is
## selected and `watch` is pressed on the object in Chapter 1's arrival platform. The memory is
## added to the loaded room at runtime (placing it in room scenes is a later Flash task).
## The SaveService autoload is pointed at a test root for every test (ISSUE-016).

const CH01_SCENE := "res://scenes/chapters/ch01/Chapter01.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_trace_memory_saves"
const MEMORY_ID := &"ch01.arrival_platform.test_memory"
const FLAG := &"ch01.flag.test_memory_seen"
const JOURNAL_KEY := "JRN_CH1_TURNSTILE_TRACE"
const LINES := [["SPK_ELIAS", "EL_B01_01"], ["SPK_ELIAS", "EL_B01_02"]]

var _store: SaveStore = null
var _original_root: String = ""
var _ch01: Node2D = null
var _session: GameSession = null
var _player: Player = null


func _init() -> void:
	timeout_frames = 1200


func _remove_root() -> void:
	var dir := DirAccess.open(TEST_SAVE_ROOT)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	if DirAccess.dir_exists_absolute(TEST_SAVE_ROOT):
		DirAccess.remove_absolute(TEST_SAVE_ROOT)


func _begin() -> void:
	_store = _tree().root.get_node("SaveService") as SaveStore
	_original_root = _store.save_root
	_remove_root()
	_store.save_root = TEST_SAVE_ROOT
	_ch01 = (load(CH01_SCENE) as PackedScene).instantiate() as Node2D
	_tree().root.add_child(_ch01)
	_session = _ch01.get_node("GameSession") as GameSession
	_player = _ch01.get_node("Player") as Player
	# Setup: Beat 01 already heard, so its monologue doesn't share the DialogueBox with the memory.
	_session.narrative_state.set_flag(&"heard.ch01_b01_start", true)
	await physics_frames(3)


func _end() -> void:
	release_all_input()
	if _ch01 != null:
		var router := _ch01.get_node("RoomRouter") as RoomRouter
		if router.current_room != null:
			router._unload_current()
		_tree().root.remove_child(_ch01)
		_ch01.free()
		_ch01 = null
	_store.save_root = _original_root
	_remove_root()
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root removed")


## A TraceMemory right next to the player in the loaded room.
func _add_memory(id: StringName, configure: Callable = Callable()) -> TraceMemory:
	var memory := TraceMemory.new()
	memory.name = String(id).get_slice(".", 2)
	memory.object_id = id
	memory.lines = LINES
	memory.flag_id = FLAG
	memory.journal_key = JOURNAL_KEY
	if configure.is_valid():
		configure.call(memory)
	var router := _ch01.get_node("RoomRouter") as RoomRouter
	router.current_room.add_child(memory)
	memory.global_position = _player.global_position + Vector2(12, 0)
	return memory


func _diag() -> DialogueBox:
	return _tree().root.find_child("DialogueBox", true, false) as DialogueBox


func _journal_count(key: String) -> int:
	return _session.narrative_state.get_journal().filter(func(e: Dictionary) -> bool: return e["key"] == key).size()


func test_trace_with_real_input_reveals_the_memory_once() -> void:
	await _begin()
	var memory := _add_memory(MEMORY_ID)
	var watch: PocketWatch = _player.pocket_watch
	var revealed: Array = []
	memory.memory_revealed.connect(func(id: StringName) -> void: revealed.append(id))
	var diag := _diag()
	var shown: Array = []
	diag.line_displayed.connect(func(_speaker: String, text_key: String) -> void: shown.append(text_key))

	_assert_eq(watch.selected_ability, &"trace", "Trace is selected")
	await physics_frames(2)
	_assert_eq(watch.current_target, memory, "Trace auto-targets the memory")
	_assert_true(memory.supports_ability(&"trace"), "a TraceMemory is traceable")
	await tap(&"watch")

	_assert_eq(revealed, [MEMORY_ID], "memory_revealed(object_id)")
	_assert_eq(diag.current_sequence_id, StringName("trace.%s" % MEMORY_ID), "sequence trace.<object_id>")
	_assert_true(diag.is_active and not diag.is_blocking, "non-blocking dialogue")
	_assert_eq(shown, ["EL_B01_01"], "first line shown")
	_assert_eq(diag.text_label.text, tr("EL_B01_01"), "translated line on screen")
	_assert_true(_session.narrative_state.get_flag(FLAG), "flag_id set")
	_assert_true(memory.is_revealed(), "traced.<object_id> set")
	_assert_eq(_journal_count(JOURNAL_KEY), 1, "journal entry added")
	_assert_true(_player.is_physics_processing(), "the player can keep walking")

	await tap(&"confirm")
	_assert_eq(shown, ["EL_B01_01", "EL_B01_02"], "confirm advances the non-blocking lines")
	await tap(&"confirm")
	_assert_false(diag.is_active, "sequence finished")

	await tap(&"watch")
	_assert_eq(revealed.size(), 2, "tracing again reveals again")
	_assert_eq(shown.size(), 3, "and replays the lines")
	_assert_eq(diag.current_sequence_id, StringName("trace.%s" % MEMORY_ID), "same sequence replayed")
	_assert_eq(_journal_count(JOURNAL_KEY), 1, "no second journal entry")
	await _end()


func test_one_shot_dialogue_and_use_rules() -> void:
	await _begin()
	var once := _add_memory(&"ch01.arrival_platform.test_memory_once", func(m: TraceMemory) -> void:
		m.one_shot_dialogue = true
		m.journal_key = "")
	var diag := _diag()
	var shown: Array = []
	diag.line_displayed.connect(func(_speaker: String, text_key: String) -> void: shown.append(text_key))
	var service := _session.interaction_service
	_assert_true(service.request(&"player", once.object_id, &"trace").ok, "trace accepted")
	_assert_eq(shown.size(), 1, "first trace plays")
	diag.finish_sequence()
	_assert_true(service.request(&"player", once.object_id, &"trace").ok, "second trace accepted")
	_assert_eq(shown.size(), 1, "one_shot_dialogue: no replay")
	_assert_eq(_session.narrative_state.get_journal().size(), 0, "no journal key, no entry")

	var result := service.request(&"player", once.object_id, &"use")
	_assert_eq(result.reason, &"unsupported", "use is refused (Trace only)")
	_assert_eq(service.request(&"player", once.object_id, &"rewind").reason, &"unsupported", "other abilities refused")

	var usable := _add_memory(&"ch01.arrival_platform.test_memory_use", func(m: TraceMemory) -> void: m.allow_use = true)
	var used: Array = []
	usable.memory_revealed.connect(func(id: StringName) -> void: used.append(id))
	_assert_true(service.request(&"player", usable.object_id, &"use").ok, "allow_use: use accepted")
	_assert_eq(used, [usable.object_id], "allow_use: use reveals the memory")
	await _end()


func test_revealed_state_survives_a_save() -> void:
	await _begin()
	var memory := _add_memory(MEMORY_ID)
	_session.interaction_service.request(&"player", MEMORY_ID, &"trace")
	var router := _ch01.get_node("RoomRouter") as RoomRouter
	var data := router.capture_save("ch01.cp.arrival")
	_assert_true(data["narrative_flags"].has("traced.%s" % MEMORY_ID), "traced flag saved")
	_session.narrative_state.import_state({}, [])
	_assert_false(memory.is_revealed(), "cleared")
	_store.apply(_session, data)
	_assert_true(memory.is_revealed(), "restored from the save")
	var before := _journal_count(JOURNAL_KEY)
	_session.interaction_service.request(&"player", MEMORY_ID, &"trace")
	_assert_eq(_journal_count(JOURNAL_KEY), before, "no new journal entry after loading")
	await _end()
