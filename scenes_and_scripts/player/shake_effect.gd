class_name ShakeEffect

var shake_amount: float = 15.0
var shake_step: float = 0.025

#TODO: make sure we return to original position even if clicked fast

func apply_to(tween_parent: Node2D, sprite: Node2D) -> void:
	var original_offset: Vector2 = sprite.offset
	var shake_tween: Tween = tween_parent.create_tween()
	for i: int in 4:
		var random_offset: Vector2 = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_tween.tween_property(sprite, "offset", original_offset + random_offset, shake_step)
	shake_tween.tween_property(sprite, "offset", original_offset, shake_step)
