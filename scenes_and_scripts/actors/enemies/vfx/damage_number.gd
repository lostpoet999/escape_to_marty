class_name DamageNumber
extends Node2D

const COLOR_DEALT: Color = Color(1, 1, 0.3)
const COLOR_TAKEN: Color = Color(1, 0.15, 0.15)

func _ready()->void:
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0, 1.0)
	tween.parallel().tween_property($AllTextTypes, "position", Vector2(0, -100), 1.0)
	tween.finished.connect(on_tween_finished)

func on_tween_finished():
	queue_free()

func show_damage(damage_string: String, color: Color = COLOR_TAKEN)->void:
	var outline_color: Color = Color.BLACK if color == COLOR_TAKEN else Color.WHITE
	if damage_string == "denied":
		$AllTextTypes/Number.visible = false
		$AllTextTypes/Denied.visible = true
		_apply_colors($AllTextTypes/Denied/Label, color, outline_color)
	else:
		$AllTextTypes/Number.visible = true
		$AllTextTypes/Number/Label.text = damage_string
		_apply_colors($AllTextTypes/Number/Label, color, outline_color)
		$AllTextTypes/Denied.visible = false

func _apply_colors(label: Label, fill: Color, outline: Color) -> void:
	label.add_theme_color_override("font_color", fill)
	label.add_theme_color_override("font_outline_color", outline)
