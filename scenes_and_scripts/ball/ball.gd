# ball.gd
class_name Ball extends Area2D

const DEFAULT_BALL_DMG: int = 1

const LIGHT_BASE_ENERGY: float = 1.0

const ARMED_FLASH_SHADER: Shader = preload("uid://gnsjmtflfbxt")

const ENEMY_PUSH_COOLDOWN: float = 0.12

const SOFT_CATCH_DIP_SCALE: float = 3.0

const ARMED_FLASH_COLOR: Color = Color("73bed3")

const MEDITATION_GRAY: Color = Color(0.55, 0.55, 0.55, 1.0)

const MEDITATION_BLINK_ALPHA: float = 0.4

const MEDITATION_BLINK_PERIOD: float = 0.2

const BLEND_IN_ALPHA: float = 0.4

@export var initial_speed: float = 500.0
## Speed multiplier applied when the paddle soft-catches the ball; the result is floored at launch speed.
@export var soft_catch_factor: float = 0.85
var current_speed: float = 500.0
var max_speed: float = 1050.0
@export var ball_dmg: float = DEFAULT_BALL_DMG
var behaviors: Array[HitBehavior]

var flipped_x: bool = false
var flipped_y: bool = false

@export var brick_bounce_particles: PackedScene
@export var wall_bounce_particles: PackedScene
@export var barrier_bounce_particles: PackedScene
@export var paddle_bounce_particles: PackedScene
@export var enemy_bounce_particles: PackedScene

@export var brick_hit_score_value:int = 50
@export var wall_hit_score_value:int = 1
@export var paddle_hit_score_value:int = 1

@export var seal_hit_trauma: float = 0.2
@export var barrier_hit_trauma: float = 0.26

@export var bounce_effect: BaseBounceEffect

## Minimum angle in degrees between the ball's path and the horizontal;
## prevents near-flat trajectories that rattle along walls and stall the rally.
@export var min_bounce_angle_deg: float = 20.0
## Consecutive non-paddle bounces below min_bounce_angle_deg before the clamp fires;
## paddle hits and any bounce at or above the angle reset the count.
@export var flat_bounces_before_clamp: int = 3
var _flat_bounce_count: int = 0

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

@export var powerup_array: Array[BallPassive]

@export var ball_dmg_type: Array[GameManager.PhaseType]
var _type_scales: Dictionary[GameManager.PhaseType, float] = {}

@export var active_ball_powerup: BallActive

## Seconds per breath cycle of the armed tell; the tint fades in and out smoothly over the full period.
@export var active_pulse_period: float = 1.8
@export var meditation_breath_period: float = 2.4
@export var meditation_breath_scale: float = 0.12
var _active_cooldown_left: float = 0.0
var _active_pulse_time: float = 0.0
var _meditating: bool = false
var _meditation_time_left: float = 0.0
var _meditation_blink_seconds: float = 0.0
var _meditation_breath_time: float = 0.0
var _meditation_wake_cued: bool = false
var _pre_meditation_modulate: Color = Color.WHITE
var _pre_meditation_sprite_scale: Vector2 = Vector2.ONE
var _phasing: bool = false
var _phase_time_left: float = 0.0
var _phase_min_hits: int = 1
var _phase_max_hits: int = 3
var _phase_rehit_seconds: float = 0.06
var _phase_budgets: Dictionary[int, int] = {}
var _phase_next_hit: Dictionary[int, float] = {}
var _pre_phase_alpha: float = 1.0
var _speed_before_boost: float = 0.0
var _speed_boost_active: bool = false
var _soft_catch_pending: bool = false
var _soft_catch_tip_played: bool = false

var ball_in_magnet_range: bool = false
var paddle_can_attract: bool = true

var velocity: Vector2 = Vector2.ZERO
var on_paddle: bool = true
var _collision_set: Array[int] = []

var _sim_time: float = 0.0
var _push_block: Dictionary = {}

var move: Vector2 = Vector2.ZERO
var old_x: float = 0.0
var old_y: float = 0.0

@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var _light_texture_radius: float = maxf(point_light_2d.texture.get_width() * 0.5, 1.0)

@onready var paddle: Paddle = $"../Paddle"
@onready var paddle_collision: CollisionShape2D = $"../Paddle/PaddleCollisionShape"
@onready var ball_collision: CollisionShape2D = $bounce_collision_shape
@onready var sprite: Sprite2D = $Sprite2D
var _armed_material: ShaderMaterial
var is_tweening_to_david: bool = false
var tween_from_magnet: bool = false

@onready var ball_half_height: float = (ball_collision.shape as CircleShape2D).radius

func _ready() -> void:
	add_to_group(&"ball")
	_armed_material = ShaderMaterial.new()
	_armed_material.shader = ARMED_FLASH_SHADER
	_armed_material.set_shader_parameter("flash_amount", 0.0)
	_armed_material.set_shader_parameter("flash_color", Vector3(ARMED_FLASH_COLOR.r, ARMED_FLASH_COLOR.g, ARMED_FLASH_COLOR.b))
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
	Signalbus.ball_in_magnet_range.connect(set_ball_in_magnet_range)
	Signalbus.magnet_refresh_timeout.connect(set_paddle_can_attract)
	active_ball_powerup = PlayerData.inventory.get_ball_active()
	Signalbus.ball_active_assigned.connect(_assign_active_powerup)
	Signalbus.ball_swap_resolved.connect(_assign_active_powerup)

func _assign_active_powerup(item: BallActive) -> void:
	active_ball_powerup = item
	_active_cooldown_left = 0.0
	_active_pulse_time = 0.0

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
	_sim_time += delta
	_update_ball_light()
	_update_active_pulse(delta)
	flipped_x = false
	flipped_y = false
	_vertical_serve_checked = false
	if on_paddle:
		position_ball_on_paddle()
	elif _meditating:
		_update_meditation(delta)
	else:
		if _phasing:
			_update_blend_in(delta)
		move_ball(delta)
		_maybe_play_soft_catch_tip()

func _update_active_pulse(delta: float) -> void:
	if _active_cooldown_left > 0.0:
		_active_cooldown_left = maxf(_active_cooldown_left - delta, 0.0)
	if active_ball_powerup == null or _active_cooldown_left > 0.0 or active_pulse_period <= 0.0:
		_set_armed_flash(false)
		return
	_active_pulse_time += delta
	var breath: float = 0.5 - 0.5 * cos(TAU * _active_pulse_time / active_pulse_period)
	sprite.material = _armed_material
	_armed_material.set_shader_parameter("flash_amount", breath)

func _set_armed_flash(white: bool) -> void:
	sprite.material = _armed_material if white else null

func _update_ball_light() -> void:
	var dmg: float = maxf(ball_dmg, 1.0)
	var base_scale: float = ball_half_height * sqrt(dmg) / _light_texture_radius
	point_light_2d.texture_scale = maxf(base_scale, 0.01)
	point_light_2d.energy = LIGHT_BASE_ENERGY

func position_ball_on_paddle() -> void:
	_end_meditation()
	_end_blend_in()
	var offset: float = ball_half_height + get_paddle_half_height() + 1
	position = paddle.global_position + Vector2(0, -offset)
	on_paddle = true
	ball_collision.set_deferred("disabled", false)
	set_physics_process(true)
	is_tweening_to_david = false
	end_speed_boost()
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

func begin_meditation(freeze_seconds: float, blink_seconds: float) -> bool:
	if _meditating or on_paddle or is_tweening_to_david:
		return false
	_meditating = true
	_meditation_time_left = freeze_seconds + blink_seconds
	_meditation_blink_seconds = blink_seconds
	_meditation_breath_time = 0.0
	_meditation_wake_cued = false
	_pre_meditation_modulate = sprite.modulate
	_pre_meditation_sprite_scale = sprite.scale
	_set_armed_flash(false)
	ball_collision.set_deferred("disabled", true)
	SFX.play_sound("meditation_start")
	return true

func _update_meditation(delta: float) -> void:
	_meditation_time_left -= delta
	if _meditation_time_left <= 0.0:
		_end_meditation()
		return
	_meditation_breath_time += delta
	var breath: float = 1.0 + meditation_breath_scale * sin(TAU * _meditation_breath_time / meditation_breath_period)
	sprite.scale = _pre_meditation_sprite_scale * breath
	if not _meditation_wake_cued and _meditation_time_left <= _meditation_blink_seconds:
		_meditation_wake_cued = true
		SFX.play_sound("meditation_wake")
	var meditation_tint: Color = MEDITATION_GRAY
	if _meditation_time_left <= _meditation_blink_seconds and fposmod(_meditation_time_left, MEDITATION_BLINK_PERIOD) < MEDITATION_BLINK_PERIOD * 0.5:
		meditation_tint.a = MEDITATION_BLINK_ALPHA
	sprite.modulate = meditation_tint

func _end_meditation() -> void:
	if not _meditating:
		return
	_meditating = false
	sprite.scale = _pre_meditation_sprite_scale
	sprite.modulate = _pre_meditation_modulate
	ball_collision.set_deferred("disabled", false)
	if active_ball_powerup != null:
		_active_cooldown_left = active_ball_powerup.cool_down_seconds
		_active_pulse_time = 0.0

func begin_blend_in(duration_seconds: float, min_hits: int, max_hits: int, rehit_seconds: float) -> bool:
	if _phasing or on_paddle or is_tweening_to_david or _meditating:
		return false
	_phasing = true
	_phase_time_left = duration_seconds
	_phase_min_hits = min_hits
	_phase_max_hits = max_hits
	_phase_rehit_seconds = rehit_seconds
	_phase_budgets.clear()
	_phase_next_hit.clear()
	_pre_phase_alpha = sprite.modulate.a
	sprite.modulate.a = BLEND_IN_ALPHA
	_set_armed_flash(false)
	return true

func _update_blend_in(delta: float) -> void:
	_phase_time_left -= delta
	if _phase_time_left <= 0.0:
		_end_blend_in()

func _end_blend_in() -> void:
	if not _phasing:
		return
	_phasing = false
	sprite.modulate.a = _pre_phase_alpha
	_phase_budgets.clear()
	_phase_next_hit.clear()

func _phase_pierces(collider: Node2D) -> bool:
	return collider.is_in_group("bricks") or collider.is_in_group("barrier") or collider.is_in_group("bounce_enemy")

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
	collect_type_scales()
	update_base_dmg()

func collect_behaviors() -> void:
	behaviors.clear()
	for powerup_ref: BallPassive in powerup_array:
		for behavior: HitBehavior in powerup_ref.on_hit:
			behaviors.append(behavior)

func collect_type_scales() -> void:
	_type_scales.clear()
	var type_copies: Dictionary[GameManager.PhaseType, int] = {}
	for powerup_ref: BallPassive in powerup_array:
		var type_item: BallDamageType = powerup_ref as BallDamageType
		if type_item == null:
			continue
		var copies: int = 0
		if type_copies.has(type_item.phase_type):
			copies = type_copies[type_item.phase_type]
		if copies >= type_item.max_copies:
			continue
		type_copies[type_item.phase_type] = copies + 1
		var current_scale: float = 0.0
		if _type_scales.has(type_item.phase_type):
			current_scale = _type_scales[type_item.phase_type]
		_type_scales[type_item.phase_type] = current_scale + type_item.scale_per_copy

func update_base_dmg() -> void:
	ball_dmg = PlayerInventory.get_instance().get_ball_damage()

func get_paddle_half_height() -> float:
	var shape: RectangleShape2D = paddle_collision.shape as RectangleShape2D
	if absf(paddle_collision.rotation - PI / 2) < 0.1:
		return shape.size.x / 2.0
	return shape.size.y / 2.0

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_mouse") and on_paddle and GameManager.current_state == GameManager.GameState.BALL_ON_PADDLE:
		launch_ball()
		if PlayerInventory.instance.check_multiball_exist():
			PlayerInventory.instance.get_multiball_powerup().try_spawn_balls(get_owner(), paddle)
	if Input.is_action_just_pressed("ball_activate_powerup"):
		_try_activate_ball_powerup()

func _try_activate_ball_powerup() -> void:
	if active_ball_powerup == null or on_paddle or _active_cooldown_left > 0.0:
		return
	if GameManager.current_state != GameManager.GameState.PLAYING and GameManager.current_state != GameManager.GameState.CLICK_MODE:
		return
	if active_ball_powerup.activate(self):
		_active_cooldown_left = active_ball_powerup.cool_down_seconds
		_active_pulse_time = 0.0

func attract_to_paddle() -> void:
	if not on_paddle and ball_in_magnet_range and paddle_can_attract and GameManager.current_state == GameManager.GameState.PLAYING:
		tween_to_david(global_position)
		position_ball_on_paddle()
		tween_from_magnet = true
		paddle_can_attract = false
		Signalbus.reset_magnet_refresh.emit()
	elif on_paddle and GameManager.current_state == GameManager.GameState.BALL_ON_PADDLE:
		launch_ball()

func set_ball_in_magnet_range(ball_in_range: bool) -> void:
	if ball_in_range:
		ball_in_magnet_range = true
	else:
		ball_in_magnet_range = false

func set_paddle_can_attract() -> void:
	paddle_can_attract = true

func speed_cap() -> float:
	return max_speed * SettingsManager.difficulty_mult()

func launch_ball() -> void:
	on_paddle = false
	_reset_vertical_serve()
	var launch_speed: float = initial_speed * SettingsManager.difficulty_mult()
	current_speed = launch_speed
	GameManager.change_state(GameManager.GameState.PLAYING)
	set_process(true)
	velocity = Vector2(float(paddle.current_speed), -launch_speed)
	velocity = velocity.normalized() * launch_speed
	_play_launch_tutorial_tips()

func _play_launch_tutorial_tips() -> void:
	if paddle.active_paddle_powerup != null:
		await DialogDirector.play_and_wait(&"tutorial_paddle_active", paddle)
		if not is_inside_tree():
			return
	if active_ball_powerup != null:
		DialogDirector.play(&"tutorial_ball_active", self)

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
		_flat_bounce_count = 0
		return
	_flat_bounce_count += 1
	if _flat_bounce_count < flat_bounces_before_clamp:
		return
	_flat_bounce_count = 0
	var vy_sign: float = 1.0 if velocity.y == 0.0 else signf(velocity.y)
	var vx_sign: float = 1.0 if velocity.x == 0.0 else signf(velocity.x)
	var new_vy: float = min_vy * vy_sign
	var new_vx: float = sqrt(maxf(speed * speed - new_vy * new_vy, 0.0)) * vx_sign
	velocity = Vector2(new_vx, new_vy)

func reset_flat_bounce_count() -> void:
	_flat_bounce_count = 0

func _push_blocked(collider: Node2D) -> bool:
	var id: int = collider.get_instance_id()
	if not _push_block.has(id):
		return false
	if _sim_time - float(_push_block[id]) >= ENEMY_PUSH_COOLDOWN:
		_push_block.erase(id)
		return false
	return true

func _mark_pushed(collider: Node2D) -> void:
	if _push_block.size() > 16:
		for id: int in _push_block.keys():
			if _sim_time - float(_push_block[id]) >= ENEMY_PUSH_COOLDOWN:
				_push_block.erase(id)
	_push_block[collider.get_instance_id()] = _sim_time

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
	if _phasing and not _phase_budgets.is_empty():
		_clean_phase_tracking()
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
		if _phasing and _phase_pierces(collider):
			continue
		var half: Vector2 = get_collider_half_size(collider)
		var diff: Vector2 = global_position - collider.global_position
		var pen_x: float = half.x + ball_half_height - absf(diff.x)
		var pen_y: float = half.y + ball_half_height - absf(diff.y)
		if pen_x <= 0.0 or pen_y <= 0.0:
			continue
		end_speed_boost()
		var is_enemy: bool = collider.is_in_group("bounce_enemy")
		if is_enemy and _push_blocked(collider):
			continue
		if is_enemy:
			apply_collider_effects(collider)
			_mark_pushed(collider)
		var dir_x: float = 1.0 if diff.x == 0.0 else signf(diff.x)
		var dir_y: float = 1.0 if diff.y == 0.0 else signf(diff.y)
		if pen_x < pen_y:
			position.x = collider.global_position.x + (half.x + ball_half_height + 0.5) * dir_x
			velocity.x = absf(velocity.x) * dir_x
		else:
			position.y = collider.global_position.y + (half.y + ball_half_height + 0.5) * dir_y
			velocity.y = absf(velocity.y) * dir_y
		if is_enemy:
			spawn_collision_feedback(collider)

func move_ball_step(delta: float) -> void:
	velocity = velocity.normalized() * current_speed
	move = velocity * delta
	_soft_catch_pending = false
	var hit_this_step: Array[int] = []
	var effects_this_step: Array[int] = []

	old_x = position.x
	position.x += move.x
	var x_collisions: Array[Node2D] = query_collisions()
	for collider: Node2D in x_collisions:
		if collider.get_instance_id() in hit_this_step:
			continue
		if collider.is_in_group("bounce_enemy") and not _phasing:
			if _push_blocked(collider):
				continue
			_mark_pushed(collider)
		hit_this_step.append(collider.get_instance_id())
		if collider.get_instance_id() not in effects_this_step:
			effects_this_step.append(collider.get_instance_id())
			var landed: bool = apply_collider_effects(collider)
			if on_paddle:
				return
			if landed:
				spawn_collision_feedback(collider)
				end_speed_boost()
		if collider.is_in_group("paddle"):
			if !flipped_x:
				_apply_soft_catch()
				bounce_effect.handle_paddle_collision(self, collider as Paddle)
				_check_vertical_serve()
				flipped_x = true
		elif collider.is_in_group("bricks") or collider.is_in_group("walls") or collider.is_in_group("bounce_enemy") or collider.is_in_group("barrier"):
			if _phasing and _phase_pierces(collider):
				continue
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
		if collider.is_in_group("bounce_enemy") and not _phasing:
			if _push_blocked(collider):
				continue
			_mark_pushed(collider)
		hit_this_step.append(collider.get_instance_id())
		if collider.get_instance_id() not in effects_this_step:
			effects_this_step.append(collider.get_instance_id())
			var landed: bool = apply_collider_effects(collider)
			if on_paddle:
				return
			if landed:
				spawn_collision_feedback(collider)
				end_speed_boost()
		if collider.is_in_group("paddle"):
			if !flipped_y:
				_apply_soft_catch()
				bounce_effect.handle_paddle_collision(self, collider as Paddle)
				_check_vertical_serve()
				flipped_y = true
		elif collider.is_in_group("bricks") or collider.is_in_group("walls") or collider.is_in_group("bounce_enemy") or collider.is_in_group("barrier"):
			if _phasing and _phase_pierces(collider):
				continue
			if not _bounce_axis_is_y(collider):
				if !flipped_x:
					bounce_effect.handle_x_collision(self, collider)
					flipped_x = true
			elif !flipped_y:
				bounce_effect.handle_y_collision(self, collider)
				flipped_y = true

func _maybe_play_soft_catch_tip() -> void:
	if _soft_catch_tip_played or is_queued_for_deletion():
		return
	var launch_speed: float = initial_speed * SettingsManager.difficulty_mult()
	if current_speed < (launch_speed + speed_cap()) * 0.5:
		return
	_soft_catch_tip_played = true
	DialogDirector.play(&"tutorial_soft_catch", paddle)

func _apply_soft_catch() -> void:
	if not _soft_catch_pending:
		return
	_soft_catch_pending = false
	var launch_speed: float = initial_speed * SettingsManager.difficulty_mult()
	current_speed = maxf(current_speed * soft_catch_factor, launch_speed)

func spawn_collision_feedback(collider: Node2D) -> void:
	var fx: Node2D = null
	if collider.is_in_group("bricks"):
		fx = brick_bounce_particles.instantiate()
		SFX.play_sound("hit-brick")
		PlayerData.update_player_score(brick_hit_score_value)
		if collider.has_method("hit_knockback"):
			collider.call("hit_knockback", velocity.normalized())
		_add_hit_trauma(seal_hit_trauma)
	if collider.is_in_group("walls"):
		fx = wall_bounce_particles.instantiate()
		SFX.play_sound("bounce_1")
		PlayerData.update_player_score(wall_hit_score_value)
		Signalbus.wall_hit.emit(self, collider, ball_dmg, ball_dmg_type)
		TileShake.shake(collider, 0.0, TileShake.DIRECT_HIT_SCALE)
	if collider.is_in_group("barrier"):
		fx = barrier_bounce_particles.instantiate()
		SFX.play_sound("bounce_barrier")
		_add_hit_trauma(barrier_hit_trauma)
	if collider.is_in_group("bounce_enemy") and enemy_bounce_particles != null:
		fx = enemy_bounce_particles.instantiate()
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

func _add_hit_trauma(amount: float) -> void:
	if amount <= 0.0:
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null or not camera.has_method(&"add_trauma"):
		return
	@warning_ignore("unsafe_method_access")
	camera.add_trauma(amount)

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
	var half: Vector2 = (shape.size * col_shape.scale * collider.global_scale).abs() / 2.0
	var rot: float = collider.global_rotation + col_shape.rotation
	if absf(sin(rot)) > absf(cos(rot)):
		half = Vector2(half.y, half.x)
	return half

# --- Collision tracking ---

func handle_pierce(collider: Node2D) -> void:
	_collision_set.append(collider.get_instance_id())

func clean_collision_set() -> void:
	var current_ids: Array[int] = []
	for c: Node2D in query_collisions():
		current_ids.append(c.get_instance_id())
	_collision_set = _collision_set.filter(func(id: int) -> bool: return id in current_ids)

func apply_collider_effects(collider: Node2D) -> bool:
	if _phasing and _phase_pierces(collider):
		return _apply_phase_hit(collider)
	if collider.get_instance_id() in _collision_set:
		return false
	var ctx: HitContext = _make_hit_context()
	for behavior: HitBehavior in behaviors:
		behavior.apply(ctx, collider)
	if collider.is_in_group("bounce_enemy"):
		_collision_set.append(collider.get_instance_id())
	return true

func _apply_phase_hit(collider: Node2D) -> bool:
	var id: int = collider.get_instance_id()
	if not _phase_budgets.has(id):
		_phase_budgets[id] = randi_range(_phase_min_hits, _phase_max_hits)
		_phase_next_hit[id] = _sim_time
	if _phase_budgets[id] <= 0 or _sim_time < _phase_next_hit[id]:
		return false
	_phase_budgets[id] -= 1
	_phase_next_hit[id] = _sim_time + _phase_rehit_seconds
	var ctx: HitContext = _make_hit_context()
	for behavior: HitBehavior in behaviors:
		behavior.apply(ctx, collider)
	return true

func _clean_phase_tracking() -> void:
	var current_ids: Array[int] = []
	for c: Node2D in query_collisions():
		current_ids.append(c.get_instance_id())
	for id: int in _phase_budgets.keys():
		if id not in current_ids:
			_phase_budgets.erase(id)
			_phase_next_hit.erase(id)

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
		if target is BaseSeal:
			for phase: GameManager.PhaseType in _type_scales:
				target.call("accept_damage", amount * _type_scales[phase], [phase])
	elif target.is_in_group("DeathWalls"):
		if is_tweening_to_david:
			return
		await tween_to_david(global_position)
		var surrender: Node = get_tree().get_first_node_in_group(GameManager.SURRENDER)
		if surrender != null:
			tween_from_magnet = false
			@warning_ignore("unsafe_method_access")
			surrender.receive_ball()
			position_ball_on_paddle()
			return
		if not tween_from_magnet:
			PlayerData.accept_reflect_damage(amount)
		else:
			tween_from_magnet = false
		if PlayerData.player_current_health > 0:
			position_ball_on_paddle()
