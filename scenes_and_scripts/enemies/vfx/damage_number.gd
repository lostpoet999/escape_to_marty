extends Node2D

func _ready():
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0, 1.0)
	tween.parallel().tween_property($AllTextTypes, "position", Vector2(0, -100), 1.0)
	tween.finished.connect(on_tween_finished)

func on_tween_finished():
	queue_free()

func show_damage(damage_string: String):
	if damage_string == "denied":
		$AllTextTypes/Number.visible = false
		$AllTextTypes/Denied.visible = true
	else:
		$AllTextTypes/Number.visible = true
		$AllTextTypes/Number/Label.text = damage_string
		$AllTextTypes/Number/Outline.text = damage_string
		$AllTextTypes/Denied.visible = false
		
