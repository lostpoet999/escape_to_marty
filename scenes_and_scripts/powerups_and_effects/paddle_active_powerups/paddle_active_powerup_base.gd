class_name ActivePaddlePowerup extends Resource

enum basic_direction {Up, Down, Left, Right}

@export var paddle_active_ability_name: String
@export var inventory_sprite: Texture2D 

@export_category("Projectile:")
@export var fire_projectile: bool
@export var projectile_speed: float
@export var projectile_scene: PackedScene

@export_category("Bump:")
@export var bump_ability: bool
@export var bump_direction: basic_direction
@export var bump_amount: float
@export var bump_acceleration: float
@export var bump_damage_bonus: int
@export var bump_hits_duration: int

func activate_paddle_shot()->void: 
	#this function can do other things besides fire a projectile. note: this likely ends up being a menu of basic active abilities then we can override in a different script if we want to extend or just add to here.
	print("activated paddle shot")
	if fire_projectile:
		activate_projectile()
		
func activate_projectile()->void: #this function will fire a projectile and can be overriden
	print("projectile")
