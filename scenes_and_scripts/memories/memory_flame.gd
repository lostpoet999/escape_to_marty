extends Node2D

var hover: Color = modulate
var not_hover: Color = Color(0.5, 0.5, 0.5, 0.95)
@onready var room_before_click: Node2D = $".."
@onready var room_after_click: Node2D = $"../../RoomAfterClick"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	pulse_loop(self, 1.1, 1.0)	
	modulate = not_hover	
	GameManager.change_state(GameManager.GameState.SPECIAL_ROOM)

func pulse_loop(node: Node2D, scale_amount: float = 1.1, duration: float = 0.6) -> void:
	var tween : Tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2.ONE * scale_amount, duration * 0.5)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.5)

func _on_texture_button_mouse_entered() -> void:
	modulate = hover

func _on_texture_button_mouse_exited() -> void:
	modulate = Color(0.5, 0.5, 0.5, 0.95)


func _on_texture_button_pressed() -> void:
	room_before_click.hide()
	room_after_click.show()	
	Signalbus.level_cleared.emit()
