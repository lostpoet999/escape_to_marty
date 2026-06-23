class_name BallDamageLabel extends CanvasLayer

const LABEL_FONT: FontFile = preload("res://label_settings_and_fonts/fonts/PressStart2P-Regular.ttf")
const LABEL_LAYER: int = 100
const PLAY_AREA_LEFT: float = 281.0
const LABEL_MARGIN: float = 24.0
const LABEL_FONT_SIZE: int = 12
const LABEL_IDLE_ALPHA: float = 0.6
const LABEL_COLOR: Color = Color(1, 0.9, 0.4)
const LABEL_PULSE_AMPLITUDE: float = 0.03
const LABEL_PULSE_SECONDS: float = 2.6
const LABEL_WOBBLE_RADIANS: float = 0.03
const LABEL_WOBBLE_SECONDS: float = 1.7
const LABEL_FLASH_INTERVAL: float = 8.0
const LABEL_FLASH_SECONDS: float = 0.35
const LABEL_FLASH_GLOW_SIZE: int = 8

var _box: VBoxContainer
var _label: Label
var _animation_time: float = 0.0
var _shown_damage: float = -1.0

func _ready() -> void:
	layer = LABEL_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_label()

func _build_label() -> void:
	_box = VBoxContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_box.grow_horizontal = Control.GROW_DIRECTION_END
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.offset_left = PLAY_AREA_LEFT + LABEL_MARGIN
	_box.offset_bottom = -LABEL_MARGIN
	_box.modulate.a = LABEL_IDLE_ALPHA
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_label = Label.new()
	_label.add_theme_font_override("font", LABEL_FONT)
	_label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	_label.add_theme_color_override("font_color", LABEL_COLOR)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_label)

func _process(delta: float) -> void:
	_box.visible = _should_show()
	if not _box.visible:
		return
	_refresh_text()
	_animation_time += delta
	_box.pivot_offset = _box.size / 2.0
	var pulse: float = 1.0 + sin(TAU * _animation_time / LABEL_PULSE_SECONDS) * LABEL_PULSE_AMPLITUDE
	_box.scale = Vector2.ONE * pulse
	_box.rotation = sin(TAU * _animation_time / LABEL_WOBBLE_SECONDS) * LABEL_WOBBLE_RADIANS
	_animate_flash()

func _refresh_text() -> void:
	var damage: float = PlayerInventory.get_instance().get_ball_damage()
	if damage == _shown_damage:
		return
	_shown_damage = damage
	_label.text = "Ball Damage: %s" % snappedf(damage, 0.01)

func _animate_flash() -> void:
	var time_into_flash: float = fmod(_animation_time, LABEL_FLASH_INTERVAL)
	if time_into_flash >= LABEL_FLASH_SECONDS:
		_label.add_theme_color_override("font_color", LABEL_COLOR)
		_label.add_theme_constant_override("outline_size", 0)
		return
	var flash: float = sin(PI * time_into_flash / LABEL_FLASH_SECONDS)
	_label.add_theme_color_override("font_color", LABEL_COLOR.lerp(Color.WHITE, flash))
	_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, flash))
	_label.add_theme_constant_override("outline_size", int(round(flash * LABEL_FLASH_GLOW_SIZE)))

func _should_show() -> bool:
	return PlayerInventory.instance != null
