# base_bounce_effect.gd
class_name BaseBounceEffect extends BaseItem

@export var pierce_brick: bool = false
@export var velocity_factor: float = 1.002

func handle_paddle_collision(ball: Ball, paddle: Paddle) -> void:
	var hit_pos: float = ball.global_position.x - paddle.global_position.x
	var new_vel: Vector2 = ball.velocity
	new_vel.x = hit_pos * paddle.paddle_influence
	new_vel.y = -abs(new_vel.y)
	new_vel = new_vel.normalized() * ball.current_speed
	ball.current_speed = clampf(ball.current_speed * velocity_factor, 0.0, ball.max_speed)
	ball.update_velocity(new_vel)

func handle_x_collision(ball: Ball, collider: Node2D) -> void:
	if pierce_brick:
		ball.handle_pierce(collider)
		return
	ball.push_out_x(collider, ball.move.x)
	ball.velocity.x = absf(ball.velocity.x) * signf(ball.global_position.x - collider.global_position.x)
	ball.current_speed *= velocity_factor
	ball.current_speed = clampf(ball.current_speed * velocity_factor, 0.0, ball.max_speed)
	var leftover: float = maxf(absf(ball.move.x) - absf(ball.position.x - ball.old_x), 0.0)
	ball.position.x += signf(ball.velocity.x) * leftover

func handle_y_collision(ball: Ball, collider: Node2D) -> void:
	if pierce_brick:
		ball.handle_pierce(collider)
		return
	ball.push_out_y(collider, ball.move.y)
	ball.velocity.y = absf(ball.velocity.y) * signf(ball.global_position.y - collider.global_position.y)
	ball.current_speed *= velocity_factor
	ball.current_speed = clampf(ball.current_speed * velocity_factor, 0.0, ball.max_speed)
	var leftover: float = maxf(absf(ball.move.y) - absf(ball.position.y - ball.old_y), 0.0)
	ball.position.y += signf(ball.velocity.y) * leftover
