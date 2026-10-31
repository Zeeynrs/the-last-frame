class_name TestPillar
extends Interactable

## Greybox static pillar per TLF-008 / CH1-PZ-001.
## Non-temporal structural column that returns &"unsupported" for watch abilities.

var _visual_rect: ColorRect = null


func _ready() -> void:
	if prompt_text == "[E] Interact":
		prompt_text = "Support Pillar"
	traceable = false
	super._ready()
	_setup_visuals()


func _setup_visuals() -> void:
	if _visual_rect == null:
		_visual_rect = ColorRect.new()
		_visual_rect.name = "PillarVisual"
		_visual_rect.position = Vector2(-12, -24)
		_visual_rect.size = Vector2(24, 48)
		_visual_rect.color = Color(0.45, 0.45, 0.5)
		add_child(_visual_rect)
