class_name WallWalker
extends PlacedEnemy

enum WallSide { LEFT, RIGHT, TOP }

@export var wall_side: WallSide ## Which wall this walker clings to; sets the emerge axis (and, in later phases, the escape direction).
@export var emerge_time: float ## Seconds for the sprite to grow out of the wall on spawn; the physics body never scales.

func _ready() -> void:
	super()
	modulate = Color.WHITE
	modulate.a = 1.0
	timer.stop()
	_play_emerge()

func _play_emerge() -> void:
	var sprite: Node2D = get_node_or_null("EnemySprite")
	if sprite == null:
		start_action_timer()
		return
	var full_scale: Vector2 = sprite.scale
	var start_scale: Vector2 = full_scale
	match wall_side:
		WallSide.TOP:
			start_scale.y = 0.0
		_:
			start_scale.x = 0.0
	sprite.scale = start_scale
	var emerge_tween: Tween = create_tween()
	emerge_tween.tween_property(sprite, "scale", full_scale, emerge_time)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	emerge_tween.tween_callback(start_action_timer)

func die() -> void:
	if is_queued_for_deletion(): return
	ready_to_remove.emit(self)
	_on_death(denial_health <= -1)
	@warning_ignore("unsafe_method_access")
	get_viewport().get_camera_2d().add_trauma(0.5)
	SFX.play_sound("enemy_hurt")
	queue_free()

## Virtual death hook. killed_by_damage == (denial_health <= -1): true means the ball
## killed it (accept_damage drove health negative), false means the level_cleared sweep.
## Subclasses (MoneyThiefSpider) override to burst the hoard only on a damage kill.
func _on_death(_killed_by_damage: bool) -> void:
	pass
