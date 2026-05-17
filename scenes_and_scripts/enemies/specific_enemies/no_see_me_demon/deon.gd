class_name Deon
extends PlacedEnemy

@export var destroy_fx: PackedScene

func accept_damage(_damage: int, _dmg_type: Array[GameManager.PhaseType])->void:
	SFX.play_sound("player_hurt")
	take_damage_fx()
	denial_health -= 1
	if denial_health == 0: self.modulate = Color.WHITE
	elif denial_health <= -1: die()
		

func die()->void:
	if is_blocker:
		Signalbus.blocker_removed.emit(self)
		ready_to_remove.emit(self)
	@warning_ignore("unsafe_method_access")
	get_viewport().get_camera_2d().add_trauma(2.0)
	SFX.play_sound("deon_die")
	if destroy_fx != null:
		var fx: Node2D = destroy_fx.instantiate()
		fx.position = global_position
		get_tree().current_scene.add_child(fx)
	queue_free()

func take_damage_fx()->void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("flash_amount", 1.0)
		var flash_tween: Tween = create_tween()
		flash_tween.tween_method(
			func(v: float) -> void: mat.set_shader_parameter("flash_amount", v),
			1.0, 0.0, 0.05
		)
	var before_shake_pos: Vector2 = self.global_position
	var shake_effect = ShakeEffect.new()
	shake_effect.apply_to(self, sprite)
	self.global_position = before_shake_pos
