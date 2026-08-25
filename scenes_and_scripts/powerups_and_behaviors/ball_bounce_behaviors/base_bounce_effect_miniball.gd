# base_bounce_effect.gd
class_name BaseBounceEffectMini extends BaseItem

@export var pierce_brick: bool = false
@export var velocity_factor: float = 1.002

func handle_paddle_collision(miniball: MiniBall, paddle: Paddle) -> void:
	var hit_pos: float = miniball.global_position.x - paddle.global_position.x
	var new_vel: Vector2
	if absf(hit_pos) >= paddle.collision_half_width() - paddle.edge_zone_px:
		var exit_rad: float = deg_to_rad(paddle.edge_exit_angle_deg)
		new_vel = Vector2(cos(exit_rad) * signf(hit_pos), -sin(exit_rad)) * miniball.current_speed
	else:
		new_vel = miniball.velocity
		new_vel.x = hit_pos * paddle.paddle_influence
		new_vel.y = -absf(new_vel.y)
		new_vel = new_vel.normalized() * miniball.current_speed
	miniball.current_speed = clampf(miniball.current_speed * velocity_factor, 0.0, miniball.max_speed)
	miniball.update_velocity(new_vel)
	miniball.enforce_min_bounce_angle()

func handle_x_collision(miniball: MiniBall, collider: Node2D) -> void:
	if pierce_brick:
		miniball.handle_pierce(collider)
		return
	miniball.push_out_x(collider, miniball.move.x)
	miniball.velocity.x = absf(miniball.velocity.x) * signf(miniball.global_position.x - collider.global_position.x)
	miniball.current_speed *= velocity_factor
	miniball.current_speed = clampf(miniball.current_speed * velocity_factor, 0.0, miniball.max_speed)
	var leftover: float = maxf(absf(miniball.move.x) - absf(miniball.position.x - miniball.old_x), 0.0)
	miniball.position.x += signf(miniball.velocity.x) * leftover
	miniball.apply_flat_decay(collider)
	miniball.enforce_min_bounce_angle()

func handle_y_collision(miniball: MiniBall, collider: Node2D) -> void:
	if pierce_brick:
		miniball.handle_pierce(collider)
		return
	miniball.push_out_y(collider, miniball.move.y)
	miniball.velocity.y = absf(miniball.velocity.y) * signf(miniball.global_position.y - collider.global_position.y)
	miniball.current_speed *= velocity_factor
	miniball.current_speed = clampf(miniball.current_speed * velocity_factor, 0.0, miniball.max_speed)
	var leftover: float = maxf(absf(miniball.move.y) - absf(miniball.position.y - miniball.old_y), 0.0)
	miniball.position.y += signf(miniball.velocity.y) * leftover
	miniball.apply_flat_decay(collider)
	miniball.enforce_min_bounce_angle()
