extends Node2D

var hover: Color = modulate
var not_hover: Color = Color(0.5, 0.5, 0.5, 0.95)
@onready var room_before_click: Node2D = $".."
@onready var codec_player: MemoryCodecPlayer = $"../../MemoryCodecPlayer"

const COLLECTED_TEXT: String = "This flame of memory has been collected... but visit me again some other time..."

func _ready() -> void:
	if SaveProgression.is_memory_seen(_memory_id()):
		room_before_click.hide()
		return
	GameManager.change_state(GameManager.GameState.SPECIAL_ROOM)
	pulse_loop(self, 1.1, 1.0)
	modulate = not_hover

func memory_room_state() -> RoomState:
	var entry: RoomEntry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	return PlayerData.get_room_state(entry)

func _memory_id() -> StringName:
	var entry: RoomEntry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	return entry.content.memory_id()

func pulse_loop(node: Node2D, scale_amount: float = 1.1, duration: float = 0.6) -> void:
	var tween : Tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2.ONE * scale_amount, duration * 0.5)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.5)

func _on_texture_button_mouse_entered() -> void:
	modulate = hover

func _on_texture_button_mouse_exited() -> void:
	modulate = not_hover

func _on_texture_button_pressed() -> void:
	if codec_player.memory_tree == null or codec_player.memory_tree.beats.is_empty():
		push_warning("MemoryFlame: no memory_tree authored for %s--flame stays uncollected" % _memory_id())
		return
	room_before_click.hide()
	await codec_player.play()
	close_memory()

func close_memory() -> void:
	room_before_click.show()
	collect_flame()
	memory_room_state().cleared = true
	SaveProgression.mark_memory_seen(_memory_id())
	Signalbus.level_cleared.emit()

func collect_flame() -> void:
	hide()
	var prompt_label: Label = room_before_click.get_node("Sprite2D/Label") as Label
	prompt_label.text = COLLECTED_TEXT
