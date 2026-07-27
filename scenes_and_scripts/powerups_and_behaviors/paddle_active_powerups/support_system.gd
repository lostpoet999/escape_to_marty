class_name SupportSystem extends PaddleActive

func can_activate_on_paddle() -> bool:
	return true

func activate(paddle: Paddle, _projectile_node: Node) -> void:
	var ball: Ball = paddle.get_tree().get_first_node_in_group("ball") as Ball
	if ball == null:
		return
	ball.attract_to_paddle()
