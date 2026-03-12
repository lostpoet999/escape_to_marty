class_name Projectile extends Area2D

@export var speed: float = 800
@export var damage: int

func initialize_shot(speed_mod, damage_ref):
	speed *= speed_mod
	damage = damage_ref

func _process(delta: float) -> void:
	global_position.y -= speed * delta


func _on_area_entered(area: Area2D) -> void:	
	if area.is_in_group("bricks"):
		area.accept_damage(damage)
		queue_free()
	elif area.is_in_group("walls"):
		queue_free()
