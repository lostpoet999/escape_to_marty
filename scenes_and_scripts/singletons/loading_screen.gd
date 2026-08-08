extends CanvasLayer

const LABEL_SETTINGS: LabelSettings = preload("uid://dx3lg2g7p81op")
const LOADING_TEXT: String = "loading..."
const FONT_SIZE: int = 48
const FADE_TIME: float = 0.35
const MIN_HOLD_TIME: float = 0.45
const FAILSAFE_TIME: float = 8.0
const CURTAIN_LAYER: int = 128

var _backdrop: ColorRect
var _label: Label
var _failsafe: Timer
var _fade_tween: Tween
var _raised: bool = false
var _lowering: bool = false
var _raised_at_msec: int = 0

func _ready() -> void:
	layer = CURTAIN_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_curtain()
	_build_failsafe()
	visible = false

func _build_curtain() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color.BLACK
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var settings: LabelSettings = LABEL_SETTINGS.duplicate() as LabelSettings
	settings.font_size = FONT_SIZE
	_label = Label.new()
	_label.text = LOADING_TEXT
	_label.label_settings = settings
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _build_failsafe() -> void:
	_failsafe = Timer.new()
	_failsafe.one_shot = true
	_failsafe.timeout.connect(_on_failsafe_timeout)
	add_child(_failsafe)

func is_raised() -> bool:
	return _raised

func raise() -> void:
	_lowering = false
	if _raised:
		_failsafe.start(FAILSAFE_TIME)
		return
	_raised = true
	_raised_at_msec = Time.get_ticks_msec()
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_backdrop.modulate.a = 1.0
	visible = true
	_failsafe.start(FAILSAFE_TIME)

func lower() -> void:
	if not _raised or _lowering:
		return
	_lowering = true
	await RenderingServer.frame_post_draw
	if not _lowering:
		return
	_start_fade_out()

func _on_failsafe_timeout() -> void:
	push_warning("LoadingScreen: room never reported ready, lowering after %.1fs" % FAILSAFE_TIME)
	_start_fade_out()

func _start_fade_out() -> void:
	if not _raised:
		return
	_raised = false
	_lowering = false
	_failsafe.stop()
	var held: float = float(Time.get_ticks_msec() - _raised_at_msec) / 1000.0
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var remaining_hold: float = maxf(0.0, MIN_HOLD_TIME - held)
	if remaining_hold > 0.0:
		_fade_tween.tween_interval(remaining_hold)
	_fade_tween.tween_property(_backdrop, "modulate:a", 0.0, FADE_TIME)
	_fade_tween.tween_callback(_on_fade_finished)

func _on_fade_finished() -> void:
	if _raised:
		return
	visible = false
