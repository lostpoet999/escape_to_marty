extends Node2D

func _ready():
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0, 1.0)
	tween.parallel().tween_property($TextContainer, "position", Vector2(0, -100), 1.0)
	tween.finished.connect(on_tween_finished)

func on_tween_finished():
	queue_free()
