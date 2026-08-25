class_name Multiball extends BallActive

const MINIBALL: PackedScene = preload("uid://b60sitvla23kq")

@export var min_balls: int = 2
@export var max_balls: int = 4
## Half-width of the spawn fan in degrees; the balls are spaced evenly from -this to +this
## around the ball's current heading, so the fan reads the same at any ball count.
@export var spread_deg: float = 20.0
@export var life_min_seconds: float = 5.0
@export var life_max_seconds: float = 8.0
## Seconds of alpha flicker before a spawned ball expires, so the despawn is telegraphed.
@export var blink_seconds: float = 1.0
## Share of the ball's damage each spawned ball deals.
@export var damage_scale: float = 0.5


func activate(ball: Ball) -> bool:
	var host: Node = ball.get_parent()
	if host == null:
		return false
	var heading: Vector2 = ball.velocity
	if heading.is_zero_approx():
		heading = Vector2.UP
	heading = heading.normalized()
	var count: int = randi_range(min_balls, max_balls)
	for i: int in count:
		var offset_deg: float = 0.0
		if count > 1:
			offset_deg = lerpf(-spread_deg, spread_deg, float(i) / float(count - 1))
		var spawned: MiniBall = MINIBALL.instantiate() as MiniBall
		spawned.spawn_velocity = heading.rotated(deg_to_rad(offset_deg)) * ball.current_speed
		spawned.life_seconds = randf_range(life_min_seconds, life_max_seconds)
		spawned.blink_seconds = blink_seconds
		spawned.damage_scale = damage_scale
		host.add_child(spawned)
		spawned.global_position = ball.global_position
	return true
