class_name Interactable
extends Area2D

## Base interactable component per ADR-005 and ADR-006.
## Registers with session IdRegistry and implements interaction contract.

signal focused_changed(is_focused: bool)
signal traced(object_id: StringName)
## Pocket-watch target highlight (ADR-015). Visuals are the HUD's job; this is state only.
signal watch_focused_changed(is_watch_focused: bool, ability_name: StringName)

## Pocket-watch ability interaction ids (ADR-006 clarification, ADR-015).
const ABILITY_TRACE: StringName = &"trace"
const ABILITY_REWIND: StringName = &"rewind"
const ABILITY_FREEZE: StringName = &"freeze"
const ABILITY_FAST_FORWARD: StringName = &"fast_forward"
const WATCH_ABILITIES: Array[StringName] = [ABILITY_TRACE, ABILITY_REWIND, ABILITY_FREEZE, ABILITY_FAST_FORWARD]

@export var object_id: StringName = &""
@export var progression: bool = false
@export var prompt_text: String = "[E] Interact"
@export var session: GameSession
## True when this object carries a residual trace the Trace ability can reveal.
@export var traceable: bool = false

var is_focused: bool = false
var is_watch_focused: bool = false
var watch_ability_name: StringName = &""


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


## First TemporalComponent child, or null when the object has no temporal behaviour.
func get_temporal() -> TemporalComponent:
	for child in get_children():
		if child is TemporalComponent:
			return child as TemporalComponent
	return null


static func is_watch_ability(interaction_id: StringName) -> bool:
	return interaction_id in WATCH_ABILITIES


## Whether a pocket-watch ability can ever apply to this object (used by watch targeting, ADR-015).
func supports_ability(ability_id: StringName) -> bool:
	if ability_id == ABILITY_TRACE:
		return traceable
	var temporal := get_temporal()
	return temporal != null and temporal.supports_ability(ability_id)


## Contract entry point called by InteractionService (ADR-006). Subclasses override
## _can_use() / _can_use_ability() instead of this method.
func can_interact(actor_id: StringName, interaction_id: StringName, payload: Dictionary = {}) -> StringName:
	var temporal := get_temporal()
	if is_watch_ability(interaction_id):
		if not supports_ability(interaction_id):
			return &"unsupported"
		if temporal != null and temporal.is_frozen and interaction_id in [ABILITY_REWIND, ABILITY_FAST_FORWARD]:
			return &"frozen"
		if interaction_id == ABILITY_REWIND and not temporal.can_rewind():
			return &"no_history"
		return _can_use_ability(actor_id, interaction_id, payload)
	if temporal != null and temporal.is_frozen:
		return &"frozen"
	return _can_use(actor_id, interaction_id, payload)


## Contract entry point called by InteractionService after can_interact() allowed it.
func interact(actor_id: StringName, interaction_id: StringName, payload: Dictionary = {}) -> void:
	match interaction_id:
		ABILITY_TRACE:
			traced.emit(object_id)
			_on_traced(actor_id)
		ABILITY_REWIND:
			get_temporal().rewind()
		ABILITY_FREEZE:
			get_temporal().toggle_freeze()
		ABILITY_FAST_FORWARD:
			get_temporal().fast_forward()
		_:
			_on_use(actor_id, interaction_id, payload)


## Override: extra rules for non-ability interactions. Return &"" to allow.
func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &""


## Override: cross-object rules for pocket-watch abilities (e.g. a frozen gear blocking a shutter).
func _can_use_ability(_actor_id: StringName, _ability_id: StringName, _payload: Dictionary) -> StringName:
	return &""


## Override: perform a non-ability interaction.
func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	pass


## Override: react to being traced (reveal visuals, journal hooks).
func _on_traced(_actor_id: StringName) -> void:
	pass


## Called by player when this interactable becomes the closest target.
func set_focused(p_focused: bool) -> void:
	if is_focused != p_focused:
		is_focused = p_focused
		focused_changed.emit(is_focused)
		_on_focus_changed(is_focused)


func _on_focus_changed(_focused: bool) -> void:
	pass


## Called by the pocket watch when this object becomes (or stops being) its target.
func set_watch_focused(p_watch_focused: bool, p_ability_name: StringName = &"") -> void:
	if is_watch_focused == p_watch_focused and watch_ability_name == p_ability_name:
		return
	is_watch_focused = p_watch_focused
	watch_ability_name = p_ability_name
	watch_focused_changed.emit(is_watch_focused, watch_ability_name)
	_on_watch_focus_changed(is_watch_focused, watch_ability_name)


## Override: react to watch targeting (e.g. outline). Default does nothing.
func _on_watch_focus_changed(_focused: bool, _ability_name: StringName) -> void:
	pass

