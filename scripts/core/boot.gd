extends Control

## Boot (TLF-037): main scene. Makes sure translations and Settings are loaded, then routes to
## the title screen (deferred, so the scene change happens after Boot finished entering).

signal routed()


func _ready() -> void:
	UIFeedback.init_translations()
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		push_warning("Boot: Settings autoload missing; continuing with defaults.")
	_route_to_title.call_deferred()


func _route_to_title() -> void:
	var router := get_node_or_null("/root/SceneRouter")
	if router == null:
		push_error("Boot: SceneRouter autoload missing; cannot open the title screen.")
		return
	router.return_to_title()
	routed.emit()
