class_name BaseBounceEffect extends Node2D

func handle_paddle_collision(ball: Ball, paddle: Paddle) -> void:
	var hit_pos: float = ball.global_position.x - paddle.global_position.x
	var new_vel: Vector2 = ball.velocity
	new_vel.x = hit_pos * paddle.paddle_influence
	new_vel.y = -abs(new_vel.y)
	new_vel = new_vel.normalized() * ball.initial_speed
	ball.update_velocity(new_vel)

func should_bounce(_collider: Node2D) -> bool:
	return true
