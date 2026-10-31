class_name DispatchTerminalPresenter
extends Sprite2D

## Visual presenter for dispatch_terminal in Station Atrium (Beat 09).
## Binds to narrative flag ch01.flag.ledger_2359_revealed per ADR-019 / TLF-041.

@export var tex_idle: Texture2D = preload("res://assets/props/ch01/ch01_prop_dispatch_terminal_idle.png")
@export var tex_active: Texture2D = preload("res://assets/props/ch01/ch01_prop_dispatch_terminal_active.png")

const FLAG_ID: StringName = &"ch01.flag.ledger_2359_revealed"

var _target: Node


func _ready() -> void:
	centered = false
	offset = Vector2(-32, -56)
	_target = get_parent()
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var is_active: bool = false
	if _target != null and _target.has_method("get_session"):
		var sess = _target.get_session()
		if sess != null and sess.narrative_state != null:
			is_active = bool(sess.narrative_state.get_flag(FLAG_ID, false))
	if not is_active and is_inside_tree():
		var node = get_tree().root.find_child("GameSession", true, false)
		if node != null and "narrative_state" in node and node.narrative_state != null:
			is_active = bool(node.narrative_state.get_flag(FLAG_ID, false))

	var next_tex: Texture2D = tex_active if is_active else tex_idle
	if texture != next_tex:
		texture = next_tex
