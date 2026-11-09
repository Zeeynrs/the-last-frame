extends Control

## Title screen (TLF-037): New Game / Continue / Quit. 960x540 (ADR-023 addendum 3), TLF Pixel Mono, ASCII only.
## Keyboard and controller via move_up/move_down + confirm/interact; mouse optional.
## Continue is enabled only when SaveService has slot 0. New Game with a save asks once
## (UI_TITLE_OVERWRITE_CONFIRM); the save itself is only replaced at the first checkpoint.

signal item_activated(item: StringName)

const FONT_PATH := "res://assets/ui/fonts/tlf_pixel_mono.ttf"
const SAVE_SLOT := 0
const ITEMS: Array[StringName] = [&"new_game", &"continue", &"quit"]
const ITEM_KEYS := {
	&"new_game": "UI_TITLE_NEW_GAME",
	&"continue": "UI_TITLE_CONTINUE",
	&"quit": "UI_TITLE_QUIT",
}
const COLOR_SELECTED := Color(1.0, 0.85, 0.4)
const COLOR_NORMAL := Color(0.85, 0.88, 0.92)
const COLOR_DISABLED := Color(0.4, 0.43, 0.48)

@onready var title_label: Label = $Title
@onready var menu: VBoxContainer = $Menu
@onready var message_label: Label = $Message
@onready var hint_label: Label = $Hint

var selected: int = 0
var continue_enabled: bool = false
var overwrite_pending: bool = false
var _started: bool = false
var _labels: Dictionary = {}   # item -> Label


func _ready() -> void:
	UIFeedback.init_translations()
	var prj_theme := load("res://scenes/ui/theme/tlf_ui_theme.tres") as Theme
	if prj_theme != null:
		theme = prj_theme
	_labels = {&"new_game": $Menu/NewGame, &"continue": $Menu/Continue, &"quit": $Menu/Quit}
	for item in ITEMS:
		var label: Label = _labels[item]
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_entered.connect(_on_item_hovered.bind(item))
		label.gui_input.connect(_on_item_gui_input.bind(item))
	title_label.text = tr("UI_TITLE_GAME")
	hint_label.text = "%s/%s %s   %s %s" % [
		InputPrompts.get_action_glyph(&"move_up"), InputPrompts.get_action_glyph(&"move_down"),
		tr("UI_TITLE_SELECT"), InputPrompts.get_action_glyph(&"confirm"), tr("UI_TITLE_CONFIRM")]
	message_label.text = ""
	refresh()


## Re-reads the save slot and redraws the menu (Continue defaults when a save exists).
func refresh() -> void:
	var store := get_node_or_null("/root/SaveService") as SaveStore
	continue_enabled = store != null and store.has_slot(SAVE_SLOT)
	selected = ITEMS.find(&"continue") if continue_enabled else ITEMS.find(&"new_game")
	overwrite_pending = false
	message_label.text = ""
	_redraw()


func selected_item() -> StringName:
	return ITEMS[selected]


func is_enabled(item: StringName) -> bool:
	return item != &"continue" or continue_enabled


func move_selection(step: int) -> void:
	var index := selected
	for i in ITEMS.size():
		index = wrapi(index + step, 0, ITEMS.size())
		if is_enabled(ITEMS[index]):
			break
	if index != selected:
		selected = index
		overwrite_pending = false
		message_label.text = ""
		_redraw()


func activate() -> void:
	if _started:
		return
	var item := selected_item()
	if not is_enabled(item):
		return
	match item:
		&"new_game":
			if continue_enabled and not overwrite_pending:
				overwrite_pending = true
				message_label.text = tr("UI_TITLE_OVERWRITE_CONFIRM")
				return
			_start(-1)
		&"continue":
			_start(SAVE_SLOT)
		&"quit":
			_started = true
			item_activated.emit(item)
			get_tree().quit()
			return
	item_activated.emit(item)


func _start(restore_slot: int) -> void:
	_started = true
	var router := get_node_or_null("/root/SceneRouter")
	if router != null:
		router.start_chapter(router.CHAPTER_01_SCENE, restore_slot)


func _unhandled_input(event: InputEvent) -> void:
	if _started:
		return
	# Grab the viewport first: starting a chapter removes this scene from the tree immediately.
	var viewport := get_viewport()
	if event.is_action_pressed(&"move_up"):
		move_selection(-1)
	elif event.is_action_pressed(&"move_down"):
		move_selection(1)
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"interact"):
		activate()
	else:
		return
	if viewport != null:
		viewport.set_input_as_handled()


func _on_item_hovered(item: StringName) -> void:
	var index := ITEMS.find(item)
	if is_enabled(item) and index != selected:
		selected = index
		overwrite_pending = false
		message_label.text = ""
		_redraw()


func _on_item_gui_input(event: InputEvent, item: StringName) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and is_enabled(item):
		selected = ITEMS.find(item)
		_redraw()
		activate()


func _redraw() -> void:
	for i in ITEMS.size():
		var item := ITEMS[i]
		var label: Label = _labels[item]
		var text := tr(ITEM_KEYS[item])
		label.text = ("> %s <" % text) if i == selected else text
		label.add_theme_color_override(&"font_color",
			COLOR_DISABLED if not is_enabled(item) else (COLOR_SELECTED if i == selected else COLOR_NORMAL))
