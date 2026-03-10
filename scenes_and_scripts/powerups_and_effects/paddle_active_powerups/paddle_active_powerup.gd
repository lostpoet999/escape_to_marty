class_name ActivePaddlePowerup extends Resource
@export_category("Projectile:")
@export var fire_projectile: bool
@export var projectile_speed: float
@export var projectile_scene: PackedScene

func activate_paddle_shot()->void:
	print("activated paddle shot")
	if fire_projectile:
		activate_projectile()
		
func activate_projectile()->void:
	print("projectile")
