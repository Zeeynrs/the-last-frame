class_name TestGate
extends Interactable

## Greybox test gate per TLF-008 / CH1-PZ-001.
## Demonstrates Rewind on pre-arrival initial_history and physical jam rejection.

signal gate_state_changed(arm_state: StringName, passage_blocked: bool)

@export var arm_state: StringName = &"collapsed"
@export var passage_blocked: bool = true

var temporal: TemporalComponent
var _visual_rect: ColorRect = null
var _status_label: Label = null


func _ready() -> void:
	if prompt_text == "[E] Interact":
		prompt_text = "[E] Turnstile Gate"

	_setup_temporal()
	super._ready()
	_setup_visuals()
	_update_visuals()


func _setup_temporal() -> void:
	temporal = get_temporal_component()
	if temporal == null:
		temporal = TemporalComponent.new()
		temporal.name = "TemporalComponent"
		temporal.capabilities = TemporalComponent.Capability.REWIND
		temporal.schema_version = 1
		temporal.state_fields = ["arm_state", "passage_blocked"]
		var h: Array[Dictionary] = [
			{"arm_state": &"open", "passage_blocked": false}
		]
		temporal.initial_history = h
		add_child(temporal)
		if not temporal.is_inside_tree():
			temporal.init_history()


func capture_state() -> Dictionary:
	return {
		"arm_state": arm_state,
		"passage_blocked": passage_blocked,
	}


func apply_state(d: Dictionary) -> void:
	arm_state = d["arm_state"]
	passage_blocked = d["passage_blocked"]
	_update_visuals()
	gate_state_changed.emit(arm_state, passage_blocked)


func can_interact(actor_id: StringName, interaction_id: StringName, payload: Dictionary = {}) -> StringName:
	if interaction_id == &"use":
		if arm_state == &"collapsed":
			return &"jammed"
		return &"already_open"
	return super.can_interact(actor_id, interaction_id, payload)


func _setup_visuals() -> void:
	if _visual_rect == null:
		_visual_rect = ColorRect.new()
		_visual_rect.name = "GateVisual"
		_visual_rect.position = Vector2(-16, -16)
		_visual_rect.size = Vector2(32, 32)
		add_child(_visual_rect)

	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = "GateStatus"
		_status_label.position = Vector2(-24, -28)
		_status_label.size = Vector2(48, 14)
		_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status_label.add_theme_font_size_override("font_size", 8)
		add_child(_status_label)


func _update_visuals() -> void:
	if _visual_rect != null:
		_visual_rect.color = Color(0.85, 0.25, 0.2) if passage_blocked else Color(0.2, 0.8, 0.5)
	if _status_label != null:
		_status_label.text = "[X] JAMMED" if passage_blocked else "[>>] OPEN"
