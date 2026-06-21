extends Node

const CUTSCENE_ID: StringName = &"opening"
const NAG_INTERVAL_SECONDS: float = 8.0
const FALL_SECONDS: float = 0.75
const TUTORIAL_LABEL_GROUP: StringName = &"opening_tutorial"
const SKIP_FONT: FontFile = preload("res://label_settings_and_fonts/fonts/PressStart2P-Regular.ttf")
const SKIP_HOLD_SECONDS: float = 1.0
const SKIP_MARGIN: float = 24.0
const SKIP_BAR_HEIGHT: float = 6.0
const SKIP_FONT_SIZE: int = 12
const SKIP_IDLE_ALPHA: float = 0.6
const SKIP_COLOR: Color = Color(1, 0.9, 0.4)
const SKIP_PULSE_AMPLITUDE: float = 0.03
const SKIP_PULSE_SECONDS: float = 2.6
const SKIP_WOBBLE_RADIANS: float = 0.03
const SKIP_WOBBLE_SECONDS: float = 1.7

## The seal used in the opening scene.
@export var seal: BaseSeal

var _break_position: Vector2
var _skipped: bool = false
var _animation_time: float = 0.0
var _hold_seconds: float = 0.0
var _prompt_held: bool = false
var _skip_layer: CanvasLayer
var _skip_box: VBoxContainer
var _skip_bar: ColorRect
var _skip_fill: ColorRect


func _ready() -> void:
	set_process(false)


func run() -> void:
	if PlayerData.seen_cutscenes.has(CUTSCENE_ID):
		return
	PlayerData.seen_cutscenes.append(CUTSCENE_ID)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_spawn_skip_prompt()
	set_process(true)
	_set_tutorial_visible(false)
	_set_exits_locked(true)
	var paddle: Paddle = get_tree().get_first_node_in_group("paddle") as Paddle
	paddle.set_paddle_hidden(true, true)
	seal.input_event.connect(_on_seal_input)
	DialogDirector.play(&"opening_in_brick", seal)
	_nag_loop()
	await _shell_break()
	if _skipped:
		return
	await _david_falls(paddle)
	if _skipped:
		return
	await DialogDirector.play_and_wait(&"opening_collector_grant")
	if _skipped:
		return
	paddle.set_paddle_hidden(false)
	await DialogDirector.play_and_wait(&"opening_freed")
	if _skipped:
		return
	_set_tutorial_visible(true)
	_set_exits_locked(false)
	_remove_skip_prompt()


func _process(delta: float) -> void:
	_animation_time += delta
	if _prompt_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_prompt_held = false
	if Input.is_physical_key_pressed(KEY_E) or _prompt_held: #hold to skip
		_hold_seconds += delta
	else:
		_hold_seconds = 0.0
	_update_skip_fill()
	_animate_skip_prompt()
	if _hold_seconds >= SKIP_HOLD_SECONDS:
		_skip_to_end()


func _skip_to_end() -> void:
	_skipped = true
	_remove_skip_prompt()
	DialogDirector.cancel_active()
	if is_instance_valid(seal) and not seal.dying:
		seal.dying = true
		seal.queue_free()
	var paddle: Paddle = get_tree().get_first_node_in_group("paddle") as Paddle
	paddle.set_paddle_hidden(false, true)
	_set_tutorial_visible(true)
	_set_exits_locked(false)


func _set_exits_locked(locked: bool) -> void:
	for exit_node: Node in get_tree().get_nodes_in_group(&"exits"):
		exit_node.set_travel_locked(locked)


func _on_seal_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT or not click.pressed:
		return
	var click_types: Array[GameManager.PhaseType] = [GameManager.PhaseType.DENIAL]
	seal.accept_damage(PlayerInventory.get_instance().get_gesture_damage(), click_types)


func _shell_break() -> void:
	while is_instance_valid(seal) and not seal.stages.is_empty():
		await get_tree().process_frame
	if _skipped or not is_instance_valid(seal):
		return
	_break_position = seal.global_position
	seal.dying = true
	var fx: Node2D = seal.brick_destroy_fx.instantiate() as Node2D
	fx.position = _break_position
	get_tree().current_scene.add_child(fx)
	var tween: Tween = create_tween()
	tween.tween_property(seal, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(seal, "scale", Vector2(0.1, 0.1), 0.1).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	seal.queue_free()


func _david_falls(paddle: Paddle) -> void:
	var david: Node2D = paddle.david
	var rest_local: Vector2 = david.position
	david.global_position = _break_position
	david.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(david, "position", rest_local, FALL_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


func _nag_loop() -> void:
	while is_instance_valid(seal) and not seal.stages.is_empty():
		await get_tree().create_timer(NAG_INTERVAL_SECONDS).timeout
		if _skipped or not is_instance_valid(seal) or seal.stages.is_empty():
			return
		DialogDirector.play(&"opening_nags", seal)


func _set_tutorial_visible(shown: bool) -> void:
	for label: Node in get_tree().get_nodes_in_group(TUTORIAL_LABEL_GROUP):
		var item: CanvasItem = label as CanvasItem
		if item != null:
			item.visible = shown


func _spawn_skip_prompt() -> void:
	_skip_layer = CanvasLayer.new()
	_skip_layer.layer = 100
	add_child(_skip_layer)
	_skip_box = VBoxContainer.new()
	_skip_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_skip_box.offset_right = -SKIP_MARGIN
	_skip_box.offset_bottom = -SKIP_MARGIN
	_skip_box.modulate.a = SKIP_IDLE_ALPHA
	_skip_box.add_to_group(&"skip_prompt")
	_skip_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_skip_box.gui_input.connect(_on_prompt_gui_input)
	_skip_layer.add_child(_skip_box)
	var label: Label = Label.new()
	label.text = "HOLD TO SKIP [E]"
	label.add_theme_font_override("font", SKIP_FONT)
	label.add_theme_font_size_override("font_size", SKIP_FONT_SIZE)
	label.add_theme_color_override("font_color", SKIP_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_box.add_child(label)
	_skip_bar = ColorRect.new()
	_skip_bar.color = Color(SKIP_COLOR, 0.25)
	_skip_bar.custom_minimum_size = Vector2(0, SKIP_BAR_HEIGHT)
	_skip_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_box.add_child(_skip_bar)
	_skip_fill = ColorRect.new()
	_skip_fill.color = SKIP_COLOR	
	_skip_fill.size = Vector2(0, SKIP_BAR_HEIGHT)
	_skip_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_bar.add_child(_skip_fill)


func _on_prompt_gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		_prompt_held = click.pressed


func _update_skip_fill() -> void:
	if not is_instance_valid(_skip_fill):
		return
	var progress: float = clampf(_hold_seconds / SKIP_HOLD_SECONDS, 0.0, 1.0)
	_skip_fill.size = Vector2(_skip_bar.size.x * progress, SKIP_BAR_HEIGHT)
	_skip_box.modulate.a = lerpf(SKIP_IDLE_ALPHA, 1.0, progress)


func _animate_skip_prompt() -> void:
	if not is_instance_valid(_skip_box):
		return
	_skip_box.pivot_offset = _skip_box.size / 2.0
	var pulse: float = 1.0 + sin(TAU * _animation_time / SKIP_PULSE_SECONDS) * SKIP_PULSE_AMPLITUDE
	_skip_box.scale = Vector2.ONE * pulse
	_skip_box.rotation = sin(TAU * _animation_time / SKIP_WOBBLE_SECONDS) * SKIP_WOBBLE_RADIANS


func _remove_skip_prompt() -> void:
	set_process(false)
	if is_instance_valid(_skip_layer):
		_skip_layer.queue_free()
	_skip_layer = null
