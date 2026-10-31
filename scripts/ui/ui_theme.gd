class_name UITheme
extends Theme

## Project-wide UI Theme manager per TLF-040 & ART_BIBLE §8.
## Enforces TLF Pixel Mono, 8/16/24 px integer font sizes, and integer text scaling.

const FONT_PATH := "res://assets/ui/fonts/tlf_pixel_mono.ttf"
const THEME_PATH := "res://scenes/ui/theme/tlf_ui_theme.tres"

const COLOR_BORDER_IDLE := Color(0.2745, 0.3059, 0.3608, 1.0)     # #464E5C
const COLOR_BORDER_ACTIVE := Color(0.2980, 0.8784, 0.8235, 1.0)   # #4CE0D2
const COLOR_BORDER_WARN := Color(0.9216, 0.5412, 0.1569, 1.0)     # #EB8A28
const COLOR_BG_OPAQUE := Color(0.0392, 0.0510, 0.0784, 1.0)       # #0A0D14
const COLOR_BG_ACTIVE := Color(0.0784, 0.1020, 0.1490, 1.0)       # #141A26
const COLOR_TEXT_NORMAL := Color(0.9294, 0.9569, 0.9804, 1.0)     # #EDF4FA
const COLOR_TEXT_MUTED := Color(0.5216, 0.5608, 0.6196, 1.0)      # #858F9E

static var _instance: UITheme = null


func _init() -> void:
	_instance = self
	var args := OS.get_cmdline_args()
	if "--import" in args:
		return
	_setup_theme()
	_connect_settings()


func _make_stylebox(border_color: Color, bg_color: Color, padding: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = border_color
	sb.content_margin_left = padding
	sb.content_margin_top = padding
	sb.content_margin_right = padding
	sb.content_margin_bottom = padding
	return sb


func _setup_theme() -> void:
	var font := load(FONT_PATH) as Font
	if font != null:
		default_font = font
		set_font("font", "Label", font)
		set_font("normal_font", "RichTextLabel", font)
		set_font("font", "Button", font)
		set_font("font", "LineEdit", font)
		set_font("font", "TextEdit", font)
		set_font("font", "TabBar", font)
		set_font("font", "TabContainer", font)

	# Setup type variations
	set_type_variation(&"HeaderMedium", &"Label")
	set_type_variation(&"HeaderLarge", &"Label")

	# Panel & PanelContainer styles per ART_BIBLE §8 (1 px border #464E5C, fill #0A0D14, 4 px padding)
	var sb_idle = _make_stylebox(COLOR_BORDER_IDLE, COLOR_BG_OPAQUE, 4)
	var sb_active = _make_stylebox(COLOR_BORDER_ACTIVE, COLOR_BG_OPAQUE, 4)
	var sb_pressed = _make_stylebox(COLOR_BORDER_ACTIVE, COLOR_BG_ACTIVE, 4)
	var sb_disabled = _make_stylebox(COLOR_BORDER_IDLE.darkened(0.5), COLOR_BG_OPAQUE, 4)

	set_stylebox("panel", "Panel", sb_idle)
	set_stylebox("panel", "PanelContainer", sb_idle)

	# Button styles
	set_stylebox("normal", "Button", sb_idle)
	set_stylebox("hover", "Button", sb_active)
	set_stylebox("pressed", "Button", sb_pressed)
	set_stylebox("focus", "Button", sb_active)
	set_stylebox("disabled", "Button", sb_disabled)
	set_color("font_color", "Button", COLOR_TEXT_NORMAL)
	set_color("font_hover_color", "Button", COLOR_BORDER_ACTIVE)
	set_color("font_focus_color", "Button", COLOR_BORDER_ACTIVE)
	set_color("font_pressed_color", "Button", COLOR_BORDER_ACTIVE)
	set_color("font_disabled_color", "Button", COLOR_TEXT_MUTED)

	# Label & RichTextLabel colors
	set_color("font_color", "Label", COLOR_TEXT_NORMAL)
	set_color("default_color", "RichTextLabel", COLOR_TEXT_NORMAL)

	# TabContainer & TabBar
	set_stylebox("panel", "TabContainer", sb_idle)
	set_stylebox("tab_selected", "TabContainer", sb_active)
	set_stylebox("tab_unselected", "TabContainer", sb_idle)
	set_stylebox("tab_selected", "TabBar", sb_active)
	set_stylebox("tab_unselected", "TabBar", sb_idle)
	set_color("font_selected_color", "TabContainer", COLOR_BORDER_ACTIVE)
	set_color("font_unselected_color", "TabContainer", COLOR_TEXT_MUTED)
	set_color("font_selected_color", "TabBar", COLOR_BORDER_ACTIVE)
	set_color("font_unselected_color", "TabBar", COLOR_TEXT_MUTED)

	# Apply initial font sizes based on current Settings if available
	var scale_mult := 1
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var settings = tree.root.get_node_or_null("Settings")
		if settings != null and "text_scale" in settings:
			scale_mult = 2 if settings.text_scale >= 1.5 else 1

	apply_scale_multiplier(scale_mult)


func apply_scale_multiplier(mult: int) -> void:
	default_font_size = 8 * mult
	set_font_size("font_size", "Label", 8 * mult)
	set_font_size("font_size", "Button", 8 * mult)
	set_font_size("normal_font_size", "RichTextLabel", 8 * mult)
	set_font_size("font_size", "RichTextLabel", 8 * mult)
	set_font_size("font_size", "TabBar", 8 * mult)
	set_font_size("font_size", "TabContainer", 8 * mult)
	set_font_size("font_size", "LineEdit", 8 * mult)
	set_font_size("font_size", "TextEdit", 8 * mult)
	set_font_size("font_size", "HeaderMedium", 16 * mult)
	set_font_size("font_size", "HeaderLarge", 24 * mult)
	emit_changed()

	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)


func _connect_settings() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var settings = tree.root.get_node_or_null("Settings")
	if settings != null and settings.has_signal("setting_changed"):
		if not settings.setting_changed.is_connected(_on_setting_changed):
			settings.setting_changed.connect(_on_setting_changed)
		var mult: int = 2 if settings.text_scale >= 1.5 else 1
		apply_scale_multiplier(mult)
	else:
		if not tree.node_added.is_connected(_on_node_added):
			tree.node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node.name == "Settings":
		_connect_settings()


func _on_setting_changed(key: StringName, value: Variant) -> void:
	if key == &"text_scale":
		var mult: int = 2 if float(value) >= 1.5 else 1
		apply_scale_multiplier(mult)


static func ensure_initialized() -> void:
	var th: UITheme = null
	if _instance != null:
		th = _instance
	else:
		var prj = ThemeDB.get_project_theme()
		if prj is UITheme:
			th = prj
			_instance = prj
		else:
			var res = load(THEME_PATH)
			if res is UITheme:
				th = res
				_instance = res
	if th != null:
		if th.default_font == null:
			th._setup_theme()
		th._connect_settings()
