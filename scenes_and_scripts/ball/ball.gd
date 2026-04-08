# ball.gd
class_name Ball extends Area2D

const DEFAULT_BALL_DMG: int = 1

@export var initial_speed: float = 500.0
var current_speed: float = 500.0
var max_speed: float = 1500.0
@export var ball_dmg: float = DEFAULT_BALL_DMG
var damage_effects: Array[BaseDamageEffect]

var flipped_x: bool = false
var flipped_y: bool = false

@export var brick_bounce_particles: PackedScene
@export var wall_bounce_particles: PackedScene
@export var paddle_bounce_particles: PackedScene

@export var bounce_effect: BaseBounceEffect

@export var powerup_array: Array[BallPowerUp]

@export var ball_dmg_type: Array[GameManager.PhaseType]

var velocity: Vector2 = Vector2.ZERO
var on_paddle: bool = true
var _collision_set: Array[int] = []

var move: Vector2 = Vector2.ZERO
var old_x: float = 0.0
var old_y: float = 0.0

@onready var paddle: Paddle = $"../Paddle"
@onready var paddle_collision: CollisionShape2D = $"../Paddle/PaddleCollisionShape"
@onready var ball_collision: CollisionShape2D = $bounce_collision_shape

@onready var ball_half_height: float = (ball_collision.shape as CircleShape2D).radius
@onready var effects_node: Node = $Effects

func _ready() -> void:	
	DP.track("Ball Velocity: ",self,"current_speed")
	position_ball_on_paddle()
	bounce_effect = null
	bounce_effect = PlayerData.inventory.get_ball_bounce()
	assert(bounce_effect != null, "no bounce effect loaded")
	Signalbus.inventory_changed.connect(repopulate_effects_from_inventory)
	repopulate_effects_from_inventory()
	instantiate_all_effects()
	get_ball_dmg_types()
	update_base_dmg()
	Signalbus.level_cleared.connect(remove_ball)
	Signalbus.game_state_special_room.connect(remove_ball)
	Signalbus.db_panel_closed.connect(repopulate_effects_from_inventory)

func get_ball_dmg_types() -> void:
	ball_dmg_type.clear()
	if ball_dmg_type.is_empty():
		ball_dmg_type.push_back(GameManager.PhaseType.HEALTH)

func remove_ball() -> void:
	on_paddle = false
	queue_free()



func _process(delta: float) -> void:
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
	GameManager.change_state(GameManager.GameState.BALL_ON_PADDLE)

func repopulate_effects_from_inventory() -> void:
	powerup_array.clear()
	var items: Array = PlayerInventory.get_instance().get_items_for_ball()
	powerup_array.append_array(items)

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
	if Input.is_action_just_pressed("left_mouse") and on_paddle and GameManager.GameState.BALL_ON_PADDLE:
		launch_ball()

func launch_ball() -> void:
	on_paddle = false
	current_speed = initial_speed
	GameManager.change_state(GameManager.GameState.PLAYING)
	set_process(true)
	velocity = Vector2(float(paddle.current_speed), -initial_speed)
	velocity = velocity.normalized() * initial_speed

func update_velocity(velocity_ref: Vector2) -> void:
	velocity = velocity_ref

func move_ball(delta: float) -> void:
	velocity = velocity.normalized() * current_speed
	move = velocity * delta
	var hit_this_step: Array[int] = []

	if not _collision_set.is_empty():
		clean_collision_set()

	old_x = position.x
	position.x += move.x
	var x_collisions: Array[Node2D] = query_collisions()
	for collider: Node2D in x_collisions:
		if collider.get_instance_id() in hit_this_step:
			continue
		hit_this_step.append(collider.get_instance_id())
		apply_collider_effects(collider)
		if on_paddle:
			return
		var fx: Node2D = null
		if collider.is_in_group("bricks"):
			fx = brick_bounce_particles.instantiate()
			SFX.play_sound("hit-brick")
		if collider.is_in_group("walls"):
			fx = wall_bounce_particles.instantiate()
			SFX.play_sound("bounce_1")			
		if collider.is_in_group("paddle"):
			fx = paddle_bounce_particles.instantiate()
			SFX.play_sound("hit-paddle")
			
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		
		if collider.is_in_group("paddle"):
			if !flipped_x:
				bounce_effect.handle_paddle_collision(self, collider as Paddle)
				flipped_x = true
		elif collider.is_in_group("bricks") or collider.is_in_group("walls"):
			if !flipped_x:
				bounce_effect.handle_x_collision(self, collider)
				flipped_x = true

	old_y = position.y
	position.y += move.y
	var y_collisions: Array[Node2D] = query_collisions()
	for collider: Node2D in y_collisions:
		if collider.get_instance_id() in hit_this_step:
			continue
		hit_this_step.append(collider.get_instance_id())
		apply_collider_effects(collider)
		if on_paddle:
			return
		var fx: Node2D = null
		if collider.is_in_group("bricks"):
			fx = brick_bounce_particles.instantiate()
			SFX.play_sound("hit-brick")
		if collider.is_in_group("walls"):
			fx = wall_bounce_particles.instantiate()			
			SFX.play_sound("bounce_1")		
		if collider.is_in_group("paddle"):
			fx = paddle_bounce_particles.instantiate()
			SFX.play_sound("hit-paddle")
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)		
		
		if collider.is_in_group("paddle"):
			if !flipped_y:
				bounce_effect.handle_paddle_collision(self, collider as Paddle)
				flipped_y = true
		elif collider.is_in_group("bricks") or collider.is_in_group("walls"):
			if !flipped_y:
				bounce_effect.handle_y_collision(self, collider)
				flipped_y = true

# --- Collision query ---

func query_collisions() -> Array[Node2D]:
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

func push_out_x(collider: Node2D, move_x: float) -> void:
	var half: Vector2 = get_collider_half_size(collider)
	var r: float = ball_half_height
	if move_x > 0:
		position.x = collider.global_position.x - half.x - r - 0.5
	else:
		position.x = collider.global_position.x + half.x + r + 0.5

func push_out_y(collider: Node2D, move_y: float) -> void:
	var half: Vector2 = get_collider_half_size(collider)
	var r: float = ball_half_height
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
	for c: Node2D in query_collisions():
		current_ids.append(c.get_instance_id())
	_collision_set = _collision_set.filter(func(id: int) -> bool: return id in current_ids)

func apply_collider_effects(collider: Node2D) -> void:
	if collider.get_instance_id() in _collision_set:
		return
	for effect: BaseDamageEffect in damage_effects:
		effect.process_damage(self, collider, ball_dmg_type)
