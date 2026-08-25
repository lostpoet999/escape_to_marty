# base_bounce_effect.gd
class_name BaseBounceEffect extends BaseItem

@export var pierce_brick: bool = false
@export var velocity_factor: float = 1.002

func handle_paddle_collision(ball: Ball, paddle: Paddle) -> void:
	var hit_pos: float = ball.global_position.x - paddle.global_position.x
	var fraction: float = clampf(hit_pos / paddle.collision_half_width(), -1.0, 1.0)
	var exit_rad: float = deg_to_rad(lerpf(90.0, paddle.edge_exit_angle_deg, absf(fraction)))
	var new_vel: Vector2 = Vector2(cos(exit_rad) * signf(fraction), -sin(exit_rad)) * ball.current_speed
	ball.current_speed = clampf(ball.current_speed * velocity_factor, 0.0, ball.speed_cap())
	ball.update_velocity(new_vel)
	ball.enforce_min_bounce_angle()

func handle_x_collision(ball: Ball, collider: Node2D) -> void:
	if pierce_brick:
		ball.handle_pierce(collider)
		return
	ball.push_out_x(collider, ball.move.x)
	ball.velocity.x = absf(ball.velocity.x) * signf(ball.global_position.x - collider.global_position.x)
	ball.current_speed *= velocity_factor
	ball.current_speed = clampf(ball.current_speed * velocity_factor, 0.0, ball.speed_cap())
	var leftover: float = maxf(absf(ball.move.x) - absf(ball.position.x - ball.old_x), 0.0)
	ball.position.x += signf(ball.velocity.x) * leftover
	ball.apply_flat_decay()
	ball.enforce_min_bounce_angle()

func handle_y_collision(ball: Ball, collider: Node2D) -> void:
	if pierce_brick:
		ball.handle_pierce(collider)
		return
	ball.push_out_y(collider, ball.move.y)
	ball.velocity.y = absf(ball.velocity.y) * signf(ball.global_position.y - collider.global_position.y)
	ball.current_speed *= velocity_factor
	ball.current_speed = clampf(ball.current_speed * velocity_factor, 0.0, ball.speed_cap())
	var leftover: float = maxf(absf(ball.move.y) - absf(ball.position.y - ball.old_y), 0.0)
	ball.position.y += signf(ball.velocity.y) * leftover
	ball.apply_flat_decay()
	ball.enforce_min_bounce_angle()
