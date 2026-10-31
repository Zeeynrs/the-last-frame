class_name TestShutter
extends Interactable

## Greybox vertical fire shutter per TLF-008 / CH1-PZ-002.
## Demonstrates Rewind to pre-arrival hold timer, countdown halted by frozen coupled gear,
## and discrete history commit upon timer expiration.

signal shutter_state_changed(shutter_state: StringName, hold_ticks: int, passage_blocked: bool)

@export var shutter_state: StringName = &"closed"
@export var hold_ticks: int = 0
@export var passage_blocked: bool = true
@export var gear: TestGear = null
@export var gear_id: StringName = &"ch01.test.gear"

var temporal: TemporalComponent
var _last_tick: int = -1

var _visual_rect: ColorRect = null
var _status_label: Label = null


func _ready() -> void:
	if prompt_text == "[E] Interact":
		prompt_text = "Fire Shutter"

	_setup_temporal()
	super._ready()
	_setup_visuals()
	_update_visuals()

	var sess = get_session()
	if sess != null and sess.sim_clock != null:
		sess.sim_clock.tick_advanced.connect(_on_sim_clock_tick)
		_last_tick = sess.sim_clock.tick


func _setup_temporal() -> void:
	temporal = get_temporal_component()
	if temporal == null:
		temporal = TemporalComponent.new()
		temporal.name = "TemporalComponent"
		temporal.capabilities = TemporalComponent.Capability.REWIND
		temporal.schema_version = 1
		temporal.state_fields = ["shutter_state", "hold_ticks", "passage_blocked"]
		var h: Array[Dictionary] = [
			{"shutter_state": &"raised", "hold_ticks": 180, "passage_blocked": false}
		]
		temporal.initial_history = h
		add_child(temporal)
		if not temporal.is_inside_tree():
			temporal.init_history()


func capture_state() -> Dictionary:
	return {
		"shutter_state": shutter_state,
		"hold_ticks": hold_ticks,
		"passage_blocked": passage_blocked,
	}


func apply_state(d: Dictionary) -> void:
	shutter_state = d["shutter_state"]
	hold_ticks = d["hold_ticks"]
	passage_blocked = d["passage_blocked"]

	var sess = get_session()
	if sess != null and sess.sim_clock != null:
		_last_tick = sess.sim_clock.tick

	_update_visuals()
	shutter_state_changed.emit(shutter_state, hold_ticks, passage_blocked)


func is_coupled_gear_frozen() -> bool:
	if gear == null:
		var sess = get_session()
		if sess != null and sess.id_registry != null:
			gear = sess.id_registry.resolve(gear_id) as TestGear
	return gear != null and gear.is_gear_frozen()


func can_interact(actor_id: StringName, interaction_id: StringName, payload: Dictionary = {}) -> StringName:
	if interaction_id == &"rewind":
		if is_coupled_gear_frozen():
			return &"frozen"
		if shutter_state == &"raised":
			return &"no_history"
	elif interaction_id == &"freeze":
		return &"unsupported"
	elif interaction_id == &"use":
		return &"jammed"

	return super.can_interact(actor_id, interaction_id, payload)


func _on_sim_clock_tick(current_tick: int) -> void:
	if _last_tick < 0:
		_last_tick = current_tick
		return

	var delta_ticks = current_tick - _last_tick
	_last_tick = current_tick

	if delta_ticks <= 0:
		return

	if shutter_state == &"raised" and not is_coupled_gear_frozen():
		if delta_ticks >= hold_ticks:
			hold_ticks = 0
			shutter_state = &"closed"
			passage_blocked = true
			_update_visuals()
			shutter_state_changed.emit(shutter_state, hold_ticks, passage_blocked)
			var tc = get_temporal_component()
			if tc != null:
				tc.commit_history()
		else:
			hold_ticks -= delta_ticks
			_update_visuals()
			shutter_state_changed.emit(shutter_state, hold_ticks, passage_blocked)


func _setup_visuals() -> void:
	if _visual_rect == null:
		_visual_rect = ColorRect.new()
		_visual_rect.name = "ShutterVisual"
		_visual_rect.position = Vector2(-20, -20)
		_visual_rect.size = Vector2(40, 40)
		add_child(_visual_rect)

	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = "ShutterStatus"
		_status_label.position = Vector2(-36, -34)
		_status_label.size = Vector2(72, 14)
		_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status_label.add_theme_font_size_override("font_size", 8)
		add_child(_status_label)


func _update_visuals() -> void:
	if _visual_rect != null:
		_visual_rect.color = Color(0.85, 0.3, 0.2) if passage_blocked else Color(0.2, 0.7, 0.9)
	if _status_label != null:
		if passage_blocked:
			_status_label.text = "[LOCKED] CLOSED"
		else:
			_status_label.text = "[OPEN] (%d)" % hold_ticks
