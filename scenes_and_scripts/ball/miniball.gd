# miniball.gd
class_name MiniBall extends Area2D

const DEFAULT_MINIBALL_DMG: float = 0.5

const LIGHT_BASE_ENERGY: float = 1.0
const SOFT_CATCH_DIP_SCALE: float = 3.0

const EXPIRE_BLINK_ALPHA: float = 0.4

const EXPIRE_BLINK_PERIOD: float = 0.15

@export var initial_speed: float = 500.0
var current_speed: float = 500.0
var max_speed: float = 1050.0
@export var ball_dmg: float = DEFAULT_MINIBALL_DMG
var behaviors: Array[HitBehavior]

var spawn_velocity: Vector2 = Vector2.ZERO
var life_seconds: float = 0.0
var blink_seconds: float = 1.0
var damage_scale: float = 0.5
var _life_left: float = 0.0
var _blink_time: float = 0.0

var flipped_x: bool = false
var flipped_y: bool = false

@export var brick_bounce_particles: PackedScene
@export var wall_bounce_particles: PackedScene
@export var barrier_bounce_particles: PackedScene
@export var paddle_bounce_particles: PackedScene

@export var brick_hit_score_value:int = 50
@export var wall_hit_score_value:int = 1
@export var paddle_hit_score_value:int = 1

@export var bounce_effect: BaseBounceEffectMini

## Minimum angle in degrees between the ball's path and the horizontal after any bounce;
## prevents near-flat trajectories that rattle along walls and stall the rally.
@export var min_bounce_angle_deg: float = 15.0
## Wall/brick bounces that leave the ball flatter than this (degrees from horizontal) steepen it by
## flat_decay_step_deg per bounce until it reaches this angle; paddle hits re-aim and are exempt.
@export var flat_decay_below_deg: float = 40.0
@export var flat_decay_step_deg: float = 4.0

## Below this |velocity.x| (px/s) a paddle bounce counts as a vertical serve.
@export var vertical_serve_epsilon: float = 8.0
## Consecutive vertical paddle bounces before the nudge fires; the trigger count is re-rolled
## in this range on every reset so the loop never breaks on a predictable count.
@export var vertical_serve_hits_min: int = 3
@export var vertical_serve_hits_max: int = 6
## Random rotation in degrees (random sign) applied to break a vertical serve loop.
@export var vertical_nudge_min_deg: float = 4.0
@export var vertical_nudge_max_deg: float = 9.0
var _vertical_serve_hits: int = 0
var _vertical_serve_threshold: int = 0
var _vertical_serve_checked: bool = false
var _soft_catch_pending: bool = false

@export var powerup_array: Array[BallPassive]

@export var ball_dmg_type: Array[GameManager.PhaseType]

## Seconds per full white-swap cycle of the armed tell; the sprite spends half of it solid white.
@export var active_pulse_period: float = 0.9
var _active_cooldown_left: float = 0.0
var _active_pulse_time: float = 0.0
var _speed_before_boost: float = 0.0
var _speed_boost_active: bool = false

var velocity: Vector2 = Vector2.ZERO
var on_paddle: bool = true
var _collision_set: Array[int] = []

var move: Vector2 = Vector2.ZERO
var old_x: float = 0.0
var old_y: float = 0.0

@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var _light_texture_radius: float = maxf(point_light_2d.texture.get_width() * 0.5, 1.0)

@onready var paddle: Paddle = $"../Paddle"
@onready var paddle_collision: CollisionShape2D = $"../Paddle/PaddleCollisionShape"
@onready var ball_collision: CollisionShape2D = $bounce_collision_shape
@onready var sprite: Sprite2D = $Sprite2D
var is_tweening_to_david: bool = false
@onready var ball_half_height: float = (ball_collision.shape as CircleShape2D).radius

func _ready() -> void:
	add_to_group(&"multiball")
	DP.track("Ball Velocity: ",self,"current_speed")
	bounce_effect = null
	bounce_effect = PlayerData.inventory.get_miniball_bounce()
	assert(bounce_effect != null, "no bounce effect loaded")
	Signalbus.inventory_changed.connect(repopulate_effects_from_inventory)
	repopulate_effects_from_inventory()
	get_ball_dmg_types()
	Signalbus.level_cleared.connect(remove_ball)
	Signalbus.game_state_special_room.connect(remove_ball)
	Signalbus.floor_cleared.connect(remove_ball)
	Signalbus.db_panel_closed.connect(repopulate_effects_from_inventory)
	if spawn_velocity.is_zero_approx():
		launch_ball()
	else:
		launch_from_spawn()

func get_ball_dmg_types() -> void:
	ball_dmg_type.clear()
	if ball_dmg_type.is_empty():
		ball_dmg_type.push_back(GameManager.PhaseType.HEALTH)

func remove_ball() -> void:
	on_paddle = false
	set_process(false)
	set_physics_process(false)
	queue_free()

func launch_ball() -> void:
	on_paddle = false
	_reset_vertical_serve()
	var launch_speed: float = initial_speed * SettingsManager.difficulty_mult()
	current_speed = launch_speed
	GameManager.change_state(GameManager.GameState.PLAYING)
	set_process(true)
	velocity = Vector2(float(paddle.current_speed), -launch_speed)
	velocity = velocity.normalized() * launch_speed

func launch_from_spawn() -> void:
	on_paddle = false
	_reset_vertical_serve()
	current_speed = clampf(spawn_velocity.length(), 0.0, max_speed)
	velocity = spawn_velocity
	_life_left = life_seconds
	set_process(true)

func _tick_lifetime(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		remove_ball()
		return
	if _life_left > blink_seconds:
		return
	_blink_time += delta
	var lit: bool = fmod(_blink_time, EXPIRE_BLINK_PERIOD * 2.0) < EXPIRE_BLINK_PERIOD
	sprite.modulate.a = 1.0 if lit else EXPIRE_BLINK_ALPHA

func _process(delta: float) -> void:
	if not is_inside_tree():
		print("Not In Tree")
		return
	if _life_left > 0.0:
		_tick_lifetime(delta)
		if _life_left <= 0.0:
			return
	_update_ball_light()
	flipped_x = false
	flipped_y = false
	_vertical_serve_checked = false
	move_ball(delta)

func _update_ball_light() -> void:
	var dmg: float = maxf(ball_dmg, 1.0)
	var base_scale: float = ball_half_height * sqrt(dmg) / _light_texture_radius
	point_light_2d.texture_scale = maxf(base_scale, 0.01)
	point_light_2d.energy = LIGHT_BASE_ENERGY
	
func tween_to_david(hit_pos: Vector2) -> void:
	is_tweening_to_david = true
	set_physics_process(false)
	ball_collision.set_deferred("disabled", true)

	var david: Node2D = get_tree().get_first_node_in_group("david")
	var hit_target: Node2D = david.get_node("DavidHitTarget")

	var p0: Vector2 = hit_pos
	var p2: Vector2 = hit_target.global_position
	var mid: Vector2 = (p0 + p2) * 0.5
	var sag: float = 40.0
	var p1: Vector2 = mid + Vector2(0, sag)

	var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(
		func(t: float) -> void:
			global_position = _bezier(t, p0, p1, p2),
		0.0, 1.0, 0.2
	)
	await tw.finished

func redirect_to_nearest_seal(speed_multiplier: float = 1.0) -> bool:
	var target: BaseSeal = get_nearest_seal()
	if target == null:
		return false
	var heading: Vector2 = target.global_position - global_position
	if heading.is_zero_approx():
		return false
	if not _speed_boost_active:
		_speed_before_boost = current_speed
		_speed_boost_active = true
	current_speed = _speed_before_boost * speed_multiplier
	velocity = heading.normalized() * current_speed
	return true

func end_speed_boost() -> void:
	if not _speed_boost_active:
		return
	_speed_boost_active = false
	current_speed = _speed_before_boost
	velocity = velocity.normalized() * current_speed

func get_nearest_seal() -> BaseSeal:
	var nearest_seal: BaseSeal = null
	var nearest_dist: float = INF
	for brick: Node in get_tree().get_nodes_in_group("bricks"):
		var seal: BaseSeal = brick as BaseSeal
		if seal == null or seal.dying:
			continue
		var temp_dist: float = global_position.distance_squared_to(seal.global_position)
		if temp_dist < nearest_dist:
			nearest_dist = temp_dist
			nearest_seal = seal
	return nearest_seal

func _bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var u: float = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

func repopulate_effects_from_inventory() -> void:
	powerup_array.clear()
	var items: Array = PlayerInventory.get_instance().get_items_for_ball()
	powerup_array.append_array(items)
	collect_behaviors()
	update_base_dmg()

func collect_behaviors() -> void:
	behaviors.clear()
	for powerup_ref: BallPassive in powerup_array:
		for behavior: HitBehavior in powerup_ref.on_hit:
			behaviors.append(behavior)

func update_base_dmg() -> void:
	ball_dmg = PlayerInventory.get_instance().get_ball_damage() * damage_scale

func get_paddle_half_height() -> float:
	var shape: RectangleShape2D = paddle_collision.shape as RectangleShape2D
	if absf(paddle_collision.rotation - PI / 2) < 0.1:
		return shape.size.x / 2.0
	return shape.size.y / 2.0

func update_velocity(velocity_ref: Vector2) -> void:
	velocity = velocity_ref

func _reset_vertical_serve() -> void:
	_vertical_serve_hits = 0
	_vertical_serve_threshold = randi_range(vertical_serve_hits_min, vertical_serve_hits_max)

func _check_vertical_serve() -> void:
	if _vertical_serve_checked:
		return
	_vertical_serve_checked = true
	if absf(velocity.x) >= vertical_serve_epsilon:
		_reset_vertical_serve()
		return
	_vertical_serve_hits += 1
	if _vertical_serve_hits < _vertical_serve_threshold:
		return
	var nudge_sign: float = -1.0 if randf() < 0.5 else 1.0
	var nudge_rad: float = deg_to_rad(randf_range(vertical_nudge_min_deg, vertical_nudge_max_deg))
	velocity = velocity.rotated(nudge_sign * nudge_rad)
	enforce_min_bounce_angle()
	_reset_vertical_serve()

func enforce_min_bounce_angle() -> void:
	var speed: float = velocity.length()
	if speed == 0.0:
		return
	var min_vy: float = speed * sin(deg_to_rad(min_bounce_angle_deg))
	if absf(velocity.y) >= min_vy:
		return
	var vy_sign: float = 1.0 if velocity.y == 0.0 else signf(velocity.y)
	var vx_sign: float = 1.0 if velocity.x == 0.0 else signf(velocity.x)
	var new_vy: float = min_vy * vy_sign
	var new_vx: float = sqrt(maxf(speed * speed - new_vy * new_vy, 0.0)) * vx_sign
	velocity = Vector2(new_vx, new_vy)

func apply_flat_decay() -> void:
	var speed: float = velocity.length()
	if speed == 0.0:
		return
	var angle_deg: float = rad_to_deg(atan2(absf(velocity.y), absf(velocity.x)))
	if angle_deg >= flat_decay_below_deg:
		return
	var new_angle: float = deg_to_rad(minf(angle_deg + flat_decay_step_deg, flat_decay_below_deg))
	var vx_sign: float = 1.0 if velocity.x == 0.0 else signf(velocity.x)
	var vy_sign: float = 1.0 if velocity.y == 0.0 else signf(velocity.y)
	velocity = Vector2(cos(new_angle) * vx_sign, sin(new_angle) * vy_sign) * speed

func _bounce_axis_is_y(collider: Node2D) -> bool:
	var half: Vector2 = get_collider_half_size(collider)
	var diff: Vector2 = global_position - collider.global_position
	var pen_x: float = half.x + ball_half_height - absf(diff.x)
	var pen_y: float = half.y + ball_half_height - absf(diff.y)
	return pen_y < pen_x

func move_ball(delta: float) -> void:
	if bounce_effect != null and not bounce_effect.pierce_brick:
		resolve_frame_start_overlaps()
	if not _collision_set.is_empty():
		clean_collision_set()
	var frame_move: Vector2 = velocity.normalized() * current_speed * delta
	var steps: int = maxi(1, ceili(maxf(absf(frame_move.x), absf(frame_move.y)) / ball_half_height))
	var step_delta: float = delta / float(steps)
	for _i: int in steps:
		move_ball_step(step_delta)
		if on_paddle or flipped_x or flipped_y:
			return

func resolve_frame_start_overlaps() -> void:
	for collider: Node2D in query_collisions():
		if not (collider.is_in_group("bricks") or collider.is_in_group("walls") or collider.is_in_group("bounce_enemy") or collider.is_in_group("barrier")):
			continue
		var half: Vector2 = get_collider_half_size(collider)
		var diff: Vector2 = global_position - collider.global_position
		var pen_x: float = half.x + ball_half_height - absf(diff.x)
		var pen_y: float = half.y + ball_half_height - absf(diff.y)
		if pen_x <= 0.0 or pen_y <= 0.0:
			continue
		end_speed_boost()
		if collider.is_in_group("bounce_enemy"):
			apply_collider_effects(collider)
		var dir_x: float = 1.0 if diff.x == 0.0 else signf(diff.x)
		var dir_y: float = 1.0 if diff.y == 0.0 else signf(diff.y)
		if pen_x < pen_y:
			position.x = collider.global_position.x + (half.x + ball_half_height + 0.5) * dir_x
			velocity.x = absf(velocity.x) * dir_x
		else:
			position.y = collider.global_position.y + (half.y + ball_half_height + 0.5) * dir_y
			velocity.y = absf(velocity.y) * dir_y

func move_ball_step(delta: float) -> void:
	velocity = velocity.normalized() * current_speed
	move = velocity * delta
	var hit_this_step: Array[int] = []
	var effects_this_step: Array[int] = []

	old_x = position.x
	position.x += move.x
	var x_collisions: Array[Node2D] = query_collisions()
	for collider: Node2D in x_collisions:
		if collider.get_instance_id() in hit_this_step:
			continue
		hit_this_step.append(collider.get_instance_id())
		if collider.get_instance_id() not in effects_this_step:
			effects_this_step.append(collider.get_instance_id())
			apply_collider_effects(collider)
			if on_paddle:
				return
			spawn_collision_feedback(collider)
			end_speed_boost()
		if collider.is_in_group("paddle"):
			if !flipped_x:
				bounce_effect.handle_paddle_collision(self, collider as Paddle)
				_check_vertical_serve()
				flipped_x = true
		elif collider.is_in_group(GhostPaddle.GHOST_PADDLE_GROUP):
			if !flipped_x:
				bounce_effect.handle_paddle_collision(self, paddle)
				_check_vertical_serve()
				flipped_x = true
		elif collider.is_in_group("bricks") or collider.is_in_group("walls") or collider.is_in_group("bounce_enemy") or collider.is_in_group("barrier"):
			if _bounce_axis_is_y(collider):
				if !flipped_y:
					bounce_effect.handle_y_collision(self, collider)
					flipped_y = true
			elif !flipped_x:
				bounce_effect.handle_x_collision(self, collider)
				flipped_x = true

	hit_this_step.clear()
	old_y = position.y
	position.y += move.y
	var y_collisions: Array[Node2D] = query_collisions()
	for collider: Node2D in y_collisions:
		if collider.get_instance_id() in hit_this_step:
			continue
		hit_this_step.append(collider.get_instance_id())
		if collider.get_instance_id() not in effects_this_step:
			effects_this_step.append(collider.get_instance_id())
			apply_collider_effects(collider)
			if on_paddle:
				return
			spawn_collision_feedback(collider)
			end_speed_boost()
		if collider.is_in_group("paddle"):
			if !flipped_y:
				bounce_effect.handle_paddle_collision(self, collider as Paddle)
				_check_vertical_serve()
				flipped_y = true
		elif collider.is_in_group(GhostPaddle.GHOST_PADDLE_GROUP):
			if !flipped_y:
				bounce_effect.handle_paddle_collision(self, paddle)
				_check_vertical_serve()
				flipped_y = true
		elif collider.is_in_group("bricks") or collider.is_in_group("walls") or collider.is_in_group("bounce_enemy") or collider.is_in_group("barrier"):
			if not _bounce_axis_is_y(collider):
				if !flipped_x:
					bounce_effect.handle_x_collision(self, collider)
					flipped_x = true
			elif !flipped_y:
				bounce_effect.handle_y_collision(self, collider)
				flipped_y = true

func spawn_collision_feedback(collider: Node2D) -> void:
	var fx: Node2D = null
	if collider.is_in_group("bricks"):
		fx = brick_bounce_particles.instantiate()
		SFX.play_sound("hit-brick")
		PlayerData.update_player_score(brick_hit_score_value)
		if collider.has_method("hit_knockback"):
			collider.call("hit_knockback", velocity.normalized())
	if collider.is_in_group("walls"):
		fx = wall_bounce_particles.instantiate()
		SFX.play_sound("bounce_1")
		PlayerData.update_player_score(wall_hit_score_value)
		Signalbus.wall_hit.emit(self, collider, ball_dmg, ball_dmg_type)
		TileShake.shake(collider, 0.0, TileShake.DIRECT_HIT_SCALE)
	if collider.is_in_group("barrier"):
		fx = barrier_bounce_particles.instantiate()
		SFX.play_sound("bounce_barrier")
	if collider.is_in_group(GhostPaddle.GHOST_PADDLE_GROUP):
		fx = paddle_bounce_particles.instantiate()
		SFX.play_sound("hit-paddle")
		PlayerData.update_player_score(paddle_hit_score_value)
		paddle.bounce_dip()
	if collider.is_in_group("paddle"):
		var hit_paddle: Paddle = collider as Paddle
		_soft_catch_pending = hit_paddle.try_soft_catch()
		fx = paddle_bounce_particles.instantiate()
		SFX.play_sound("win_sting" if _soft_catch_pending else "hit-paddle")
		PlayerData.update_player_score(paddle_hit_score_value)
		if _soft_catch_pending:
			hit_paddle.soft_catch_flash()
		hit_paddle.bounce_dip(SOFT_CATCH_DIP_SCALE if _soft_catch_pending else 1.0)
	if fx != null:
		fx.position = global_position
		get_tree().current_scene.add_child(fx)

# --- Collision query ---

func query_collisions() -> Array[Node2D]:
	if not is_inside_tree():
		return []
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = ball_collision.shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var results: Array[Dictionary] = space.intersect_shape(query)
	var colliders: Array[Node2D] = []
	for result: Dictionary in results:
		if result.has("collider") and result["collider"] is Node2D:
			colliders.append(result["collider"])
	return colliders

# --- Push-out helpers ---

func push_out_x(collider: Node2D, _move_x: float) -> void:
	var half: Vector2 = get_collider_half_size(collider)
	var r: float = ball_half_height
	if global_position.x < collider.global_position.x:
		position.x = collider.global_position.x - half.x - r - 0.5
	else:
		position.x = collider.global_position.x + half.x + r + 0.5

func push_out_y(collider: Node2D, _move_y: float) -> void:
	var half: Vector2 = get_collider_half_size(collider)
	var r: float = ball_half_height
	if global_position.y < collider.global_position.y:
		position.y = collider.global_position.y - half.y - r - 0.5
	else:
		position.y = collider.global_position.y + half.y + r + 0.5

func get_collider_half_size(collider: Node2D) -> Vector2:
	var col_shape: CollisionShape2D = collider.get_node("CollisionShape2D")
	var shape: RectangleShape2D = col_shape.shape as RectangleShape2D
	return (shape.size * col_shape.scale * collider.global_scale).abs() / 2.0

# --- Collision tracking ---

func handle_pierce(collider: Node2D) -> void:
	_collision_set.append(collider.get_instance_id())

func clean_collision_set() -> void:
	var current_ids: Array[int] = []
	for c: Node2D in query_collisions():
		current_ids.append(c.get_instance_id())
	_collision_set = _collision_set.filter(func(id: int) -> bool: return id in current_ids)

func apply_collider_effects(collider: Node2D) -> void:
	if collider.get_instance_id() in _collision_set:
		return
	var ctx: HitContext = _make_hit_context()
	for behavior: HitBehavior in behaviors:
		behavior.apply(ctx, collider)
	if collider.is_in_group("bounce_enemy"):
		_collision_set.append(collider.get_instance_id())

func _make_hit_context() -> HitContext:
	var ctx: HitContext = HitContext.new()
	ctx.source = self
	ctx.hit_point = global_position
	ctx.collision_mask = collision_mask
	ctx.exclude = [get_rid()]
	ctx.base_damage = ball_dmg
	ctx.dmg_types = ball_dmg_type
	ctx.apply = apply_damage_to
	return ctx

# per-target application; group decides the reaction
func apply_damage_to(target: Node2D, amount: float, dmg_types: Array) -> void:
	if target.is_in_group("bricks") or target.is_in_group("bounce_enemy"):
		target.call("accept_damage", amount, dmg_types)

