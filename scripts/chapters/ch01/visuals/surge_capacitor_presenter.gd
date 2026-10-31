class_name SurgeCapacitorPresenter
extends Sprite2D

## Visual presenter for SurgeCapacitor (CH1-PZ-004).
## State mapping lives in state_textures as data per ADR-019 / TLF-041.

@export var state_textures: Dictionary = {
	"discharged": preload("res://assets/props/ch01/ch01_prop_surge_capacitor_discharged.png"),
	"charged": preload("res://assets/props/ch01/ch01_prop_surge_capacitor_charged.png"),
	"frozen": preload("res://assets/props/ch01/ch01_prop_surge_capacitor_frozen.png"),
}

var _target: SurgeCapacitor


func _ready() -> void:
	centered = false
	offset = Vector2(-32, -56)
	_target = get_parent() as SurgeCapacitor
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func resolve_state_key(charge_state: StringName, is_frozen: bool) -> String:
	if is_frozen:
		var split_key := "frozen_%s" % String(charge_state)
		if state_textures.has(split_key):
			return split_key
		return "frozen"
	return String(charge_state)


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as SurgeCapacitor
	if _target == null:
		return
	var is_frozen: bool = _target.has_method("is_frozen") and _target.is_frozen()
	var key := resolve_state_key(_target.charge_state, is_frozen)
	var next_tex: Texture2D = state_textures.get(key, state_textures.get("discharged"))
	if texture != next_tex:
		texture = next_tex
