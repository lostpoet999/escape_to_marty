class_name SkipPrompt extends CanvasLayer

signal skip_committed

const SKIP_FONT: FontFile = preload("res://label_settings_and_fonts/fonts/PressStart2P-Regular.ttf")
const HOLD_SECONDS: float = 1.0
const MARGIN: float = 24.0
const BAR_HEIGHT: float = 6.0
const FONT_SIZE: int = 12
const IDLE_ALPHA: float = 0.6
const PROMPT_COLOR: Color = Color(1, 0.9, 0.4)
const PULSE_AMPLITUDE: float = 0.03
const PULSE_SECONDS: float = 2.6
const WOBBLE_RADIANS: float = 0.03
const WOBBLE_SECONDS: float = 1.7
const FLASH_INTERVAL: float = 8.0
const FLASH_SECONDS: float = 0.35
const FLASH_GLOW_SIZE: int = 8

var _animation_time: float = 0.0
var _hold_seconds: float = 0.0
var _prompt_held: bool = false
var _committed: bool = false
var _box: VBoxContainer
var _bar: ColorRect
var _fill: ColorRect
var _label: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box = VBoxContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.offset_right = -MARGIN
	_box.offset_bottom = -MARGIN
	_box.modulate.a = IDLE_ALPHA
	_box.add_to_group(&"skip_prompt")
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_box.gui_input.connect(_on_prompt_gui_input)
	add_child(_box)
	_label = Label.new()
	_label.text = "HOLD TO SKIP [E]"
	_label.add_theme_font_override("font", SKIP_FONT)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", PROMPT_COLOR)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_label)
	_bar = ColorRect.new()
	_bar.color = Color(PROMPT_COLOR, 0.25)
	_bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_bar)
	_fill = ColorRect.new()
	_fill.color = PROMPT_COLOR
	_fill.size = Vector2(0, BAR_HEIGHT)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_fill)


func _process(delta: float) -> void:
	_animation_time += delta
	if _prompt_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_prompt_held = false
	if Input.is_physical_key_pressed(KEY_E) or _prompt_held:
		_hold_seconds += delta
	else:
		_hold_seconds = 0.0
	_update_fill()
	_animate_prompt()
	if _hold_seconds >= HOLD_SECONDS and not _committed:
		_committed = true
		skip_committed.emit()


func _on_prompt_gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		_prompt_held = click.pressed


func _update_fill() -> void:
	if not is_instance_valid(_fill):
		return
	var progress: float = clampf(_hold_seconds / HOLD_SECONDS, 0.0, 1.0)
	_fill.size = Vector2(_bar.size.x * progress, BAR_HEIGHT)
	_box.modulate.a = lerpf(IDLE_ALPHA, 1.0, progress)


func _animate_prompt() -> void:
	if not is_instance_valid(_box):
		return
	_box.pivot_offset = _box.size / 2.0
	var pulse: float = 1.0 + sin(TAU * _animation_time / PULSE_SECONDS) * PULSE_AMPLITUDE
	_box.scale = Vector2.ONE * pulse
	_box.rotation = sin(TAU * _animation_time / WOBBLE_SECONDS) * WOBBLE_RADIANS
	_animate_flash()


func _animate_flash() -> void:
	if not is_instance_valid(_label):
		return
	var time_into_flash: float = fmod(_animation_time, FLASH_INTERVAL)
	if time_into_flash >= FLASH_SECONDS:
		_label.add_theme_color_override("font_color", PROMPT_COLOR)
		_label.add_theme_constant_override("outline_size", 0)
		return
	var flash: float = sin(PI * time_into_flash / FLASH_SECONDS)
	_label.add_theme_color_override("font_color", PROMPT_COLOR.lerp(Color.WHITE, flash))
	_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, flash))
	_label.add_theme_constant_override("outline_size", int(round(flash * FLASH_GLOW_SIZE)))
