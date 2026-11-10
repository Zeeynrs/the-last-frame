class_name VoiceRecorderCup
extends Interactable

## VoiceRecorderCup (TLF-076 / ADR-025 V6)
## The knocked-over personal voice recorder and coffee cup at x=600 on the floor line.
## Rewind returns it to the bench top at x=540 (Vector2(540, 384)).
## No text; no message on Rewind.
## Relinquishes interact/watch focus after Rewind so bench at x=520 remains focused.

@onready var temporal: TemporalComponent = get_node_or_null("TemporalComponent")

var _is_rewound: bool = false


func _ready() -> void:
	super._ready()
	if temporal == null:
		temporal = get_temporal()
	if temporal != null and not temporal.rewound.is_connected(_on_rewound):
		temporal.rewound.connect(_on_rewound)
	if position.x < 590.0:
		_apply_rewound_state()


func capture_state() -> Dictionary:
	return {
		"position_x": position.x,
		"position_y": position.y,
	}


func apply_state(state: Dictionary) -> void:
	if state.has("position_x") and state.has("position_y"):
		position = Vector2(float(state["position_x"]), float(state["position_y"]))
	if position.x < 590.0:
		_apply_rewound_state()


func _on_rewound(_cursor: int) -> void:
	_apply_rewound_state()


func _apply_rewound_state() -> void:
	_is_rewound = true
	# Relinquish interact/watch focus so bench at x=520 remains targetable from x=500-550
	collision_layer = 0
	collision_mask = 0


func supports_ability(ability_id: StringName) -> bool:
	if _is_rewound:
		return false
	return super.supports_ability(ability_id)


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"
