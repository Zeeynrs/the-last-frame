class_name TestGear
extends Interactable

## Greybox counterweight gear per TLF-008 / CH1-PZ-002.
## Demonstrates Freeze toggle ability and cross-object coupling with TestShutter.

signal gear_state_changed(gear_state: StringName, is_frozen: bool)

@export var gear_state: StringName = &"idle"

var temporal: TemporalComponent
var _visual_rect: ColorRect = null
var _status_label: Label = null


func _ready() -> void:
	if prompt_text == "[E] Interact":
		prompt_text = "Counterweight Gear"

	_setup_temporal()
	super._ready()
	_setup_visuals()
	_update_visuals()


func _setup_temporal() -> void:
	temporal = get_temporal_component()
	if temporal == null:
		temporal = TemporalComponent.new()
		temporal.name = "TemporalComponent"
		temporal.capabilities = TemporalComponent.Capability.FREEZE
		temporal.schema_version = 1
		temporal.state_fields = ["gear_state"]
		var h: Array[Dictionary] = []
		temporal.initial_history = h
		add_child(temporal)
		if not temporal.is_inside_tree():
			temporal.init_history()
	temporal.freeze_changed.connect(_on_freeze_changed)


func capture_state() -> Dictionary:
	return {
		"gear_state": gear_state,
	}


func apply_state(d: Dictionary) -> void:
	gear_state = d["gear_state"]
	_update_visuals()


func is_gear_frozen() -> bool:
	var tc = get_temporal_component()
	return tc != null and tc.is_frozen


func can_interact(actor_id: StringName, interaction_id: StringName, payload: Dictionary = {}) -> StringName:
	if interaction_id == &"rewind" or interaction_id == &"use":
		return &"unsupported"
	return super.can_interact(actor_id, interaction_id, payload)


func _on_freeze_changed(_p_is_frozen: bool) -> void:
	_update_visuals()
	gear_state_changed.emit(gear_state, is_gear_frozen())


func _setup_visuals() -> void:
	if _visual_rect == null:
		_visual_rect = ColorRect.new()
		_visual_rect.name = "GearVisual"
		_visual_rect.position = Vector2(-14, -14)
		_visual_rect.size = Vector2(28, 28)
		add_child(_visual_rect)

	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = "GearStatus"
		_status_label.position = Vector2(-28, -26)
		_status_label.size = Vector2(56, 14)
		_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status_label.add_theme_font_size_override("font_size", 8)
		add_child(_status_label)


func _update_visuals() -> void:
	var frozen = is_gear_frozen()
	if _visual_rect != null:
		_visual_rect.color = Color(0.3, 0.75, 0.95) if frozen else Color(0.4, 0.45, 0.55)
	if _status_label != null:
		_status_label.text = "[*] FROZEN" if frozen else "(o) SLIPPING"
