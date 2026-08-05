class_name ClickModeCursor extends Node2D

const CURSOR_SCENE: PackedScene = preload("res://scenes_and_scripts/actors/player/ghost_david.tscn")
const ENTRY_FX_SCENE: PackedScene = preload("res://scenes_and_scripts/bricks/brick_vfx/brick_damage_fx.tscn")
const CURSOR_SCALE_FACTOR: float = 0.80
const CURSOR_Z_INDEX: int = 4095
const CURSOR_LAYER: int = 200
const TRANSITION_SECONDS: float = 0.144
const RELEASE_LIFT: float = 150.0
const GOLD_REST_COLOR: Color = Color("#ebede9")
const GOLD_HOVER_COLOR: Color = Color("#75a743")
const GOLD_PULSE_COLOR: Color = Color("#a8ca58")
const GOLD_HOVER_GROW: float = 1.5
const GOLD_PULSE_PEAK: float = 1.7
const HOVER_TRANSITION_SECONDS: float = 0.12
const HOVER_PULSE_SECONDS: float = 0.22
const ENTRY_PULSE_GROW: float = 1.10
const ENTRY_PULSE_LIFT: float = 1.25
const ENTRY_PULSE_SECONDS: float = 0.3
const ENTRY_TELL_GROW: bool = true
const ENTRY_TELL_DAMAGE_FX: bool = true
const MANIFEST_STATES: Array[GameManager.GameState] = [
	GameManager.GameState.CLICK_MODE,
	GameManager.GameState.LEVEL_CLEARED,
	GameManager.GameState.SPECIAL_ROOM,
]

var _cursor: Node2D
var _gold: Node2D
var _paddle_ghost: Node2D
var _following: bool = false
var _transitioning: bool = false
var _virtual_pos: Vector2
var _forwarding: bool = false
var _was_manifested: bool = false
var _tween: Tween
var _gestures: MouseGestures
var _gold_rest_scale: Vector2
var _hovering: bool = false
var _hover_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cursor_layer: CanvasLayer = CanvasLayer.new()
	cursor_layer.layer = CURSOR_LAYER
	cursor_layer.follow_viewport_enabled = true
	add_child(cursor_layer)
	_cursor = CURSOR_SCENE.instantiate()
	_cursor.z_index = CURSOR_Z_INDEX
	_cursor.z_as_relative = false
	_cursor.visible = false
	cursor_layer.add_child(_cursor)
	_gold = _cursor.get_node("ParticleCartoonGold")
	_gold_rest_scale = _gold.scale
	_gold.modulate = GOLD_REST_COLOR

func _process(_delta: float) -> void:
	var manifested: bool = _should_manifest()
	if manifested != _was_manifested:
		_was_manifested = manifested
		if manifested:
			_manifest_cursor()
		else:
			_settle_cursor()
	if _following:
		_cursor.global_position = _aligned_cursor_position(_cursor.scale)
		_update_hover()

func _input(event: InputEvent) -> void:
	if _forwarding:
		return
	if not (_transitioning or _following) or DialogDirector.focused_active:
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		if _following:
			_virtual_pos = _clamped_viewport_point(_virtual_pos + motion.relative)
			_push_synthetic_motion(motion.relative)
		get_viewport().set_input_as_handled()
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if _following:
			if button.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
				_virtual_pos = _clamped_viewport_point(button.position)
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_push_synthetic_button(button)
		get_viewport().set_input_as_handled()

func _push_synthetic_motion(rel: Vector2) -> void:
	var ev: InputEventMouseMotion = InputEventMouseMotion.new()
	ev.position = _virtual_pos
	ev.global_position = _virtual_pos
	ev.relative = rel
	ev.screen_relative = rel
	ev.button_mask = Input.get_mouse_button_mask()
	_forward_event(ev)

func _push_synthetic_button(source: InputEventMouseButton) -> void:
	var ev: InputEventMouseButton = source.duplicate() as InputEventMouseButton
	ev.position = _virtual_pos
	ev.global_position = _virtual_pos
	_forward_event(ev)

func _forward_event(ev: InputEvent) -> void:
	_forwarding = true
	get_viewport().push_input(ev, true)
	_forwarding = false

func _should_manifest() -> bool:
	if _cutscene_running():
		return false
	return GameManager.current_state in MANIFEST_STATES

func _cutscene_running() -> bool:
	for node: Node in get_tree().get_nodes_in_group(&"cutscene"):
		if node.get("active") == true:
			return true
	return false

func _aligned_cursor_position(at_scale: Vector2) -> Vector2:
	return _virtual_world() - _gold.position * at_scale

func _virtual_world() -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * _virtual_pos

func _clamped_viewport_point(point: Vector2) -> Vector2:
	var rect: Rect2 = get_viewport().get_visible_rect()
	return point.clamp(rect.position, rect.end)

func _manifest_cursor() -> void:
	if GameManager.current_state == GameManager.GameState.CLICK_MODE:
		_pulse_click_targets()
	if not _resolve_paddle_ghost():
		GameManager.set_mouse_visible()
		return
	_following = false
	_kill_tween()
	_reset_gold_visuals()
	_paddle_ghost.visible = false
	_cursor.visible = true
	_gold.visible = true
	_cursor.global_position = _paddle_ghost.global_position
	_cursor.scale = _paddle_ghost.scale
	var target_scale: Vector2 = _paddle_ghost.scale * CURSOR_SCALE_FACTOR
	var lift_origin: Vector2 = _paddle_ghost.global_position - Vector2(0, RELEASE_LIFT)
	_virtual_pos = _clamped_viewport_point(get_viewport().get_canvas_transform() * (lift_origin + _gold.position * target_scale))
	_transitioning = true
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_cursor, "global_position", lift_origin, TRANSITION_SECONDS)
	_tween.tween_property(_cursor, "scale", target_scale, TRANSITION_SECONDS)
	_tween.chain().tween_callback(_begin_follow)

func _begin_follow() -> void:
	_transitioning = false
	_following = true
	_push_synthetic_motion(Vector2.ZERO)

func _settle_cursor() -> void:
	_following = false
	_transitioning = false
	_kill_tween()
	_reset_gold_visuals()
	if _paddle_ghost == null or not is_instance_valid(_paddle_ghost):
		_settle_on_paddle()
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(_cursor, "global_position", _paddle_ghost.global_position, TRANSITION_SECONDS)
	_tween.tween_property(_cursor, "scale", _paddle_ghost.scale, TRANSITION_SECONDS)
	_tween.chain().tween_callback(_settle_on_paddle)

func _settle_on_paddle() -> void:
	_cursor.visible = false
	_gold.visible = false
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

func _update_hover() -> void:
	var hovered: bool = _resolve_gestures() and not _hover_suppressed() and _gestures.get_hover_target() != null
	if hovered == _hovering:
		return
	_hovering = hovered
	if _hovering:
		_start_hover_visuals()
	else:
		_end_hover_visuals()

func _hover_suppressed() -> bool:
	return _gestures.bargain_active or (_gestures.mouse_down and _gestures.mouse_down_time > _gestures.click_vs_hold)

func _resolve_gestures() -> bool:
	if _gestures != null and is_instance_valid(_gestures):
		return true
	_gestures = get_tree().get_first_node_in_group(&"mouse_gestures") as MouseGestures
	return _gestures != null

func _start_hover_visuals() -> void:
	_kill_hover_tween()
	_hover_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hover_tween.tween_property(_gold, "modulate", GOLD_HOVER_COLOR, HOVER_TRANSITION_SECONDS)
	_hover_tween.parallel().tween_property(_gold, "scale", _gold_rest_scale * GOLD_HOVER_GROW, HOVER_TRANSITION_SECONDS)
	_hover_tween.chain().tween_property(_gold, "scale", _gold_rest_scale * GOLD_PULSE_PEAK, HOVER_PULSE_SECONDS)
	_hover_tween.parallel().tween_property(_gold, "modulate", GOLD_PULSE_COLOR, HOVER_PULSE_SECONDS)
	_hover_tween.chain().tween_property(_gold, "scale", _gold_rest_scale * GOLD_HOVER_GROW, HOVER_PULSE_SECONDS)
	_hover_tween.parallel().tween_property(_gold, "modulate", GOLD_HOVER_COLOR, HOVER_PULSE_SECONDS)
	_hover_tween.set_loops(0)

func _end_hover_visuals() -> void:
	_kill_hover_tween()
	_hover_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hover_tween.tween_property(_gold, "modulate", GOLD_REST_COLOR, HOVER_TRANSITION_SECONDS)
	_hover_tween.parallel().tween_property(_gold, "scale", _gold_rest_scale, HOVER_TRANSITION_SECONDS)

func _reset_gold_visuals() -> void:
	_kill_hover_tween()
	_hovering = false
	_gold.modulate = GOLD_REST_COLOR
	_gold.scale = _gold_rest_scale

func _kill_hover_tween() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()

func _pulse_click_targets() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or not _resolve_gestures():
		return
	for node: Node in scene.find_children("*", "", true, false):
		if node.has_method("accept_damage") and _gestures.is_gesture_target(node):
			if ENTRY_TELL_GROW:
				_pulse_target_sprite(node)
			if ENTRY_TELL_DAMAGE_FX and node is BaseSeal:
				_spawn_target_fx(node)

func _spawn_target_fx(target: Node) -> void:
	var target_2d: Node2D = target as Node2D
	if target_2d == null:
		return
	var fx: Node2D = ENTRY_FX_SCENE.instantiate()
	fx.position = target_2d.global_position
	get_tree().current_scene.add_child(fx)

func _pulse_target_sprite(target: Node) -> void:
	var sprite: Node2D = _find_pulse_sprite(target)
	if sprite == null or sprite.get_meta(&"entry_pulse_active", false):
		return
	sprite.set_meta(&"entry_pulse_active", true)
	var base_scale: Vector2 = sprite.scale
	var base_self: Color = sprite.self_modulate
	var lifted: Color = Color(base_self.r * ENTRY_PULSE_LIFT, base_self.g * ENTRY_PULSE_LIFT, base_self.b * ENTRY_PULSE_LIFT, base_self.a)
	var pulse: Tween = sprite.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(sprite, "scale", base_scale * ENTRY_PULSE_GROW, ENTRY_PULSE_SECONDS * 0.5)
	pulse.parallel().tween_property(sprite, "self_modulate", lifted, ENTRY_PULSE_SECONDS * 0.5)
	pulse.chain().tween_property(sprite, "scale", base_scale, ENTRY_PULSE_SECONDS * 0.5)
	pulse.parallel().tween_property(sprite, "self_modulate", base_self, ENTRY_PULSE_SECONDS * 0.5)
	pulse.finished.connect(_on_entry_pulse_finished.bind(sprite))

func _on_entry_pulse_finished(sprite: Node2D) -> void:
	if is_instance_valid(sprite):
		sprite.remove_meta(&"entry_pulse_active")

func _find_pulse_sprite(target: Node) -> Node2D:
	var sprites: Array[Node] = target.find_children("*", "Sprite2D", true, false)
	if sprites.is_empty():
		sprites = target.find_children("*", "AnimatedSprite2D", true, false)
	if sprites.is_empty():
		return null
	return sprites[0] as Node2D
