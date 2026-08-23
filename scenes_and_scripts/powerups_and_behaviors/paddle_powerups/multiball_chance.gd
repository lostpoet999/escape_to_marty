class_name MultiballChance extends PaddlePowerup

const miniball = preload("res://scenes_and_scripts/ball/miniball.tscn")
const MINIBALL_SPAWN_CHANCE: float = 0.5
var num_extra_balls: int = 0
var can_damage_player: bool = false

func set_damage_player(can_damage: bool) -> void:
	if can_damage:
		can_damage_player = true
	else:
		can_damage_player = false

func try_spawn_balls(root_scene: Node, paddle: Paddle) -> void:
	var chance: float = randf_range(0,1)
	if chance > MINIBALL_SPAWN_CHANCE:
		return
	num_extra_balls = randi_range(2,4)
	for i in range(0, num_extra_balls):
		var new_miniball: MiniBall = miniball.instantiate() as MiniBall
		root_scene.add_child(new_miniball)
		var spawn_marker_index: int = randi_range(4,7)
		new_miniball.global_position = paddle.get_child(spawn_marker_index).global_position - Vector2(0,10.0)
