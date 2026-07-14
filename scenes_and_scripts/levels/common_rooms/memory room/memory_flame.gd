extends Node2D

var hover: Color = modulate
var not_hover: Color = Color(0.5, 0.5, 0.5, 0.95)
var base_scale: Vector2 = Vector2.ONE
var _collecting: bool = false
var _pulse_tween: Tween
@onready var room_before_click: Node2D = $".."
@onready var codec_player: MemoryCodecPlayer = $"../../MemoryCodecPlayer"
@onready var texture_button: TextureButton = $TextureButton

func _ready() -> void:
	if SaveProgression.is_memory_seen(_memory_id()):
		room_before_click.hide()
		return
	if codec_player.memory_tree == null:
		var entry: RoomEntry = GameManager.get_current_floor_entry(GameManager.current_room_id)
		codec_player.memory_tree = entry.content.memory_tree
	GameManager.change_state(GameManager.GameState.SPECIAL_ROOM)
	DialogDirector.play.call_deferred(&"memory_room_taunt")
	base_scale = scale
	pulse_loop(self, 1.08, 1.4)
	modulate = not_hover

func memory_room_state() -> RoomState:
	var entry: RoomEntry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	return PlayerData.get_room_state(entry)

func _memory_id() -> StringName:
	var entry: RoomEntry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	return entry.content.memory_id()

func pulse_loop(node: Node2D, scale_amount: float = 1.1, duration: float = 0.6) -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE)
	_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(node, "scale", base_scale * scale_amount, duration * 0.5)
	_pulse_tween.tween_property(node, "scale", base_scale, duration * 0.5)

func _on_texture_button_mouse_entered() -> void:
	modulate = hover

func _on_texture_button_mouse_exited() -> void:
	if _collecting:
		return
	modulate = not_hover

func _on_texture_button_pressed() -> void:
	if codec_player.memory_tree == null or codec_player.memory_tree.beats.is_empty():
		push_warning("MemoryFlame: no memory_tree authored for %s--flame stays uncollected" % _memory_id())
		return
	if _collecting:
		return
	_collecting = true
	texture_button.disabled = true
	modulate = hover
	DialogDirector.cancel_active()
	await _tween_to_david()
	room_before_click.hide()
	await codec_player.play()
	close_memory()

func _tween_to_david() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	var david: Node2D = get_tree().get_first_node_in_group("david")
	if david == null:
		return
	var hit_target: Node2D = david.get_node("DavidHitTarget")
	var p0: Vector2 = global_position
	var p2: Vector2 = hit_target.global_position
	var p1: Vector2 = (p0 + p2) * 0.5 + Vector2(0, 40.0)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(t: float) -> void: global_position = _bezier(t, p0, p1, p2),
		0.0, 1.0, 0.55
	)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * 0.05, 0.55)
	await tween.finished

func _bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var u: float = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

func close_memory() -> void:
	room_before_click.show()
	collect_flame()
	memory_room_state().cleared = true
	SaveProgression.mark_memory_seen(_memory_id())
	Signalbus.level_cleared.emit()

func collect_flame() -> void:
	hide()
