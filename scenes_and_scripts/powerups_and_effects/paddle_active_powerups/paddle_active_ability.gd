class_name PaddleActive extends BaseItem

@export_category("Shot Configuration:")
@export var projectile_ref: PackedScene
@export var max_spawn: int
@export var cool_down_seconds: float
@export var speed_modifier: float
@export var damage: int
#TODO: add spawn logic based on paddle marker. ie, you can mark all the spots its possible to spawn from

func activate(paddle , projectile_node: Node):
	var projectile = projectile_ref.instantiate() as Area2D
	projectile.position = paddle.global_position
	projectile.position.y -= 32
	projectile.initialize_shot(speed_modifier, damage)
	projectile_node.add_child(projectile)
