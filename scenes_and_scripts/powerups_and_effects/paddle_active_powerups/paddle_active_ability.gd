class_name PaddleActive extends BaseItem

@export_category("Shot Configuration:")
@export var projectile_ref: PackedScene
@export var max_spawn: int
@export var cool_down_seconds: float
@export var speed_modifier: float
@export var damage: int
var current_active: int = 0
var projectile_dmg_type: Array[GameManager.PhaseType]
#TODO: add spawn logic based on paddle marker. ie, you can mark all the spots its possible to spawn from

func _ready()->void:
	current_active = 0
	projectile_dmg_type = [GameManager.PhaseType.DENIAL]

func activate(paddle:Paddle , projectile_node: Node)->void:		
	if (current_active < max_spawn) or (max_spawn<=0):
		var projectile:Projectile = projectile_ref.instantiate() as Area2D
		projectile.position = paddle.global_position
		projectile.position.y -= 32
		projectile.initialize_shot(speed_modifier, damage, self,projectile_dmg_type)		
		projectile_node.add_child(projectile)
		current_active+=1
