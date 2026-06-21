class_name ClickModePrompt extends CanvasLayer

const PROMPT_FONT: FontFile = preload("res://label_settings_and_fonts/fonts/PressStart2P-Regular.ttf")
const PROMPT_TEXT_PLAYING: String = "Press <TAB> for click mode"
const PROMPT_TEXT_CLICK_MODE: String = "Press <TAB> to return to paddle"
const PROMPT_LAYER: int = 100
const PROMPT_MARGIN: float = 24.0
const PROMPT_FONT_SIZE: int = 12
const PROMPT_IDLE_ALPHA: float = 0.6
const PROMPT_COLOR_PLAYING: Color = Color(1, 0.9, 0.4)
const PROMPT_COLOR_CLICK_MODE: Color = Color(1, 0.3, 0.3)
const PROMPT_PULSE_AMPLITUDE: float = 0.03
const PROMPT_PULSE_SECONDS: float = 2.6
const PROMPT_WOBBLE_RADIANS: float = 0.03
const PROMPT_WOBBLE_SECONDS: float = 1.7

var _box: VBoxContainer
var _label: Label
var _applied_state: int = -1
var _animation_time: float = 0.0

func _ready() -> void:
	layer = PROMPT_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_prompt()
	_box.visible = false

func _build_prompt() -> void:
	_box = VBoxContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.offset_right = -PROMPT_MARGIN
	_box.offset_bottom = -PROMPT_MARGIN
	_box.modulate.a = PROMPT_IDLE_ALPHA
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_label = Label.new()
	_label.add_theme_font_override("font", PROMPT_FONT)
	_label.add_theme_font_size_override("font_size", PROMPT_FONT_SIZE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_label)

func _process(delta: float) -> void:
	_box.visible = _should_show()
	if not _box.visible:
		return
	_apply_state_style()
	_animation_time += delta
	_box.pivot_offset = _box.size / 2.0
	var pulse: float = 1.0 + sin(TAU * _animation_time / PROMPT_PULSE_SECONDS) * PROMPT_PULSE_AMPLITUDE
	_box.scale = Vector2.ONE * pulse
	_box.rotation = sin(TAU * _animation_time / PROMPT_WOBBLE_SECONDS) * PROMPT_WOBBLE_RADIANS

func _apply_state_style() -> void:
	if GameManager.current_state == _applied_state:
		return
	_applied_state = GameManager.current_state
	if _applied_state == GameManager.GameState.CLICK_MODE:
		_label.text = PROMPT_TEXT_CLICK_MODE
		_label.add_theme_color_override("font_color", PROMPT_COLOR_CLICK_MODE)
	else:
		_label.text = PROMPT_TEXT_PLAYING
		_label.add_theme_color_override("font_color", PROMPT_COLOR_PLAYING)

func _should_show() -> bool:
	if GameManager.current_state != GameManager.GameState.PLAYING and GameManager.current_state != GameManager.GameState.CLICK_MODE:
		return false
	if DialogDirector.focused_active:
		return false
	return get_tree().get_nodes_in_group(&"skip_prompt").is_empty()
