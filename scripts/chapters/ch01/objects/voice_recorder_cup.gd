class_name VoiceRecorderCup
extends Interactable

## VoiceRecorderCup (TLF-076 / ADR-025 V6)
## The knocked-over personal voice recorder and coffee cup at x=600 on the floor line.
## Rewind returns it to the bench top at x=540 (Vector2(540, 384)).
## No text; provides short feedback with existing key on Rewind.

@onready var temporal: TemporalComponent = get_node_or_null("TemporalComponent")


func _ready() -> void:
	super._ready()
	if temporal == null:
		temporal = get_temporal()
	if temporal != null and not temporal.rewound.is_connected(_on_rewound):
		temporal.rewound.connect(_on_rewound)


func capture_state() -> Dictionary:
	return {
		"position_x": position.x,
		"position_y": position.y,
	}


func apply_state(state: Dictionary) -> void:
	if state.has("position_x") and state.has("position_y"):
		position = Vector2(float(state["position_x"]), float(state["position_y"]))


func _on_rewound(_cursor: int) -> void:
	var hud := _find_hud()
	if hud != null and hud.has_method("show_message"):
		hud.show_message(tr("ABILITY_REWIND"), 2.0)


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"


func _find_hud() -> Node:
	if not is_inside_tree():
		return null
	var candidate := get_tree().root.find_child("HUD", true, false)
	return candidate
