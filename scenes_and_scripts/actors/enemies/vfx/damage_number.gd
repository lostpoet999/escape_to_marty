class_name DamageNumber
extends Node2D

const COLOR_DEALT: Color = Color(1, 1, 0.3)
const COLOR_TAKEN: Color = Color(1, 0.15, 0.15)

func _ready():
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0, 1.0)
	tween.parallel().tween_property($AllTextTypes, "position", Vector2(0, -100), 1.0)
	tween.finished.connect(on_tween_finished)

func on_tween_finished():
	queue_free()

func show_damage(damage_string: String, color: Color = COLOR_TAKEN):
	if damage_string == "denied":
		$AllTextTypes/Number.visible = false
		$AllTextTypes/Denied.visible = true
		$AllTextTypes/Denied/Label.add_theme_color_override("font_color", color)
		$AllTextTypes/Denied/Outline.add_theme_color_override("font_color", Color.WHITE)
	else:
		$AllTextTypes/Number.visible = true
		$AllTextTypes/Number/Label.text = damage_string
		$AllTextTypes/Number/Outline.text = damage_string
		$AllTextTypes/Number/Label.add_theme_color_override("font_color", color)
		$AllTextTypes/Number/Outline.add_theme_color_override("font_color", Color.WHITE)
		$AllTextTypes/Denied.visible = false
		
