extends RefCounted

## Verification tests for project settings, display configuration,
## input action mappings, controller device bindings, and boot scene initialization per TLF-006.

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
	"echo_reset",
	"confirm",
	"cancel",
	"journal",
	"pause",
	"hint"
]

const GAMEPLAY_ACTIONS: Array[String] = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"interact",
	"watch",
	"ability_next",
	"ability_prev",
	"echo_reset",
	"journal",
	"pause",
	"hint"
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


func _events_conflict(ev1: InputEvent, ev2: InputEvent) -> bool:
	if ev1 is InputEventKey and ev2 is InputEventKey:
		var k1 = ev1.physical_keycode if ev1.physical_keycode != KEY_NONE else ev1.keycode
		var k2 = ev2.physical_keycode if ev2.physical_keycode != KEY_NONE else ev2.keycode
		return k1 == k2 and k1 != KEY_NONE
	elif ev1 is InputEventMouseButton and ev2 is InputEventMouseButton:
		return ev1.button_index == ev2.button_index
	elif ev1 is InputEventJoypadButton and ev2 is InputEventJoypadButton:
		return ev1.button_index == ev2.button_index
	elif ev1 is InputEventJoypadMotion and ev2 is InputEventJoypadMotion:
		var sign1 = 1 if ev1.axis_value > 0 else (-1 if ev1.axis_value < 0 else 0)
		var sign2 = 1 if ev2.axis_value > 0 else (-1 if ev2.axis_value < 0 else 0)
		return ev1.axis == ev2.axis and sign1 == sign2
	return false


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


func test_controller_device_configuration() -> void:
	for action in REQUIRED_ACTIONS:
		var events = InputMap.action_get_events(action)
		for ev in events:
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				_assert_eq(ev.device, -1, "Action '%s' joypad event must use device -1 (All Devices) to support multiple controllers, found device %d" % [action, ev.device])


func test_no_input_binding_conflicts() -> void:
	# 1. Gameplay actions must be pairwise disjoint
	for i in range(GAMEPLAY_ACTIONS.size()):
		var action_a = GAMEPLAY_ACTIONS[i]
		var events_a = InputMap.action_get_events(action_a)
		for j in range(i + 1, GAMEPLAY_ACTIONS.size()):
			var action_b = GAMEPLAY_ACTIONS[j]
			var events_b = InputMap.action_get_events(action_b)

			for ev_a in events_a:
				for ev_b in events_b:
					var conflicts = _events_conflict(ev_a, ev_b)
					_assert_true(not conflicts, "Binding conflict detected between gameplay actions '%s' and '%s': %s clashes with %s" % [action_a, action_b, ev_a.as_text(), ev_b.as_text()])

	# 2. UI navigation actions confirm and cancel must be disjoint
	var confirm_events = InputMap.action_get_events("confirm")
	var cancel_events = InputMap.action_get_events("cancel")
	for ev_c in confirm_events:
		for ev_x in cancel_events:
			var conflicts = _events_conflict(ev_c, ev_x)
			_assert_true(not conflicts, "Binding conflict between UI actions 'confirm' and 'cancel': %s clashes with %s" % [ev_c.as_text(), ev_x.as_text()])

	# 3. Cancel and pause must not share keys (Escape must not pause while cancelling)
	var pause_events = InputMap.action_get_events("pause")
	for ev_x in cancel_events:
		for ev_p in pause_events:
			var conflicts = _events_conflict(ev_x, ev_p)
			_assert_true(not conflicts, "Binding conflict between 'cancel' and 'pause': %s clashes with %s" % [ev_x.as_text(), ev_p.as_text()])


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

		# TLF-037: the placeholder label is gone; Boot routes to the title screen.
		_assert_true(instance.get_node_or_null("Label") == null, "Boot has no placeholder Label")
		_assert_eq((instance.get_script() as Script).resource_path, "res://scripts/core/boot.gd", "Boot runs boot.gd")

		instance.free()


func test_autoloads() -> void:
	# ADR-011 (+ TLF-037): Settings, SaveService, SceneRouter. Autoload names must not be hidden
	# by a class_name (SaveService's class is SaveStore; SceneRouter has none).
	var expected := {
		"Settings": "*res://scripts/settings/settings.gd",
		"SaveService": "*res://scripts/save/save_service.gd",
		"SceneRouter": "*res://scripts/core/scene_router.gd",
	}
	for autoload_name in expected.keys():
		_assert_eq(ProjectSettings.get_setting("autoload/" + autoload_name), expected[autoload_name],
			"autoload %s registered" % autoload_name)
	var tree := Engine.get_main_loop() as SceneTree
	_assert_true(tree.root.has_node("SceneRouter"), "SceneRouter autoload is instantiated under /root")
