class_name RageKing
extends FallingEnemy

const RAGE_BLOB: PackedScene = preload("uid://b1mku5iyrtraa")
const DAMAGE_NUMBER: PackedScene = preload("uid://bedvoohhfbi03")

enum VolleyPattern { SWEEP = 0, PINGPONG = 1 }

@export var max_health: float = 35.0 ## Real HP pool: HEALTH-type damage subtracts its actual amount; at 0 the king dies and emits Signalbus.boss_defeated.
@export var start_scale: float = 0.5 ## Uniform scale stamped at spawn, before the intro grow.
@export var full_scale: float = 8.0 ## Uniform scale the intro grows to; the king keeps this size for the whole fight.
@export var grow_time: float = 2.5 ## Seconds of the intro grow from start_scale to full_scale; the king is invulnerable and motionless until it finishes.
@export var patrol_min_x: float = 544.0 ## Left bound (world) for the king's center; keeps the sprite's opaque edge clear of the left wall at full scale.
@export var patrol_max_x: float = 1648.0 ## Right bound (world) for the king's center; keeps the sprite's opaque edge clear of the right wall at full scale.
@export var patrol_min_y: float = 304.0 ## Top bound (world) for the king's center; keeps the head's opaque edge clear of the top wall at full scale.
@export var patrol_max_y: float = 368.0 ## Bottom bound (world) for the king's center; keeps the whole opaque sprite above the side exits' bottom edge (world y 576) at full scale.
@export var sweep_period: float = 9.0 ## Seconds for one full left-right-left patrol sweep at normal speed.
@export var sweep_jitter_min: float = 1.5 ## Shortest seconds between sweep re-rolls (speed change or direction flip).
@export var sweep_jitter_max: float = 4.0 ## Longest seconds between sweep re-rolls.
@export var sweep_flip_chance: float = 0.3 ## Chance per re-roll that the horizontal drift eases into reverse instead of just changing speed.
@export var bob_period_min: float = 2.0 ## Shortest seconds for one vertical bob swing (mid to extreme and back to mid); re-rolled each swing.
@export var bob_period_max: float = 4.5 ## Longest seconds for one vertical bob swing; re-rolled each swing.
@export var bob_amp_min_frac: float = 0.35 ## Smallest bob amplitude as a fraction of the half vertical band; re-rolled each swing. 1.0 = always full-band bobs.
@export var spit_delay_min: float = 4.0 ## Shortest seconds between normal-blob spit attempts while not enraged.
@export var spit_delay_max: float = 8.0 ## Longest seconds between spit attempts.
@export var max_spit_blobs: int = 2 ## Spit attempts are skipped (and re-rolled) while this many spat blobs are still alive.
@export var enrage_hit_interval: int = 3 ## Every Nth ball hit traps the ball and triggers the pulse-volley-careen enrage sequence.
@export var pulse_time: float = 2.5 ## Seconds of sprite-pulse telegraph before the volley fires.
@export var pulse_amount: float = 1.15 ## Sprite scale multiplier at the peak of each telegraph pulse.
@export var volley_count: int = 10 ## Shots fired per enrage volley.
@export var volley_interval: float = 0.35 ## Seconds between shots in a sweep volley.
@export var pingpong_interval: float = 0.6 ## Seconds between shots in a back-and-forth volley; slower than the sweep so the paddle can cross between sides.
@export var volley_spread_degrees: float = 100.0 ## Full fan angle of the volley, centered straight down from the mouth. Sweep volleys walk it left to right; back-and-forth volleys alternate its edges, converging toward the middle.
@export var shot_scene: PackedScene ## The RageShot projectile fired by volleys.
@export var enrage_move_time: float = 3.0 ## Seconds the king careens in a random direction after the volley.
@export var enrage_move_speed: float = 480.0 ## Careen speed in pixels per second; bounces off the patrol bounds.
@export var recover_time: float = 0.6 ## Seconds to glide from the careen end point back onto the patrol wave.
@export var stuck_radius: float = 130.0 ## World pixels from the king's center where the trapped ball seats, along the bearing it hit from; keep below the sprite's opaque half-extents (~200 at full scale) so the ball reads as sunk into the body.
@export var release_offset_y: float = 220.0 ## World pixels below the king's center where the ball pops back out.
@export var destroy_fx: PackedScene ## Particle burst instanced at the king's position on death. Empty = no burst.
@export var destroy_fx_scale: float = 8.0 ## Multiplier on the destroy_fx root scale so the burst matches the king's size.

const SWEEP_RATE_EASE: float = 5.0
const SWEEP_RATE_MIN: float = 0.7
const SWEEP_RATE_MAX: float = 1.25

var health: float
var dying: bool = false
var _grown: bool = false
var _enraged: bool = false
var _hit_count: int = 0
var _sweep_phase: float = 0.0
var _sweep_rate: float = 1.0
var _sweep_rate_target: float = 1.0
var _sweep_timer: float = 0.0
var _bob_phase: float = 0.0
var _bob_period: float = 0.0
var _bob_amp: float = 0.0
var _stuck_ball: Ball
var _stuck_offset: Vector2 = Vector2.ZERO
var _careen_dir: Vector2 = Vector2.ZERO
var _volley_index: int = 0
var _spit_timer: Timer
var _spit_blobs: Array[Node] = []

func _ready() -> void:
	health = max_health
	scale = Vector2.ONE * start_scale
	var hitbox: CollisionShape2D = $CollisionShape2D
	hitbox.disabled = true
	_bob_period = randf_range(bob_period_min, bob_period_max)
	_bob_amp = _roll_bob_amp()
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * full_scale, grow_time)
	tween.tween_callback(_finish_intro)
	_set_player_frozen.call_deferred(true)

func _finish_intro() -> void:
	_grown = true
	Signalbus.encounter_progress.emit(1, 1, health, max_health)
	$CollisionShape2D.set_deferred("disabled", false)
	_set_player_frozen(false)
	_setup_spit_timer()

func _setup_spit_timer() -> void:
	_spit_timer = Timer.new()
	_spit_timer.one_shot = true
	_spit_timer.timeout.connect(_on_spit_timer_timeout)
	add_child(_spit_timer)
	_restart_spit_timer()

func _restart_spit_timer() -> void:
	_spit_timer.start(randf_range(spit_delay_min, spit_delay_max))

func _on_spit_timer_timeout() -> void:
	if dying:
		return
	_prune_spit_blobs()
	if not _enraged and _spit_blobs.size() < max_spit_blobs \
			and GameManager.current_state != GameManager.GameState.LEVEL_CLEARED:
		_spit_blob()
	_restart_spit_timer()

func _prune_spit_blobs() -> void:
	for i: int in range(_spit_blobs.size() - 1, -1, -1):
		if not is_instance_valid(_spit_blobs[i]):
			_spit_blobs.remove_at(i)

func _spit_blob() -> void:
	var blob: RageBlob = RAGE_BLOB.instantiate()
	blob.add_collision_exception_with(self)
	var mouth: Node2D = $Mouth
	blob.position = mouth.global_position
	get_parent().add_child(blob)
	_spit_blobs.append(blob)

func _set_player_frozen(frozen: bool) -> void:
	var paddle: Node = get_tree().get_first_node_in_group(GameManager.PADDLE)
	if paddle != null:
		paddle.set_process_input(not frozen)
		paddle.set_process(not frozen)
		paddle.set_physics_process(not frozen)
	var ball: Node = get_tree().get_first_node_in_group(&"ball")
	if ball != null:
		ball.set_process_input(not frozen)

func tick_movement(delta: float) -> void:
	if _grown and not dying and not _enraged:
		_advance_phases(delta)
		global_position = _patrol_point()
	_track_stuck_ball()

func _advance_phases(delta: float) -> void:
	_sweep_timer -= delta
	if _sweep_timer <= 0.0:
		_reroll_sweep()
	_sweep_rate = move_toward(_sweep_rate, _sweep_rate_target, delta * SWEEP_RATE_EASE)
	_sweep_phase = wrapf(_sweep_phase + delta * TAU / sweep_period * _sweep_rate, 0.0, TAU)
	var prev_bob_phase: float = _bob_phase
	_bob_phase += delta * PI / _bob_period
	if prev_bob_phase < PI and _bob_phase >= PI:
		_reroll_bob()
	elif _bob_phase >= TAU:
		_bob_phase -= TAU
		_reroll_bob()

func _patrol_point() -> Vector2:
	var mid_x: float = (patrol_min_x + patrol_max_x) * 0.5
	var half_x: float = (patrol_max_x - patrol_min_x) * 0.5
	var mid_y: float = (patrol_min_y + patrol_max_y) * 0.5
	return Vector2(mid_x + half_x * sin(_sweep_phase), mid_y + _bob_amp * sin(_bob_phase))

func _reroll_sweep() -> void:
	_sweep_timer = randf_range(sweep_jitter_min, sweep_jitter_max)
	var dir_sign: float = signf(_sweep_rate_target) if _sweep_rate_target != 0.0 else 1.0
	if randf() < sweep_flip_chance:
		dir_sign = -dir_sign
	_sweep_rate_target = dir_sign * randf_range(SWEEP_RATE_MIN, SWEEP_RATE_MAX)

func _reroll_bob() -> void:
	_bob_period = randf_range(bob_period_min, bob_period_max)
	_bob_amp = _roll_bob_amp()

func _roll_bob_amp() -> float:
	return randf_range(bob_amp_min_frac, 1.0) * (patrol_max_y - patrol_min_y) * 0.5

func accept_damage(damage: float, dmg_type: Array[GameManager.PhaseType], score_mult: float = 1.0) -> void:
	if dying or not _grown:
		return
	if not dmg_type.has(GameManager.PhaseType.HEALTH):
		return
	SFX.play_sound("enemy_hurt")
	_show_damage_number(damage)
	_flash_hit()
	PlayerData.update_player_score(minf(damage, maxf(health, 0.0)), score_mult)
	health -= damage
	Signalbus.encounter_progress.emit(1, 1, maxf(health, 0.0), max_health)
	if health <= 0.0:
		_die()
		return
	_hit_count += 1
	if not _enraged and enrage_hit_interval > 0 and _hit_count % enrage_hit_interval == 0:
		_start_enrage()

func _start_enrage() -> void:
	_enraged = true
	_capture_ball()
	_run_enrage_sequence()

func _run_enrage_sequence() -> void:
	await _pulse()
	if dying:
		return
	await _fire_volley()
	if dying:
		return
	await _careen()
	if dying:
		return
	await _recover()
	_release_ball()
	_enraged = false

func _pulse() -> void:
	var sprite: Sprite2D = $Sprite2D
	var cycles: int = 3
	var half_cycle: float = pulse_time / (float(cycles) * 2.0)
	var tween: Tween = create_tween()
	for i: int in cycles:
		tween.tween_property(sprite, "scale", Vector2.ONE * pulse_amount, half_cycle)
		tween.tween_property(sprite, "scale", Vector2.ONE, half_cycle)
	await tween.finished

func _fire_volley() -> void:
	var pattern: VolleyPattern = VolleyPattern.SWEEP if _volley_index % 2 == 0 else VolleyPattern.PINGPONG
	_volley_index += 1
	var interval: float = volley_interval if pattern == VolleyPattern.SWEEP else pingpong_interval
	for i: int in volley_count:
		if dying:
			return
		_fire_shot(i, pattern)
		await get_tree().create_timer(interval, false).timeout

func _fire_shot(index: int, pattern: VolleyPattern) -> void:
	if shot_scene == null:
		return
	var shot: RageShot = shot_scene.instantiate()
	shot.add_collision_exception_with(self)
	var half_spread: float = deg_to_rad(volley_spread_degrees) * 0.5
	var t: float = _shot_fan_position(index, pattern)
	shot.direction = Vector2.DOWN.rotated(lerpf(-half_spread, half_spread, t))
	var mouth: Node2D = $Mouth
	shot.position = mouth.global_position
	get_parent().add_child(shot)

func _shot_fan_position(index: int, pattern: VolleyPattern) -> float:
	if volley_count <= 1:
		return 0.5
	if pattern == VolleyPattern.SWEEP:
		return float(index) / float(volley_count - 1)
	@warning_ignore("integer_division")
	var pairs: int = maxi(1, (volley_count + 1) / 2 - 1)
	@warning_ignore("integer_division")
	var inward: float = float(index / 2) / float(pairs) * 0.45
	return inward if index % 2 == 0 else 1.0 - inward

func _careen() -> void:
	_careen_dir = Vector2.from_angle(randf_range(0.0, TAU))
	var elapsed: float = 0.0
	while elapsed < enrage_move_time:
		await get_tree().physics_frame
		if dying:
			return
		var delta: float = get_physics_process_delta_time()
		elapsed += delta
		var next: Vector2 = global_position + _careen_dir * enrage_move_speed * delta
		if next.x < patrol_min_x or next.x > patrol_max_x:
			_careen_dir.x = -_careen_dir.x
		if next.y < patrol_min_y or next.y > patrol_max_y:
			_careen_dir.y = -_careen_dir.y
		global_position += _careen_dir * enrage_move_speed * delta

func _recover() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", _patrol_point(), recover_time)
	await tween.finished

func _capture_ball() -> void:
	var ball: Ball = get_tree().get_first_node_in_group("ball") as Ball
	if ball == null or ball.on_paddle:
		return
	_stuck_ball = ball
	ball.set_physics_process(false)
	ball.set_process(false)
	ball.set_deferred("monitorable", false)
	var bearing: Vector2 = (ball.global_position - global_position).normalized()
	if bearing == Vector2.ZERO:
		bearing = Vector2.DOWN
	ball.global_position = global_position + bearing * stuck_radius
	_stuck_offset = ball.global_position - global_position

func _track_stuck_ball() -> void:
	if _stuck_ball == null:
		return
	if not is_instance_valid(_stuck_ball):
		_stuck_ball = null
		return
	var sprite: Sprite2D = $Sprite2D
	_stuck_ball.global_position = global_position + _stuck_offset * sprite.scale.x

func _release_ball() -> void:
	if _stuck_ball == null or not is_instance_valid(_stuck_ball):
		_stuck_ball = null
		return
	_stuck_ball.global_position = global_position + Vector2(0.0, release_offset_y)
	_stuck_ball.update_velocity(Vector2.DOWN * _stuck_ball.current_speed)
	_stuck_ball.set_deferred("monitorable", true)
	_stuck_ball.set_process(true)
	_stuck_ball.set_physics_process(true)
	_stuck_ball = null

func responding_gestures() -> Array[GameManager.PhaseType]:
	return []

func _show_damage_number(amount: float) -> void:
	var dn: DamageNumber = DAMAGE_NUMBER.instantiate()
	dn.position = global_position
	dn.z_index = 2000
	get_tree().current_scene.add_child(dn)
	dn.show_damage("-" + DamageNumber.format_amount(amount), DamageNumber.COLOR_DEALT)

func _flash_hit() -> void:
	var sprite: Sprite2D = $Sprite2D
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_amount", 1.0)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("flash_amount", v),
		1.0, 0.0, 0.05
	)

func _die() -> void:
	dying = true
	_release_ball()
	SFX.play_sound("deon_die")
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		@warning_ignore("unsafe_method_access")
		camera.add_trauma(2.0)
	_spawn_destroy_fx()
	queue_free()
	Signalbus.boss_defeated.emit()

func _spawn_destroy_fx() -> void:
	if destroy_fx == null:
		return
	var fx: Node2D = destroy_fx.instantiate()
	fx.position = global_position
	fx.scale *= destroy_fx_scale
	get_tree().current_scene.add_child(fx)
