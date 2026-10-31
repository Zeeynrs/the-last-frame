class_name Interactable
extends Area2D

## Base interactable component per ADR-005, ADR-006, and ADR-007.
## Registers with session IdRegistry, delegates temporal abilities to TemporalComponent,
## and implements interaction and targeting contracts.

signal focused_changed(is_focused: bool)
signal watch_focused_changed(is_watch_focused: bool, ability_name: StringName)
signal traced(object_id: StringName)

@export var object_id: StringName = &""
@export var progression: bool = false
@export var prompt_text: String = "[E] Interact"
@export var traceable: bool = false
@export var session: GameSession

var is_focused: bool = false
var is_watch_focused: bool = false
var watch_ability_name: StringName = &""
var _watch_label: Label = null


func _enter_tree() -> void:
	add_to_group(&"interactable")


func _ready() -> void:
	if String(object_id).is_empty():
		push_error("Interactable '%s' has an empty object_id." % name)
		return
	_register_with_session()


func _exit_tree() -> void:
	if not String(object_id).is_empty():
		_unregister_from_session()


## Locates the active GameSession via direct reference, ancestor hierarchy, or tree group.
func get_session() -> GameSession:
	if session != null:
		return session

	var p = get_parent()
	while p != null:
		if p is GameSession:
			return p as GameSession
		if p.is_in_group(&"game_session") and "id_registry" in p:
			return p as GameSession
		p = p.get_parent()

	if is_inside_tree():
		var tree = get_tree()
		if tree != null:
			var found = tree.get_first_node_in_group(&"game_session")
			if found != null:
				return found as GameSession

	return null


func _register_with_session() -> void:
	var sess = get_session()
	if sess == null or sess.id_registry == null:
		push_error("Interactable '%s' (%s) could not find GameSession with IdRegistry." % [name, object_id])
		return
	sess.id_registry.register(object_id, self)


func _unregister_from_session() -> void:
	var sess = get_session()
	if sess != null and sess.id_registry != null:
		sess.id_registry.unregister(object_id, self)


## Finds the child TemporalComponent if one exists.
func get_temporal_component() -> TemporalComponent:
	for child in get_children():
		if child is TemporalComponent:
			return child
	return null


## Queries whether this interactable supports the requested watch ability.
func supports_ability(ability_id: StringName) -> bool:
	if ability_id == &"trace":
		return traceable
	var tc = get_temporal_component()
	if tc != null:
		return tc.supports_ability(ability_id)
	return false


## Check if the actor can interact. Delegates temporal abilities per ADR-006 & ADR-007.
func can_interact(_actor_id: StringName, interaction_id: StringName, _payload: Dictionary = {}) -> StringName:
	var tc = get_temporal_component()
	match interaction_id:
		&"use":
			if tc != null and tc.is_frozen:
				return &"frozen"
			return &""
		&"trace":
			if traceable:
				return &""
			return &"unsupported"
		&"rewind":
			if tc == null or not tc.supports_ability(&"rewind"):
				return &"unsupported"
			if tc.is_frozen:
				return &"frozen"
			if tc.get_history_cursor() <= 0:
				return &"no_history"
			return &""
		&"freeze":
			if tc == null or not tc.supports_ability(&"freeze"):
				return &"unsupported"
			return &""
		&"fast_forward":
			if tc == null or not tc.supports_ability(&"fast_forward"):
				return &"unsupported"
			if tc.is_frozen:
				return &"frozen"
			return &""
		_:
			return &""


## Execute the interaction.
func interact(_actor_id: StringName, interaction_id: StringName, _payload: Dictionary = {}) -> void:
	var tc = get_temporal_component()
	match interaction_id:
		&"trace":
			if traceable:
				traced.emit(object_id)
		&"rewind":
			if tc != null:
				tc.rewind()
		&"freeze":
			if tc != null:
				tc.toggle_freeze()


## Called by player when this interactable becomes the closest target for physical interaction.
func set_focused(p_focused: bool) -> void:
	if is_focused != p_focused:
		is_focused = p_focused
		focused_changed.emit(is_focused)
		_on_focus_changed(is_focused)


func _on_focus_changed(_focused: bool) -> void:
	pass


## Called by pocket watch when this interactable becomes the active watch target.
func set_watch_focused(p_watch_focused: bool, p_ability_name: StringName = &"") -> void:
	if is_watch_focused != p_watch_focused or watch_ability_name != p_ability_name:
		is_watch_focused = p_watch_focused
		watch_ability_name = p_ability_name
		watch_focused_changed.emit(is_watch_focused, watch_ability_name)
		_update_watch_visuals()


func _update_watch_visuals() -> void:
	if is_watch_focused:
		if _watch_label == null:
			_watch_label = Label.new()
			_watch_label.name = "WatchHighlightLabel"
			_watch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_watch_label.position = Vector2(-40, -40)
			_watch_label.size = Vector2(80, 20)
			_watch_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
			_watch_label.add_theme_font_size_override("font_size", 9)
			add_child(_watch_label)
		_watch_label.text = "[Q: %s]" % String(watch_ability_name).to_upper()
		_watch_label.visible = true
	else:
		if _watch_label != null:
			_watch_label.visible = false
	queue_redraw()


func _draw() -> void:
	if is_watch_focused:
		draw_rect(Rect2(-12, -12, 24, 24), Color(0.9, 0.8, 0.2, 0.8), false, 1.5)

