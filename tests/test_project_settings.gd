extends RefCounted

## Verification tests for project settings, display configuration,
## input action mappings, and boot scene initialization per TLF-006.

var assert_helper: RefCounted

const REQUIRED_ACTIONS: Array[String] = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"interact",
	"watch",
	"ability_next",
	"ability_prev",
	"confirm",
	"cancel",
	"journal",
	"pause"
]


func _assert_eq(actual, expected, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_eq(actual, expected, msg)
	assert(actual == expected, msg)
	return actual == expected


func _assert_true(cond: bool, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_true(cond, msg)
	assert(cond, msg)
	return cond


func _assert_not_null(val, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_not_null(val, msg)
	assert(val != null, msg)
	return val != null


func test_viewport_and_display_settings() -> void:
	# Viewport internal size 640x360
	_assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 640, "viewport_width must be 640")
	_assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 360, "viewport_height must be 360")

	# Window override 1920x1080
	_assert_eq(ProjectSettings.get_setting("display/window/size/window_width_override"), 1920, "window_width_override must be 1920")
	_assert_eq(ProjectSettings.get_setting("display/window/size/window_height_override"), 1080, "window_height_override must be 1080")

	# Stretch mode, aspect, and integer scale
	_assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport", "stretch/mode must be viewport")
	_assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep", "stretch/aspect must be keep")
	_assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer", "stretch/scale_mode must be integer")

	# Pixel-art rendering: nearest filter and pixel snap
	_assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0, "default_texture_filter must be 0 (Nearest)")
	_assert_eq(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"), true, "snap_2d_transforms_to_pixel must be true")

	# Physics ticks determinism
	_assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 60, "physics_ticks_per_second must be 60")

	# Renderer and physics engine preservation
	_assert_eq(ProjectSettings.get_setting("physics/3d/physics_engine"), "Jolt Physics", "Jolt Physics engine preserved")
	_assert_eq(ProjectSettings.get_setting("rendering/rendering_device/driver.windows"), "d3d12", "D3D12 rendering driver preserved")


func test_input_actions() -> void:
	for action in REQUIRED_ACTIONS:
		var has_action = InputMap.has_action(action)
		_assert_true(has_action, "InputMap must define action '%s'" % action)
		if not has_action:
			continue

		var events = InputMap.action_get_events(action)
		var key_event_count: int = 0
		var joy_event_count: int = 0

		for ev in events:
			if ev is InputEventKey or ev is InputEventMouseButton:
				key_event_count += 1
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				joy_event_count += 1

		_assert_true(key_event_count >= 1, "Action '%s' must have at least 1 keyboard/mouse event (found %d)" % [action, key_event_count])
		_assert_true(joy_event_count >= 1, "Action '%s' must have at least 1 joypad event (found %d)" % [action, joy_event_count])


func test_main_scene() -> void:
	var main_scene_path = ProjectSettings.get_setting("application/run/main_scene")
	_assert_eq(main_scene_path, "res://scenes/boot/Boot.tscn", "main_scene must point to res://scenes/boot/Boot.tscn")
	_assert_true(ResourceLoader.exists(main_scene_path), "Boot scene file must exist at path")

	var scene = load(main_scene_path)
	_assert_not_null(scene, "Boot scene resource must load")

	if scene is PackedScene:
		var instance = scene.instantiate()
		_assert_not_null(instance, "Boot scene must instantiate")
		_assert_true(instance is Control, "Boot scene root must be a Control node")

		var label = instance.get_node_or_null("Label")
		_assert_not_null(label, "Boot scene must contain a Label node")
		if label is Label:
			_assert_eq(label.text, "THE LAST FRAME — boot", "Label text must be 'THE LAST FRAME — boot'")

		instance.free()
