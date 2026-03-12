class_name Projectile extends Area2D

@export var speed: float = 800
@export var damage: int
@export var spawner: PaddleActive

func initialize_shot(speed_mod, damage_ref, spawner_ref):
	speed *= speed_mod
	damage = damage_ref
	spawner = spawner_ref

func _process(delta: float) -> void:
	global_position.y -= speed * delta


func _on_area_entered(area: Area2D) -> void:	
	if area.is_in_group("bricks"):
		area.accept_damage(damage)		
		queue_free()
		spawner.current_active -=1
	elif area.is_in_group("walls"):
		queue_free()
		spawner.current_active -=1


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
	spawner.current_active -=1
