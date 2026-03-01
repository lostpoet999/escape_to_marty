extends Area2D

@export var fall_speed: float = 120.0
@export var star_value: int = 1

func _ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)
	tween.set_loops(0)

func _process(delta: float) -> void:
	position.y += fall_speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(GameManager.DEATH_WALLS):
		Signalbus.star_collected.emit(-1)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(GameManager.PADDLE):
		Signalbus.star_collected.emit(-1)
		set_process(false)
		PlayerData.change_player_stars(star_value)
		visible = false
		queue_free()
