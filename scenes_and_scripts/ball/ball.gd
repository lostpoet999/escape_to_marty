# ball.gd
class_name Ball extends Area2D

const DEFAULT_BALL_DMG: int = 1

@export var initial_speed: float = 500.0
var current_speed: float = 500.0
var max_speed: float = 1500.0
@export var ball_dmg: float = DEFAULT_BALL_DMG
var behaviors: Array[HitBehavior]

var flipped_x: bool = false
var flipped_y: bool = false

@export var brick_bounce_particles: PackedScene
@export var wall_bounce_particles: PackedScene
@export var paddle_bounce_particles: PackedScene

@export var brick_hit_score_value:int = 50
@export var wall_hit_score_value:int = 1
@export var paddle_hit_score_value:int = 1

@export var bounce_effect: BaseBounceEffect

@export var powerup_array: Array[BallPassive]

@export var ball_dmg_type: Array[GameManager.PhaseType]

## Gates the ball_activate_powerup input; stays false until the player owns the homing powerup.
@export var has_homing_powerup: bool = false

var velocity: Vector2 = Vector2.ZERO
var on_paddle: bool = true
var _collision_set: Array[int] = []

var move: Vector2 = Vector2.ZERO
var old_x: float = 0.0
var old_y: float = 0.0

var time : float = 0.0
@onready var point_light_2d: PointLight2D = $PointLight2D

@onready var paddle: Paddle = $"../Paddle"
@onready var paddle_collision: CollisionShape2D = $"../Paddle/PaddleCollisionShape"
@onready var ball_collision: CollisionShape2D = $bounce_collision_shape
var is_tweening_to_david: bool = false
var is_tweening_to_nearest_brick: bool = false
var nearest_brick_tween: Tween = null

@onready var ball_half_height: float = (ball_collision.shape as CircleShape2D).radius

func _ready() -> void:
	add_to_group(&"ball")
	DP.track("Ball Velocity: ",self,"current_speed")
	position_ball_on_paddle()
	bounce_effect = null
	bounce_effect = PlayerData.inventory.get_ball_bounce()
	assert(bounce_effect != null, "no bounce effect loaded")
	Signalbus.inventory_changed.connect(repopulate_effects_from_inventory)
	repopulate_effects_from_inventory()
	get_ball_dmg_types()
	Signalbus.level_cleared.connect(remove_ball)
	Signalbus.game_state_special_room.connect(remove_ball)
	Signalbus.floor_cleared.connect(remove_ball)
	Signalbus.db_panel_closed.connect(repopulate_effects_from_inventory)

func get_ball_dmg_types() -> void:
	ball_dmg_type.clear()
	if ball_dmg_type.is_empty():
		ball_dmg_type.push_back(GameManager.PhaseType.HEALTH)

func remove_ball() -> void:
	on_paddle = false
	set_process(false)
	set_physics_process(false)
	queue_free()



func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	time += delta
	point_light_2d.energy = 1.0 + sin(time * 3.0) * 0.15
	flipped_x = false
	flipped_y = false
	if on_paddle:
		position_ball_on_paddle()
	else:
		move_ball(delta)

func position_ball_on_paddle() -> void:
	var offset: float = ball_half_height + get_paddle_half_height() + 1
	position = paddle.global_position + Vector2(0, -offset)
	on_paddle = true
	ball_collision.set_deferred("disabled", false)
	set_physics_process(true)
	is_tweening_to_david = false
	cancel_tween_to_nearest_brick()
	GameManager.change_state(GameManager.GameState.BALL_ON_PADDLE)
	

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

func tween_to_nearest_brick() -> void:
	if is_tweening_to_nearest_brick == true:
		return
	var nearest_brick: Node = get_nearest_brick()
	if nearest_brick == null:
		return
	is_tweening_to_nearest_brick = true
	set_physics_process(false)
	var p0: Vector2 = position
	var p2: Vector2 = nearest_brick.global_position
	var mid: Vector2 = (p0 + p2) * 0.5
	var sag: float = 20.0
	var p1: Vector2 = mid + Vector2(sag, 0)
	nearest_brick_tween = create_tween().set_trans(Tween.TRANS_SINE)
	nearest_brick_tween.tween_method(
		func(t: float) -> void:
			if is_tweening_to_nearest_brick == false:
				return
			global_position = _bezier(t, p0, p1, p2),
			0.0, 1.0, 0.3
	)
	nearest_brick_tween.finished.connect(cancel_tween_to_nearest_brick)

func cancel_tween_to_nearest_brick() -> void:
	if is_tweening_to_nearest_brick == false:
		return
	is_tweening_to_nearest_brick = false
	if nearest_brick_tween != null and nearest_brick_tween.is_valid():
		nearest_brick_tween.kill()
	nearest_brick_tween = null
	set_physics_process(true)

func get_nearest_brick() -> Node:
	var bricks: Array[Node] = get_tree().get_nodes_in_group("bricks")
	if bricks.is_empty():
		return null
	var p0: Vector2 = position
	var nearest_brick: Node = bricks[0]
	var p1: Vector2 = nearest_brick.position
	var nearest_dist: float = global_position.distance_to(nearest_brick.position)
	for i in range (bricks.size()):
		var brick = bricks[i]
		var temp_dist: float = global_position.distance_to(brick.position)
		if temp_dist < nearest_dist:
			nearest_dist = temp_dist
			nearest_brick = brick
	return nearest_brick

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
	ball_dmg = PlayerInventory.get_instance().get_ball_damage()

func get_paddle_half_height() -> float:
	var shape: RectangleShape2D = paddle_collision.shape as RectangleShape2D
	if absf(paddle_collision.rotation - PI / 2) < 0.1:
		return shape.size.x / 2.0
	return shape.size.y / 2.0

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_mouse") and on_paddle and GameManager.current_state == GameManager.GameState.BALL_ON_PADDLE:
		print("mouse pressed")
		launch_ball()
	if Input.is_action_just_pressed("ball_activate_powerup"):
		if has_homing_powerup and not on_paddle and GameManager.current_state == GameManager.GameState.PLAYING:
			tween_to_nearest_brick()

func launch_ball() -> void:
	on_paddle = false
	var launch_speed: float = initial_speed * SettingsManager.difficulty_mult()
	current_speed = launch_speed
	GameManager.change_state(GameManager.GameState.PLAYING)
	set_process(true)
	velocity = Vector2(float(paddle.current_speed), -launch_speed)
	velocity = velocity.normalized() * launch_speed

func update_velocity(velocity_ref: Vector2) -> void:
	velocity = velocity_ref

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
		if not (collider.is_in_group("bricks") or collider.is_in_group("walls") or collider.is_in_group("bounce_enemy")):
			continue
		var half: Vector2 = get_collider_half_size(collider)
		var diff: Vector2 = global_position - collider.global_position
		var pen_x: float = half.x + ball_half_height - absf(diff.x)
		var pen_y: float = half.y + ball_half_height - absf(diff.y)
		if pen_x <= 0.0 or pen_y <= 0.0:
			continue
		cancel_tween_to_nearest_brick()
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
		if collider.is_in_group("paddle"):
			if !flipped_x:
				bounce_effect.handle_paddle_collision(self, collider as Paddle)
				flipped_x = true
		elif collider.is_in_group("bricks") or collider.is_in_group("walls") or collider.is_in_group("bounce_enemy"):
			cancel_tween_to_nearest_brick()
			if !flipped_x:
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
		if collider.is_in_group("paddle"):
			if !flipped_y:
				bounce_effect.handle_paddle_collision(self, collider as Paddle)
				flipped_y = true
		elif collider.is_in_group("bricks") or collider.is_in_group("walls") or collider.is_in_group("bounce_enemy"):
			cancel_tween_to_nearest_brick()
			if !flipped_y:
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
	if collider.is_in_group("paddle"):
		fx = paddle_bounce_particles.instantiate()
		SFX.play_sound("hit-paddle")
		PlayerData.update_player_score(paddle_hit_score_value)
		(collider as Paddle).bounce_dip()
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
	elif target.is_in_group("DeathWalls"):
		if is_tweening_to_david:
			return
		await tween_to_david(global_position)
		PlayerData.accept_reflect_damage(amount)
		position_ball_on_paddle()
