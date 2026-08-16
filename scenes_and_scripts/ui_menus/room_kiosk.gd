class_name RoomKiosk extends Node2D

const CLICK_STATES: Array[GameManager.GameState] = [
	GameManager.GameState.CLICK_MODE,
	GameManager.GameState.LEVEL_CLEARED,
	GameManager.GameState.SPECIAL_ROOM,
]

const LABEL_SETTINGS: LabelSettings = preload("res://label_settings_and_fonts/popup_title_32.tres")
const LABEL_PREFIX_COLOR: Color = ApolloPalette.TEXT_HOVER
const LABEL_BOTTOM: float = -152.0

const DRAW_SIZE: float = 192.0
const OUTLINE_COLOR: Color = ApolloPalette.TEXT_HOVER
const OUTLINE_SCREEN_PIXELS: float = 3.0
const BREATHE_GROW: float = 1.04
const BREATHE_SECONDS: float = 1.4
const SHAKE_INTERVAL_MIN: float = 5.0
const SHAKE_INTERVAL_MAX: float = 10.0
const SHAKE_ANGLE_DEG: float = 5.0
const SHAKE_STEP_SECONDS: float = 0.05
const SHAKE_WOBBLES: int = 5

signal activated

@onready var kiosk_button: TextureButton = $KioskButton
@onready var kiosk_label: RichTextLabel = $KioskLabel

var draw_size: float = DRAW_SIZE

var _rest_scale: Vector2
var _hover_outline: TextureRect

func _ready() -> void:
	kiosk_button.set_meta(&"click_pickable", true)
	_fit_button()
	_build_hover_outline()
	_style_label()
	_start_breathe()
	_queue_shake()

func _build_hover_outline() -> void:
	if kiosk_button.texture_hover != null:
		return
	var art: Vector2 = kiosk_button.texture_normal.get_size()
	_hover_outline = TextureRect.new()
	_hover_outline.texture = kiosk_button.texture_normal
	_hover_outline.self_modulate = OUTLINE_COLOR
	_hover_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_outline.show_behind_parent = true
	_hover_outline.visible = false
	_hover_outline.size = art
	_hover_outline.pivot_offset = art * 0.5
	var bleed: float = OUTLINE_SCREEN_PIXELS / _rest_scale.x
	_hover_outline.scale = Vector2.ONE * (1.0 + bleed * 2.0 / art.x)
	kiosk_button.add_child(_hover_outline)
	kiosk_button.mouse_entered.connect(_set_hover_outline.bind(true))
	kiosk_button.mouse_exited.connect(_set_hover_outline.bind(false))

func _set_hover_outline(shown: bool) -> void:
	_hover_outline.visible = shown

func _style_label() -> void:
	kiosk_label.add_theme_font_override(&"normal_font", LABEL_SETTINGS.font)
	kiosk_label.add_theme_font_size_override(&"normal_font_size", LABEL_SETTINGS.font_size)
	kiosk_label.add_theme_color_override(&"default_color", LABEL_SETTINGS.font_color)
	kiosk_label.add_theme_constant_override(&"outline_size", LABEL_SETTINGS.outline_size)
	kiosk_label.add_theme_color_override(&"font_outline_color", LABEL_SETTINGS.outline_color)
	kiosk_label.text = _split_at_colon(kiosk_label.text)
	kiosk_label.resized.connect(_pin_label)
	_pin_label()

func _split_at_colon(raw: String) -> String:
	var colon: int = raw.find(":")
	if colon < 0:
		return "[center]%s[/center]" % raw
	var prefix: String = raw.substr(0, colon + 1)
	var rest: String = raw.substr(colon + 1)
	return "[center][color=#%s]%s[/color]%s[/center]" % [LABEL_PREFIX_COLOR.to_html(false), prefix, rest]

func _pin_label() -> void:
	kiosk_label.position.y = LABEL_BOTTOM - kiosk_label.size.y

func _fit_button() -> void:
	var art: Vector2 = kiosk_button.texture_normal.get_size()
	kiosk_button.size = art
	kiosk_button.position = -art * 0.5
	kiosk_button.pivot_offset = art * 0.5
	_rest_scale = Vector2.ONE * maxf(1.0, roundf(draw_size / art.x))
	kiosk_button.scale = _rest_scale

func _start_breathe() -> void:
	var breathe: Tween = kiosk_button.create_tween().set_loops()
	breathe.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(kiosk_button, "scale", _rest_scale * BREATHE_GROW, BREATHE_SECONDS)
	breathe.tween_property(kiosk_button, "scale", _rest_scale, BREATHE_SECONDS)

func _queue_shake() -> void:
	var shake: Tween = kiosk_button.create_tween()
	shake.set_trans(Tween.TRANS_SINE)
	shake.tween_interval(randf_range(SHAKE_INTERVAL_MIN, SHAKE_INTERVAL_MAX))
	for i: int in SHAKE_WOBBLES:
		var decay: float = 1.0 - float(i) / float(SHAKE_WOBBLES)
		var angle: float = deg_to_rad(SHAKE_ANGLE_DEG) * decay
		shake.tween_property(kiosk_button, "rotation", angle if i % 2 == 0 else -angle, SHAKE_STEP_SECONDS)
	shake.tween_property(kiosk_button, "rotation", 0.0, SHAKE_STEP_SECONDS)
	shake.tween_callback(_queue_shake)

func _on_kiosk_button_pressed() -> void:
	if GameManager.current_state not in CLICK_STATES:
		return
	activated.emit()
