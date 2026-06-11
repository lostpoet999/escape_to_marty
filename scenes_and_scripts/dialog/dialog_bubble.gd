class_name DialogBubble extends Node2D

const REVEAL_CHARACTERS_PER_SECOND: float = 30.0
const ANCHOR_POINT_NODE_NAME: String = "BubbleAnchor"
const MIRROR_X: Transform2D = Transform2D(Vector2(-1, 0), Vector2(0, 1), Vector2.ZERO)
const COLLECTOR_EDGE_MARGIN: float = 24.0
const COLLECTOR_TAIL_OFFSCREEN_REACH: float = 70.0
const COLLECTOR_TAIL_BOW_PIXELS: float = 18.0
const COLLECTOR_TAIL_POINT_COUNT: int = 5
const COLLECTOR_TOP_Y: float = 60.0
const COLLECTOR_SIDE_FALLBACK_Y: float = 350.0
const SCREEN_TOP: float = 0.0
const ADVANCE_BOB_PIXELS: float = 4.0
const ADVANCE_BOB_SECONDS: float = 0.9

@export var pulse_scale_amplitude: float = 0.012
@export var pulse_seconds: float = 2.6
@export var jitter_pixels: float = 1.5
@export var tail_wiggle_pixels: float = 2.5
@export var tail_wiggle_seconds: float = 1.7
@export var left_screen_limit: float = 281.0
@export var right_screen_limit: float = 1920.0
@export var david_text_color: Color = Color(0.4, 0.8, 1)
@export var collector_text_color: Color = Color(1, 0.9, 0.4)
@export var spirit_text_color: Color = Color(0.75, 1, 0.8)
@export var boss_text_color: Color = Color(1, 0.6, 0.6)
@export var collector_panel_color: Color = Color(1, 0.45, 0.45)
@export var panel_opacity: float = 0.5
@export var collector_side_anchor_ys: Array[float] = [210.0, 380.0, 540.0]
@export var collector_top_anchor_fractions: Array[float] = [0.25, 0.5, 0.75]

@onready var dialog_text: Label = $BubblePanel/MarginContainer/DialogText
@onready var bubble_panel: NinePatchRect = $BubblePanel
@onready var tail_line: Line2D = $TailLine
@onready var advance_indicator: Polygon2D = $BubblePanel/AdvanceIndicator

var focused: bool = false

var _anchor: Node2D
var _anchor_point: Node2D
var _collector_mode: bool = false
var _static_origin: Vector2
var _reveal_tween: Tween
var _animation_time: float = 0.0
var _tail_base_points: PackedVector2Array
var _tail_base_transform: Transform2D
var _panel_base_scale: Vector2 = Vector2.ONE
var _panel_base_position: Vector2
var _mirrored: bool = false
var _indicator_base_position: Vector2


func setup(anchor: Node2D) -> void:
	_anchor = anchor
	_anchor_point = anchor.get_node_or_null(ANCHOR_POINT_NODE_NAME) as Node2D
	_collector_mode = false


func setup_collector() -> void:
	_anchor = null
	_anchor_point = null
	_collector_mode = true


func _ready() -> void:
	_make_mouse_transparent()
	_panel_base_scale = bubble_panel.scale
	bubble_panel.pivot_offset = bubble_panel.size / 2.0
	dialog_text.label_settings = dialog_text.label_settings.duplicate()
	if _collector_mode:
		_configure_collector_layout()
	else:
		_panel_base_position = bubble_panel.position
	_tail_base_points = tail_line.points.duplicate()
	_tail_base_transform = tail_line.transform
	_indicator_base_position = advance_indicator.position
	_follow_anchor()
	_update_side()


## The focused tier advances via a full-screen ClickCatcher that sits BEHIND
## the current scene (autoload child); any non-IGNORE Control in the bubble
## would swallow clicks landing on the box before the catcher sees them.
func _make_mouse_transparent() -> void:
	bubble_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in bubble_panel.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_animation_time += delta
	_follow_anchor()
	_update_side()
	_animate_idle_motion()
	_update_advance_indicator()


func show_beat(beat: DialogBeat) -> void:
	_apply_speaker_style(beat.speaker)
	dialog_text.text = beat.text
	dialog_text.visible_ratio = 0.0
	if _reveal_tween:
		_reveal_tween.kill()
	_reveal_tween = create_tween()
	var reveal_seconds: float = maxf(beat.text.length() / REVEAL_CHARACTERS_PER_SECOND, 0.1)
	_reveal_tween.tween_property(dialog_text, "visible_ratio", 1.0, reveal_seconds)


func focus_point() -> Vector2:
	return bubble_panel.global_position + bubble_panel.size * 0.5


func is_reveal_complete() -> bool:
	return dialog_text.visible_ratio >= 1.0


func complete_reveal() -> void:
	if _reveal_tween:
		_reveal_tween.kill()
	dialog_text.visible_ratio = 1.0


func _update_advance_indicator() -> void:
	advance_indicator.visible = focused and is_reveal_complete()
	if advance_indicator.visible:
		var bob: float = sin(TAU * _animation_time / ADVANCE_BOB_SECONDS) * ADVANCE_BOB_PIXELS
		advance_indicator.position = _indicator_base_position + Vector2(0.0, bob)


func _apply_speaker_style(speaker: DialogBeat.Speaker) -> void:
	dialog_text.label_settings.font_color = _speaker_color(speaker)
	var box_tint: Color = collector_panel_color if speaker == DialogBeat.Speaker.COLLECTOR else Color.WHITE
	box_tint.a = panel_opacity
	bubble_panel.self_modulate = box_tint
	tail_line.modulate = box_tint


func _speaker_color(speaker: DialogBeat.Speaker) -> Color:
	match speaker:
		DialogBeat.Speaker.COLLECTOR:
			return collector_text_color
		DialogBeat.Speaker.LINGERING_SPIRIT:
			return spirit_text_color
		DialogBeat.Speaker.BOSS:
			return boss_text_color
		_:
			return david_text_color


func _configure_collector_layout() -> void:
	var panel_size: Vector2 = bubble_panel.size
	_panel_base_position = -panel_size / 2.0
	tail_line.transform = Transform2D.IDENTITY
	var edge: int = randi_range(0, 2)
	var tail_start_global: Vector2
	var tail_end_local: Vector2
	match edge:
		0:
			_static_origin = Vector2(
				left_screen_limit + COLLECTOR_EDGE_MARGIN + panel_size.x / 2.0,
				_pick_side_anchor_y()
			)
			tail_start_global = Vector2(left_screen_limit - COLLECTOR_TAIL_OFFSCREEN_REACH, _static_origin.y)
			tail_end_local = Vector2(-panel_size.x / 2.0 + 10.0, 0.0)
		1:
			_static_origin = Vector2(
				right_screen_limit - COLLECTOR_EDGE_MARGIN - panel_size.x / 2.0,
				_pick_side_anchor_y()
			)
			tail_start_global = Vector2(right_screen_limit + COLLECTOR_TAIL_OFFSCREEN_REACH, _static_origin.y)
			tail_end_local = Vector2(panel_size.x / 2.0 - 10.0, 0.0)
		_:
			_static_origin = Vector2(
				_pick_top_anchor_x(panel_size),
				COLLECTOR_TOP_Y + panel_size.y / 2.0
			)
			tail_start_global = Vector2(_static_origin.x, SCREEN_TOP - COLLECTOR_TAIL_OFFSCREEN_REACH)
			tail_end_local = Vector2(0.0, -panel_size.y / 2.0 + 10.0)
	tail_line.points = _build_collector_tail(tail_start_global - _static_origin, tail_end_local)


func _pick_side_anchor_y() -> float:
	if collector_side_anchor_ys.is_empty():
		return COLLECTOR_SIDE_FALLBACK_Y
	return collector_side_anchor_ys.pick_random() as float


func _pick_top_anchor_x(panel_size: Vector2) -> float:
	var min_x: float = left_screen_limit + COLLECTOR_EDGE_MARGIN + panel_size.x / 2.0
	var max_x: float = right_screen_limit - COLLECTOR_EDGE_MARGIN - panel_size.x / 2.0
	if collector_top_anchor_fractions.is_empty():
		return (min_x + max_x) / 2.0
	var fraction: float = collector_top_anchor_fractions.pick_random() as float
	return clampf(lerpf(left_screen_limit, right_screen_limit, fraction), min_x, max_x)


func _build_collector_tail(start_local: Vector2, end_local: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(COLLECTOR_TAIL_POINT_COUNT)
	var perpendicular: Vector2 = (end_local - start_local).orthogonal().normalized()
	for i: int in range(COLLECTOR_TAIL_POINT_COUNT):
		var progress: float = float(i) / float(COLLECTOR_TAIL_POINT_COUNT - 1)
		var bow: float = sin(PI * progress) * COLLECTOR_TAIL_BOW_PIXELS
		points[i] = start_local.lerp(end_local, progress) + perpendicular * bow
	return points


func _follow_anchor() -> void:
	if _collector_mode:
		global_position = _static_origin + _jitter_offset()
		return
	if is_instance_valid(_anchor_point):
		global_position = _anchor_point.global_position + _jitter_offset()
	elif is_instance_valid(_anchor):
		global_position = _anchor.global_position + _jitter_offset()


func _update_side() -> void:
	if _collector_mode:
		return
	if not _mirrored:
		var left_edge: float = global_position.x + _panel_base_position.x
		if left_edge < left_screen_limit:
			_set_mirrored(true)
	else:
		var right_edge: float = global_position.x - _panel_base_position.x
		if right_edge > right_screen_limit:
			_set_mirrored(false)


func _set_mirrored(mirrored: bool) -> void:
	_mirrored = mirrored
	tail_line.transform = MIRROR_X * _tail_base_transform if mirrored else _tail_base_transform


func _animate_idle_motion() -> void:
	var panel_x: float = _panel_base_position.x
	if _mirrored:
		panel_x = -(_panel_base_position.x + bubble_panel.size.x)
	bubble_panel.position = Vector2(panel_x, _panel_base_position.y)
	if pulse_scale_amplitude > 0.0:
		var pulse: float = 1.0 + sin(TAU * _animation_time / pulse_seconds) * pulse_scale_amplitude
		bubble_panel.scale = _panel_base_scale * pulse
	if tail_wiggle_pixels > 0.0:
		_wiggle_tail()


func _jitter_offset() -> Vector2:
	if jitter_pixels <= 0.0:
		return Vector2.ZERO
	var drift: Vector2 = Vector2(
		sin(_animation_time * 2.3) + sin(_animation_time * 3.7) * 0.5,
		cos(_animation_time * 1.9) + sin(_animation_time * 4.3) * 0.5
	)
	return drift * jitter_pixels * 0.5


func _wiggle_tail() -> void:
	var point_count: int = _tail_base_points.size()
	if point_count < 3:
		return
	var animated: PackedVector2Array = _tail_base_points.duplicate()
	for i: int in range(1, point_count - 1):
		var endpoint_falloff: float = sin(PI * float(i) / float(point_count - 1))
		var phase: float = TAU * _animation_time / tail_wiggle_seconds + float(i) * 0.9
		animated[i] += Vector2(sin(phase), cos(phase * 0.7)) * tail_wiggle_pixels * endpoint_falloff
	tail_line.points = animated
