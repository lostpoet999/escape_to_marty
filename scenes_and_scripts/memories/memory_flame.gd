extends Node2D

var hover: Color = modulate
var not_hover: Color = Color(0.5, 0.5, 0.5, 0.95)
@onready var room_before_click: Node2D = $".."
@onready var room_after_click: Node2D = $"../../RoomAfterClick"

var viewing_memory: bool = false

const COLLECTED_TEXT: String = "This flame of memory has been collected... but visit me again some other time..."

func _ready() -> void:
	if SaveProgression.is_memory_seen(_memory_id()):
		room_before_click.hide()
		room_after_click.hide()
		return
	GameManager.change_state(GameManager.GameState.SPECIAL_ROOM)
	var close_button: Button = room_after_click.get_node("CloseButton") as Button
	close_button.pressed.connect(close_memory)
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
	room_before_click.hide()
	room_after_click.show()
	viewing_memory = true

func _unhandled_input(event: InputEvent) -> void:
	if not viewing_memory:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_memory()
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			close_memory()

func close_memory() -> void:
	if not viewing_memory:
		return
	viewing_memory = false
	room_after_click.hide()
	room_before_click.show()
	collect_flame()
	memory_room_state().cleared = true
	SaveProgression.mark_memory_seen(_memory_id())
	Signalbus.level_cleared.emit()

func collect_flame() -> void:
	hide()
	var prompt_label: Label = room_before_click.get_node("Sprite2D/Label") as Label
	prompt_label.text = COLLECTED_TEXT
