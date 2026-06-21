class_name ClickModeCursor extends Node2D

const CURSOR_SCENE: PackedScene = preload("res://scenes_and_scripts/actors/player/ghost_david.tscn")
const CURSOR_SCALE_FACTOR: float = 0.80
const CURSOR_Z_INDEX: int = 1000
const TRANSITION_SECONDS: float = 0.144
const RELEASE_LIFT: float = 150.0

var _cursor: Node2D
var _star: Node2D
var _paddle_ghost: Node2D
var _following: bool = false
var _locking_mouse: bool = false
var _lift_mouse_target: Vector2
var _was_click_mode: bool = false
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cursor = CURSOR_SCENE.instantiate()
	_cursor.z_index = CURSOR_Z_INDEX
	_cursor.z_as_relative = false
	_cursor.visible = false
	add_child(_cursor)
	_star = _cursor.get_node("ParticleCartoonStar")

func _process(_delta: float) -> void:
	var in_click: bool = GameManager.current_state == GameManager.GameState.CLICK_MODE
	if in_click != _was_click_mode:
		_was_click_mode = in_click
		if in_click:
			_enter_click_mode()
		else:
			_exit_click_mode()
	if _locking_mouse:
		_warp_mouse_to(_lift_mouse_target)
	elif _following:
		_cursor.global_position = _aligned_cursor_position(_cursor.scale)

func _aligned_cursor_position(at_scale: Vector2) -> Vector2:
	return get_global_mouse_position() - _star.position * at_scale

func _warp_mouse_to(world_pos: Vector2) -> void:
	var viewport: Viewport = get_viewport()
	Input.warp_mouse(viewport.get_screen_transform() * (viewport.get_canvas_transform() * world_pos))

func _enter_click_mode() -> void:
	if not _resolve_paddle_ghost():
		return
	_following = false
	_kill_tween()
	_paddle_ghost.visible = false
	_cursor.visible = true
	_star.visible = true
	_cursor.global_position = _paddle_ghost.global_position
	_cursor.scale = _paddle_ghost.scale
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var target_scale: Vector2 = _paddle_ghost.scale * CURSOR_SCALE_FACTOR
	var lift_origin: Vector2 = _paddle_ghost.global_position - Vector2(0, RELEASE_LIFT)
	_lift_mouse_target = lift_origin + _star.position * target_scale
	_locking_mouse = true
	_warp_mouse_to(_lift_mouse_target)
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_cursor, "global_position", lift_origin, TRANSITION_SECONDS)
	_tween.tween_property(_cursor, "scale", target_scale, TRANSITION_SECONDS)
	_tween.chain().tween_callback(_begin_follow)

func _begin_follow() -> void:
	_locking_mouse = false
	_following = true

func _exit_click_mode() -> void:
	_following = false
	_locking_mouse = false
	_kill_tween()
	if _paddle_ghost == null or not is_instance_valid(_paddle_ghost):
		_settle_on_paddle()
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(_cursor, "global_position", _paddle_ghost.global_position, TRANSITION_SECONDS)
	_tween.tween_property(_cursor, "scale", _paddle_ghost.scale, TRANSITION_SECONDS)
	_tween.chain().tween_callback(_settle_on_paddle)

func _settle_on_paddle() -> void:
	_cursor.visible = false
	_star.visible = false
	if _paddle_ghost != null and is_instance_valid(_paddle_ghost):
		_paddle_ghost.visible = true

func _resolve_paddle_ghost() -> bool:
	if _paddle_ghost != null and is_instance_valid(_paddle_ghost):
		return true
	var david: Node = get_tree().get_first_node_in_group(&"david")
	if david == null:
		return false
	_paddle_ghost = david.get_node_or_null("GhostDavid")
	return _paddle_ghost != null

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
