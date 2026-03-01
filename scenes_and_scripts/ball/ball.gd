class_name Ball
extends Area2D

const DEFAULT_BALL_DMG: int = 1

@export var initial_speed: float = 500.0
@export var ball_dmg: float = DEFAULT_BALL_DMG
var damage_effects: Array[BaseDamageEffect]

#power-up and effects references:
@export var bounce_effect_scene: PackedScene
var bounce_effect: BaseBounceEffect
@export var powerup_array: Array[BallPowerUp]

var velocity: Vector2 = Vector2.ZERO
var on_paddle: bool = true
var _collision_set: Array[int] = []

@onready var paddle: Paddle = $"../Paddle"
@onready var paddle_collision: CollisionShape2D = $"../Paddle/CollisionShape2D"
@onready var ball_collision: CollisionShape2D = $CollisionShape2D
@onready var ball_half_height: float = (ball_collision.shape as CircleShape2D).radius
@onready var effects_node: Node = $Effects


func _ready() -> void:
	position_ball_on_paddle()
	bounce_effect = bounce_effect_scene.instantiate() as BaseBounceEffect
	add_child(bounce_effect)
	instantiate_all_effects()
	update_base_dmg()

func _process(delta: float) -> void:
	if on_paddle:
		position_ball_on_paddle()
	else:
		move_ball(delta)

func position_ball_on_paddle() -> void:
	var offset: float = ball_half_height + get_paddle_half_height() + 1.0
	position = paddle.global_position + Vector2(0, -offset)
	on_paddle = true

func instantiate_all_effects() -> void:
	for powerup_ref: BallPowerUp in powerup_array:
		for effect_ref: DamageEffectRef in powerup_ref.attached_effects:
			var effect: BaseDamageEffect = effect_ref.instantiate_effect()
			effects_node.add_child(effect)
			damage_effects.append(effect)

func update_base_dmg() -> void:
	ball_dmg = DEFAULT_BALL_DMG
	for powerup_ref: BallPowerUp in powerup_array:
		ball_dmg += powerup_ref.global_damage_bonus
	for powerup_ref: BallPowerUp in powerup_array:
		ball_dmg *= powerup_ref.global_damage_multi

func get_paddle_half_height() -> float:
	var shape: RectangleShape2D = paddle_collision.shape as RectangleShape2D
	if absf(paddle_collision.rotation - PI / 2) < 0.1:
		return shape.size.x / 2.0
	return shape.size.y / 2.0

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_mouse") and on_paddle:
		launch_ball()

func launch_ball() -> void:
	on_paddle = false
	set_process(true)
	velocity = Vector2(float(paddle.current_speed), -initial_speed)
	velocity = velocity.normalized() * initial_speed

func update_velocity(velocity_ref: Vector2) -> void:
	velocity = velocity_ref

func move_ball(delta: float) -> void:
	velocity = velocity.normalized() * initial_speed
	var move := velocity * delta
	var hit_this_step: Array[int] = []

	if not _collision_set.is_empty():
		clean_collision_set()

	# --- X step ---
	var old_x := position.x
	position.x += move.x
	var x_collisions := query_collisions()
	var flip_x := false
	for collider in x_collisions:
		if collider.get_instance_id() in hit_this_step:
			continue
		hit_this_step.append(collider.get_instance_id())

		apply_collider_effects(collider)
		if on_paddle:
			return

		if collider.is_in_group("paddle"):
			bounce_effect.handle_paddle_collision(self, collider as Paddle)
		elif collider.is_in_group("bricks") or collider.is_in_group("walls"):
			if bounce_effect.should_bounce(collider):
				push_out_x(collider, move.x)
				flip_x = true
			else:
				handle_pierce(collider)

	if flip_x:
		velocity.x *= -1
		var leftover := absf(move.x) - absf(position.x - old_x)
		position.x += sign(-move.x) * leftover

	# --- Y step ---
	var old_y := position.y
	position.y += move.y
	var y_collisions := query_collisions()
	var flip_y := false
	for collider in y_collisions:
		if collider.get_instance_id() in hit_this_step:
			continue
		hit_this_step.append(collider.get_instance_id())

		apply_collider_effects(collider)
		if on_paddle:
			return

		if collider.is_in_group("paddle"):
			bounce_effect.handle_paddle_collision(self, collider as Paddle)
		elif collider.is_in_group("bricks") or collider.is_in_group("walls"):
			if bounce_effect.should_bounce(collider):
				push_out_y(collider, move.y)
				flip_y = true
			else:
				handle_pierce(collider)

	if flip_y:
		velocity.y *= -1
		var leftover := absf(move.y) - absf(position.y - old_y)
		position.y += sign(-move.y) * leftover

# --- Collision query ---

func query_collisions() -> Array[Node2D]:	
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = ball_collision.shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var results := space.intersect_shape(query)
	var colliders: Array[Node2D] = []
	for result in results:
		var c := result["collider"] as Node2D
		if c:
			colliders.append(c)
	return colliders

# --- Push-out helpers ---

func push_out_x(collider: Node2D, move_x: float) -> void:
	var half := get_collider_half_size(collider)
	var r := ball_half_height
	if move_x > 0:
		position.x = collider.global_position.x - half.x - r - 0.5
	else:
		position.x = collider.global_position.x + half.x + r + 0.5

func push_out_y(collider: Node2D, move_y: float) -> void:
	var half := get_collider_half_size(collider)
	var r := ball_half_height
	if move_y > 0:
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
	for c in query_collisions():
		current_ids.append(c.get_instance_id())
	_collision_set = _collision_set.filter(func(id: int) -> bool: return id in current_ids)

func apply_collider_effects(collider: Node2D) -> void:
	if collider.get_instance_id() in _collision_set:
		return
	for effect: BaseDamageEffect in damage_effects:
		effect.process_damage(self, collider)
