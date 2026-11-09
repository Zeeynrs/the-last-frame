class_name AbilityWheel
extends CanvasLayer

## Ability Wheel modal UI per ADR-021 and TLF-052.
## Opens on hold 'Z' / controller 'LT' (or toggle mode via Settings).
## Allows radial 6-segment selection around the pocket watch face.
## Pauses SimClock and blocks player input while open.

signal wheel_opened()
signal wheel_closed(selected_ability: StringName)
signal ability_highlighted(ability: StringName, segment_index: int)

const ABILITY_NAMES: Array[StringName] = [
	&"trace",
	&"rewind",
	&"freeze",
	&"echo",
	&"fast_forward",
	&"unknown",
]

const SEGMENT_ANGLES: Array[float] = [
	-90.0,
	-30.0,
	30.0,
	90.0,
	150.0,
	-150.0,
]

const SEGMENT_OFFSETS: Array[Vector2] = [
	Vector2(43, 0),
	Vector2(102, 12),
	Vector2(102, 81),
	Vector2(43, 117),
	Vector2(0, 81),
	Vector2(0, 12),
]

const POINTER_OFFSETS: Array[Vector2] = [
	Vector2(70, 36),
	Vector2(100, 54),
	Vector2(100, 88),
	Vector2(70, 104),
	Vector2(41, 88),
	Vector2(41, 54),
]

const POINTER_REST_OFFSET: Vector2 = Vector2(75, 75)
const FACE_OFFSET: Vector2 = Vector2(54, 50)

const ICON_OFFSETS: Array[Vector2] = [
	Vector2(72, 4),
	Vector2(126, 35),
	Vector2(126, 97),
	Vector2(72, 128),
	Vector2(18, 97),
	Vector2(18, 35),
]

const LABEL_CENTERS: Array[Vector2] = [
	Vector2(80, 22),
	Vector2(138, 53),
	Vector2(138, 115),
	Vector2(80, 146),
	Vector2(22, 115),
	Vector2(22, 53),
]

var is_open: bool = false
var current_aimed_segment: int = -1   # -1 = dead zone

var pocket_watch: PocketWatch = null
var _player_ref: CharacterBody2D = null

var _seen_unlocked: Array[StringName] = []
var _pulsed_abilities: Array[StringName] = []

var _seg_nodes: Array[TextureRect] = []
var _icon_nodes: Array[TextureRect] = []
var _label_nodes: Array[Label] = []

var _mouse_start_pos: Vector2 = Vector2.ZERO
var _mouse_moved: bool = false
var _left_stick: Vector2 = Vector2.ZERO
var _right_stick: Vector2 = Vector2.ZERO

# Texture caches
var _tex_face: Texture2D
var _tex_pointer_rest: Texture2D
var _tex_pointers: Array[Texture2D] = []
var _tex_seg_normal: Array[Texture2D] = []
var _tex_seg_selected: Array[Texture2D] = []
var _tex_seg_locked: Array[Texture2D] = []
var _tex_icons: Array[Texture2D] = []
var _tex_icons_locked: Array[Texture2D] = []

@onready var wheel_container: Control = $WheelContainer
@onready var segments_container: Control = $WheelContainer/Segments
@onready var face_rect: TextureRect = $WheelContainer/Face
@onready var pointer_rect: TextureRect = $WheelContainer/Pointer
@onready var icons_container: Control = $WheelContainer/Icons
@onready var labels_container: Control = $WheelContainer/Labels


func _ready() -> void:
	UIFeedback.init_translations()
	layer = 15
	visible = false
	_load_textures()
	_setup_nodes()


func _load_textures() -> void:
	_tex_face = load("res://assets/ui/ability_wheel/ch01_ui_wheel_face.png")
	_tex_pointer_rest = load("res://assets/ui/ability_wheel/ch01_ui_wheel_pointer_rest.png")

	_tex_pointers.clear()
	for i in range(6):
		_tex_pointers.append(load("res://assets/ui/ability_wheel/ch01_ui_wheel_pointer_%d.png" % i))

	_tex_seg_normal.clear()
	_tex_seg_selected.clear()
	_tex_seg_locked.clear()
	for i in range(6):
		_tex_seg_normal.append(load("res://assets/ui/ability_wheel/ch01_ui_wheel_seg%d_normal.png" % i))
		_tex_seg_selected.append(load("res://assets/ui/ability_wheel/ch01_ui_wheel_seg%d_selected.png" % i))
		_tex_seg_locked.append(load("res://assets/ui/ability_wheel/ch01_ui_wheel_seg%d_locked.png" % i))

	_tex_icons.clear()
	_tex_icons_locked.clear()
	for name in ABILITY_NAMES:
		_tex_icons.append(load("res://assets/ui/ability_wheel/ch01_ui_icon_%s.png" % name))
		_tex_icons_locked.append(load("res://assets/ui/ability_wheel/ch01_ui_icon_%s_locked.png" % name))


func _setup_nodes() -> void:
	if wheel_container == null:
		return

	# Setup face
	if face_rect != null:
		face_rect.texture = _tex_face
		face_rect.position = FACE_OFFSET

	# Setup pointer
	if pointer_rect != null:
		pointer_rect.texture = _tex_pointer_rest
		pointer_rect.position = POINTER_REST_OFFSET

	# Setup segments
	_seg_nodes.clear()
	if segments_container != null:
		for i in range(6):
			var node := segments_container.get_node_or_null("Seg%d" % i) as TextureRect
			if node == null:
				node = TextureRect.new()
				node.name = "Seg%d" % i
				segments_container.add_child(node)
			node.position = SEGMENT_OFFSETS[i]
			node.texture = _tex_seg_locked[i]
			_seg_nodes.append(node)

	# Setup icons
	_icon_nodes.clear()
	if icons_container != null:
		for i in range(6):
			var node := icons_container.get_node_or_null("Icon%d" % i) as TextureRect
			if node == null:
				node = TextureRect.new()
				node.name = "Icon%d" % i
				icons_container.add_child(node)
			node.position = ICON_OFFSETS[i]
			node.texture = _tex_icons_locked[i]
			_icon_nodes.append(node)

	# Setup labels
	_label_nodes.clear()
	if labels_container != null:
		for i in range(6):
			var node := labels_container.get_node_or_null("Label%d" % i) as Label
			if node == null:
				node = Label.new()
				node.name = "Label%d" % i
				labels_container.add_child(node)
			node.custom_minimum_size = Vector2(48, 12)
			node.size = Vector2(48, 12)
			node.position = Vector2(LABEL_CENTERS[i].x - 24, LABEL_CENTERS[i].y - 2)
			node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_label_nodes.append(node)


func bind_pocket_watch(watch: PocketWatch) -> void:
	pocket_watch = watch


func _find_pocket_watch() -> PocketWatch:
	if pocket_watch != null and is_instance_valid(pocket_watch):
		return pocket_watch
	var player = Player.find_player(self)
	if player != null and "pocket_watch" in player and player.pocket_watch != null:
		pocket_watch = player.pocket_watch
		return pocket_watch
	return null


func _find_session() -> GameSession:
	if not is_inside_tree():
		return null
	var sess = get_tree().get_first_node_in_group(&"game_session")
	if sess is GameSession:
		return sess
	return get_tree().root.find_child("GameSession", true, false) as GameSession


func _find_unlocks() -> AbilityUnlocks:
	var sess = _find_session()
	if sess != null and "ability_unlocks" in sess and sess.ability_unlocks != null:
		return sess.ability_unlocks
	return null


func is_ability_unlocked(ability: StringName) -> bool:
	if ability == &"unknown":
		return false
	var unlocks = _find_unlocks()
	if unlocks != null:
		return unlocks.is_unlocked(ability)
	var watch = _find_pocket_watch()
	if watch != null:
		return watch.is_ability_unlocked(ability)
	return false


func _is_modal_open() -> bool:
	if not is_inside_tree():
		return false
	var root = get_tree().root
	var diag = root.find_child("DialogueBox", true, false) as DialogueBox
	if diag != null and diag.is_active:
		return true
	var doc = root.find_child("DocumentViewer", true, false) as DocumentViewer
	if doc != null and doc.is_open:
		return true
	var jrn = root.find_child("JournalScreen", true, false) as JournalScreen
	if jrn != null and jrn.is_open:
		return true
	var ovl = root.find_child("ChapterCompleteOverlay", true, false) as CanvasLayer
	if ovl != null and ovl.visible:
		return true
	return false


func _input(event: InputEvent) -> void:
	if not is_open:
		if event.is_action_pressed(&"ability_wheel"):
			if not _is_modal_open():
				open_wheel()
				if get_viewport() != null:
					get_viewport().set_input_as_handled()
		return

	# Wheel IS open
	if event is InputEventMouseMotion:
		_mouse_moved = true
	elif event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_X:
			_left_stick.x = event.axis_value
		elif event.axis == JOY_AXIS_LEFT_Y:
			_left_stick.y = event.axis_value
		elif event.axis == JOY_AXIS_RIGHT_X:
			_right_stick.x = event.axis_value
		elif event.axis == JOY_AXIS_RIGHT_Y:
			_right_stick.y = event.axis_value
		_check_aim_update()

	var is_toggle := is_wheel_toggle_mode()

	if is_toggle:
		if event.is_action_pressed(&"confirm") or event.is_action_pressed(&"ability_wheel"):
			_commit_selection()
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"cancel"):
			close_wheel(false)
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
	else:
		if event.is_action_released(&"ability_wheel"):
			_commit_selection()
			if get_viewport() != null:
				get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not is_open:
		return
	_check_aim_update()


## Screen centre of the wheel (it is anchored to the middle of the view), for mouse aiming.
func _wheel_center() -> Vector2:
	if wheel_container != null and wheel_container.is_inside_tree():
		return wheel_container.get_global_rect().get_center()
	return get_viewport().get_visible_rect().get_center()


func _check_aim_update() -> void:
	var aim_vec := Vector2.ZERO
	var move_vec := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if move_vec.length() > 0.3:
		aim_vec = move_vec
	elif _left_stick.length() > 0.3:
		aim_vec = _left_stick
	elif _right_stick.length() > 0.3:
		aim_vec = _right_stick
	else:
		var right_stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		if right_stick.length() > 0.3:
			aim_vec = right_stick
		elif _mouse_moved:
			var mouse_pos := get_viewport().get_mouse_position()
			var m_vec := mouse_pos - _wheel_center()
			if m_vec.length() > 20.0:
				aim_vec = m_vec

	_update_aim(aim_vec)


func _update_aim(vec: Vector2) -> void:
	var seg := get_segment_for_vector(vec)
	if seg != current_aimed_segment:
		current_aimed_segment = seg
		_update_visuals()
		if seg >= 0:
			ability_highlighted.emit(ABILITY_NAMES[seg], seg)


func get_segment_for_vector(vec: Vector2) -> int:
	if vec.length() < 0.3:
		return -1
	var deg := rad_to_deg(vec.angle())
	var best_seg := -1
	var best_diff := 360.0
	for i in range(6):
		var diff := absf(wrapf(deg - SEGMENT_ANGLES[i] + 180.0, 0.0, 360.0) - 180.0)
		if diff < best_diff:
			best_diff = diff
			best_seg = i
	return best_seg


func open_wheel() -> void:
	if is_open:
		return

	is_open = true
	visible = true
	current_aimed_segment = -1
	_mouse_moved = false
	_left_stick = Vector2.ZERO
	_right_stick = Vector2.ZERO

	# Pause SimClock
	var sess := _find_session()
	if sess != null and sess.sim_clock != null:
		sess.sim_clock.is_paused = true

	# Block Player
	_set_player_blocked(true)

	# Check newly unlocked abilities for single pulse
	_check_new_unlock_pulses()

	_update_visuals()
	wheel_opened.emit()


func close_wheel(_commit: bool = false) -> void:
	if not is_open:
		return

	is_open = false
	visible = false

	# Unpause SimClock
	var sess := _find_session()
	if sess != null and sess.sim_clock != null:
		sess.sim_clock.is_paused = false

	# Unblock Player
	_set_player_blocked(false)

	var watch := _find_pocket_watch()
	var final_ability := watch.selected_ability if watch != null else &""
	wheel_closed.emit(final_ability)


func _commit_selection() -> void:
	if current_aimed_segment >= 0 and current_aimed_segment < 6:
		var target_ability := ABILITY_NAMES[current_aimed_segment]
		var watch := _find_pocket_watch()
		if watch != null:
			watch.set_selected_ability(target_ability)
	close_wheel(true)


func _check_new_unlock_pulses() -> void:
	var reduced := is_reduced_effects()
	for i in range(5):
		var ab := ABILITY_NAMES[i]
		if is_ability_unlocked(ab):
			if not _seen_unlocked.has(ab):
				_seen_unlocked.append(ab)
				if not reduced and not _pulsed_abilities.has(ab):
					_pulsed_abilities.append(ab)
					_trigger_pulse(i)


func _get_settings() -> Node:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		return get_tree().root.get_node_or_null("Settings")
	return null


func is_wheel_toggle_mode() -> bool:
	var s := _get_settings()
	if s != null and "wheel_toggle_mode" in s:
		return s.wheel_toggle_mode
	return false


func is_reduced_effects() -> bool:
	var s := _get_settings()
	if s != null and "reduced_effects" in s:
		return s.reduced_effects
	return false


func _trigger_pulse(seg_index: int) -> void:
	if seg_index < 0 or seg_index >= _icon_nodes.size():
		return
	var icon := _icon_nodes[seg_index]
	if icon == null:
		return
	var tw := create_tween()
	tw.tween_property(icon, "modulate", Color(1.8, 1.8, 1.8), 0.2)
	tw.tween_property(icon, "modulate", Color.WHITE, 0.2)


func _update_visuals() -> void:
	var watch := _find_pocket_watch()
	var cur_watch_ability := watch.selected_ability if watch != null else &"trace"

	# Update pointer
	if pointer_rect != null:
		if current_aimed_segment >= 0 and current_aimed_segment < 6:
			pointer_rect.texture = _tex_pointers[current_aimed_segment]
			pointer_rect.position = POINTER_OFFSETS[current_aimed_segment]
		else:
			pointer_rect.texture = _tex_pointer_rest
			pointer_rect.position = POINTER_REST_OFFSET

	# Update segments, icons, and labels
	for i in range(6):
		var ab_name := ABILITY_NAMES[i]
		var unlocked := is_ability_unlocked(ab_name)

		# State determination
		var is_selected := false
		if current_aimed_segment >= 0:
			is_selected = (i == current_aimed_segment)
		else:
			is_selected = (unlocked and ab_name == cur_watch_ability)

		# Segment texture
		if _seg_nodes.size() > i and _seg_nodes[i] != null:
			if not unlocked:
				_seg_nodes[i].texture = _tex_seg_locked[i]
			elif is_selected:
				_seg_nodes[i].texture = _tex_seg_selected[i]
			else:
				_seg_nodes[i].texture = _tex_seg_normal[i]

		# Icon texture
		if _icon_nodes.size() > i and _icon_nodes[i] != null:
			if unlocked:
				_icon_nodes[i].texture = _tex_icons[i]
			else:
				_icon_nodes[i].texture = _tex_icons_locked[i]

		# Label text & color
		if _label_nodes.size() > i and _label_nodes[i] != null:
			var lbl := _label_nodes[i]
			if unlocked:
				lbl.text = tr("ABILITY_" + String(ab_name).to_upper())
				lbl.visible = true
				if is_selected:
					lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
				else:
					lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			else:
				if i == 5:
					# Unknown slot: no name
					lbl.text = ""
					lbl.visible = false
				else:
					# Locked slot: show "Locked"
					lbl.text = tr("UI_WHEEL_LOCKED")
					lbl.visible = true
					lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))


func _set_player_blocked(blocked: bool) -> void:
	_player_ref = Player.set_player_blocked(self, blocked, _player_ref)
