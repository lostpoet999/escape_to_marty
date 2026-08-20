class_name ApolloPalette extends RefCounted

const TEXT_GOLD: Color = Color("#e8c170")
const TEXT_HOVER: Color = Color("#ebede9")
const TEXT_ACCENT: Color = Color("#de9e41")
const TEXT_DISABLED: Color = Color("#577277")
const TEXT_OUTLINE: Color = Color("#10141f")
const PANEL_BACKGROUND: Color = Color("#151d28")
const BUTTON_FILL: Color = Color("#202e37")
const BUTTON_FILL_PRESSED: Color = Color("#394a50")
const BUTTON_BORDER: Color = Color("#a8b5b2")
const BUTTON_BORDER_HOVER: Color = Color("#c7cfcc")
const BUTTON_BORDER_DISABLED: Color = Color("#577277")

const POPUP_FONT: FontFile = preload("res://label_settings_and_fonts/fonts/PressStart2P-Regular.ttf")
const FONT_SIZE_TITLE: int = 32
const FONT_SIZE_BODY: int = 16
const FONT_SIZE_SMALL: int = 10

const BUTTON_BORDER_WIDTH: int = 4
const BUTTON_CORNER_RADIUS: int = 10
const BUTTON_CONTENT_MARGIN: float = 8.0

const SMALL_BUTTON_BORDER_WIDTH: int = 2
const SMALL_BUTTON_CORNER_RADIUS: int = 6
const SMALL_BUTTON_CONTENT_MARGIN: float = 4.0

const POPUP_OPEN_SECONDS: float = 0.18
const POPUP_OPEN_START_SCALE: float = 0.9
const POPUP_BREATHE_SCALE: float = 1.008
const POPUP_BREATHE_SECONDS: float = 1.3

const SHAKE_ANGLE_DEG: float = 5.0
const SHAKE_STEP_SECONDS: float = 0.05
const SHAKE_WOBBLES: int = 5
const IDLE_SHAKE_META: StringName = &"idle_shake_tween"

static func style_menu_button(button: Button) -> void:
	button.flat = false
	button.add_theme_font_override(&"font", POPUP_FONT)
	button.add_theme_font_size_override(&"font_size", FONT_SIZE_BODY)
	button.add_theme_color_override(&"font_color", TEXT_GOLD)
	button.add_theme_color_override(&"font_hover_color", TEXT_HOVER)
	button.add_theme_color_override(&"font_pressed_color", TEXT_GOLD)
	button.add_theme_color_override(&"font_focus_color", TEXT_GOLD)
	button.add_theme_color_override(&"font_disabled_color", TEXT_DISABLED)
	button.add_theme_stylebox_override(&"normal", _menu_box(BUTTON_FILL, BUTTON_BORDER))
	button.add_theme_stylebox_override(&"hover", _menu_box(BUTTON_FILL, BUTTON_BORDER_HOVER))
	button.add_theme_stylebox_override(&"pressed", _menu_box(BUTTON_FILL_PRESSED, BUTTON_BORDER_HOVER))
	button.add_theme_stylebox_override(&"focus", _menu_box(Color(BUTTON_FILL.r, BUTTON_FILL.g, BUTTON_FILL.b, 0.0), BUTTON_BORDER_HOVER))
	button.add_theme_stylebox_override(&"disabled", _menu_box(BUTTON_FILL, BUTTON_BORDER_DISABLED))

static func style_small_menu_button(button: Button) -> void:
	style_menu_button(button)
	button.add_theme_font_size_override(&"font_size", FONT_SIZE_SMALL)
	button.add_theme_stylebox_override(&"normal", _small_box(BUTTON_FILL, BUTTON_BORDER))
	button.add_theme_stylebox_override(&"hover", _small_box(BUTTON_FILL, BUTTON_BORDER_HOVER))
	button.add_theme_stylebox_override(&"pressed", _small_box(BUTTON_FILL_PRESSED, BUTTON_BORDER_HOVER))
	button.add_theme_stylebox_override(&"focus", _small_box(Color(BUTTON_FILL.r, BUTTON_FILL.g, BUTTON_FILL.b, 0.0), BUTTON_BORDER_HOVER))
	button.add_theme_stylebox_override(&"disabled", _small_box(BUTTON_FILL, BUTTON_BORDER_DISABLED))

static func make_open_tween(popup: Control, during_pause: bool) -> Tween:
	popup.pivot_offset = _popup_pivot(popup)
	popup.scale = Vector2.ONE * POPUP_OPEN_START_SCALE
	popup.modulate.a = 0.0
	var tween: Tween = popup.create_tween()
	if during_pause:
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(popup, "scale", Vector2.ONE, POPUP_OPEN_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "modulate:a", 1.0, POPUP_OPEN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween

static func make_breathe_tween(popup: Control, during_pause: bool) -> Tween:
	popup.pivot_offset = _popup_pivot(popup)
	var tween: Tween = popup.create_tween()
	if during_pause:
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_loops()
	tween.tween_property(popup, "scale", Vector2.ONE * POPUP_BREATHE_SCALE, POPUP_BREATHE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(popup, "scale", Vector2.ONE, POPUP_BREATHE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween

static func start_idle_shake(control: Control, interval_min: float, interval_max: float, first_delay: float) -> void:
	stop_idle_shake(control)
	_queue_idle_shake(control, first_delay, interval_min, interval_max)

static func stop_idle_shake(control: Control) -> void:
	if control.has_meta(IDLE_SHAKE_META):
		var running: Tween = control.get_meta(IDLE_SHAKE_META) as Tween
		if running != null and running.is_valid():
			running.kill()
		control.remove_meta(IDLE_SHAKE_META)
	control.rotation = 0.0

static func _queue_idle_shake(control: Control, delay: float, interval_min: float, interval_max: float) -> void:
	if not is_instance_valid(control) or not control.is_inside_tree():
		return
	var tween: Tween = control.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_interval(delay)
	tween.tween_callback(_center_pivot.bind(control))
	for i: int in SHAKE_WOBBLES:
		var decay: float = 1.0 - float(i) / float(SHAKE_WOBBLES)
		var angle: float = deg_to_rad(SHAKE_ANGLE_DEG) * decay
		tween.tween_property(control, "rotation", angle if i % 2 == 0 else -angle, SHAKE_STEP_SECONDS)
	tween.tween_property(control, "rotation", 0.0, SHAKE_STEP_SECONDS)
	tween.tween_callback(_requeue_idle_shake.bind(control, interval_min, interval_max))
	control.set_meta(IDLE_SHAKE_META, tween)

static func _requeue_idle_shake(control: Control, interval_min: float, interval_max: float) -> void:
	_queue_idle_shake(control, randf_range(interval_min, interval_max), interval_min, interval_max)

static func _center_pivot(control: Control) -> void:
	control.pivot_offset = control.size / 2.0

static func _popup_pivot(popup: Control) -> Vector2:
	if popup.size != Vector2.ZERO:
		return popup.size / 2.0
	for child: Node in popup.get_children():
		if child is Control:
			var rect: Rect2 = (child as Control).get_rect()
			return rect.get_center()
	return Vector2.ZERO

static func reset_popup(popup: Control) -> void:
	popup.scale = Vector2.ONE
	popup.modulate.a = 1.0

static func _menu_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.set_border_width_all(BUTTON_BORDER_WIDTH)
	box.border_color = border
	box.set_corner_radius_all(BUTTON_CORNER_RADIUS)
	box.set_content_margin_all(BUTTON_CONTENT_MARGIN)
	return box

static func _small_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.set_border_width_all(SMALL_BUTTON_BORDER_WIDTH)
	box.border_color = border
	box.set_corner_radius_all(SMALL_BUTTON_CORNER_RADIUS)
	box.set_content_margin_all(SMALL_BUTTON_CONTENT_MARGIN)
	return box
