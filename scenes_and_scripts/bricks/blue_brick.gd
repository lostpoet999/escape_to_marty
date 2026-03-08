extends Area2D

const STAR_COLLECTIBLE: PackedScene = preload("uid://cfjv2f23gme53")

@export var brick_score_value: int = 5
@export var brick_health: int = 3
@onready var brick_health_label: Label = $brick_health

func _ready() -> void:
	brick_health_label.text = str(brick_health)
	input_pickable = true

func accept_damage(damage: float) -> void:
	if brick_health - damage <= 0:
		pop_tween()
	else:
		brick_health -= int(damage)
		brick_health_label.text = str(brick_health)

func pop_tween() -> void:
	var tween: Tween = get_tree().create_tween()

	tween.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(.1, .1), 0.1).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.connect("finished", Callable(self, "_on_tween_finished").bind(self))

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		accept_damage(1)

#cleanup brick collision after tween finishes
func _on_tween_finished(collider: Area2D) -> void:
	if is_instance_valid(collider):
		PlayerData.update_player_score(brick_score_value)
		collider.queue_free()
		var star_instance: Area2D = STAR_COLLECTIBLE.instantiate()
		collider.get_parent().add_child(star_instance)
		star_instance.position = collider.position
		Signalbus.star_spawned.emit(1)
		Signalbus.brick_destroyed.emit()
