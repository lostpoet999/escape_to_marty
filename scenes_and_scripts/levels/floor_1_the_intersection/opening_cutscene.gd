extends Node

const CUTSCENE_ID: StringName = &"opening"
const NAG_INTERVAL_SECONDS: float = 8.0
const FALL_SECONDS: float = 0.75
const TUTORIAL_LABEL_GROUP: StringName = &"opening_tutorial"
const TUTORIAL_BOARD_DIR: String = "res://scenes_and_scripts/backgrounds/tutorial backgrounds/"

## The seal used in the opening scene.
@export var seal: BaseSeal
## The denial practice seal, revealed once the cutscene is over (or was already seen).
@export var practice_seal: PracticeSeal

var active: bool = false
var _break_position: Vector2
var _skipped: bool = false
var _skip_prompt: SkipPrompt


func _ready() -> void:
	_register_tutorial_boards()


func _register_tutorial_boards() -> void:
	for node: Node in get_parent().find_children("*", "Sprite2D", true, false):
		var board: Sprite2D = node as Sprite2D
		if board == null or board.texture == null:
			continue
		if board.texture.resource_path.begins_with(TUTORIAL_BOARD_DIR):
			board.add_to_group(TUTORIAL_LABEL_GROUP)
			board.visible = false


func run() -> void:
	if PlayerData.seen_cutscenes.has(CUTSCENE_ID):
		_clear_shell()
		_set_tutorial_visible(true)
		_reveal_practice_seal()
		return
	PlayerData.seen_cutscenes.append(CUTSCENE_ID)
	active = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_spawn_skip_prompt()
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
	_reveal_practice_seal()
	_remove_skip_prompt()
	active = false


func _skip_to_end() -> void:
	_skipped = true
	active = false
	_remove_skip_prompt()
	DialogDirector.cancel_active()
	_clear_shell()
	var paddle: Paddle = get_tree().get_first_node_in_group("paddle") as Paddle
	paddle.set_paddle_hidden(false, true)
	_set_tutorial_visible(true)
	_set_exits_locked(false)
	_reveal_practice_seal()


func _clear_shell() -> void:
	if is_instance_valid(seal) and not seal.dying:
		seal.dying = true
		seal.queue_free()


func _reveal_practice_seal() -> void:
	if practice_seal != null:
		practice_seal.reveal()


func _set_exits_locked(locked: bool) -> void:
	for exit_node: Node in get_tree().get_nodes_in_group(&"exits"):
		exit_node.set_travel_locked(locked)


func _on_seal_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT or not click.pressed:
		return
	if seal.dying:
		return
	SFX.play_sound("hit-brick")
	var click_types: Array[GameManager.PhaseType] = [GameManager.PhaseType.DENIAL]
	seal.accept_damage(PlayerInventory.get_instance().get_gesture_damage(), click_types, 0.0)


func _shell_break() -> void:
	while is_instance_valid(seal) and not seal.stages.is_empty():
		await get_tree().process_frame
		if not is_inside_tree():
			return
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
		if not is_inside_tree() or _skipped or not is_instance_valid(seal) or seal.stages.is_empty():
			return
		DialogDirector.play(&"opening_nags", seal)


func _set_tutorial_visible(shown: bool) -> void:
	for label: Node in get_tree().get_nodes_in_group(TUTORIAL_LABEL_GROUP):
		var item: CanvasItem = label as CanvasItem
		if item != null:
			item.visible = shown


func _spawn_skip_prompt() -> void:
	_skip_prompt = SkipPrompt.new()
	_skip_prompt.skip_committed.connect(_skip_to_end)
	add_child(_skip_prompt)


func _remove_skip_prompt() -> void:
	if is_instance_valid(_skip_prompt):
		_skip_prompt.queue_free()
	_skip_prompt = null
