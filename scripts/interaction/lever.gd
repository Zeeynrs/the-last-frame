class_name Lever
extends Interactable

## Test lever interactable for TLF-007 greybox validation.

signal toggled(is_on: bool)

@export var is_on: bool = false:
	set(val):
		is_on = val
		_update_visuals()

@onready var prompt_label: Label = $PromptLabel
@onready var visual_rect: ColorRect = $VisualRect


func _ready() -> void:
	super._ready()
	if prompt_text.is_empty() or prompt_text == "[E] Interact":
		prompt_text = "[E] Use Lever"
	_update_visuals()
	_update_prompt()


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	is_on = not is_on
	toggled.emit(is_on)
	_update_visuals()


func _on_focus_changed(_focused: bool) -> void:
	_update_prompt()


func _update_prompt() -> void:
	if prompt_label != null:
		prompt_label.visible = is_focused
		prompt_label.text = prompt_text


func _update_visuals() -> void:
	if visual_rect != null:
		visual_rect.color = Color(0.2, 0.8, 0.3) if is_on else Color(0.8, 0.2, 0.2)
