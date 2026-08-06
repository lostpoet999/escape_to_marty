class_name Collector
extends FallingEnemy

const DAMAGE_NUMBER: PackedScene = preload("uid://bedvoohhfbi03")

const SWEEP_RATE_EASE: float = 5.0
const SWEEP_RATE_MIN: float = 0.7
const SWEEP_RATE_MAX: float = 1.25

@export var max_health: float = 150.0
@export var start_scale: float = 0.5
@export var full_scale: float = 2.5
@export var grow_time: float = 2.5
@export var idle_fps: float = 6.0
@export var patrol_min_x: float = 544.0
@export var patrol_max_x: float = 1648.0
@export var patrol_min_y: float = 304.0
@export var patrol_max_y: float = 368.0
@export var sweep_period: float = 9.0
@export var sweep_jitter_min: float = 1.5
@export var sweep_jitter_max: float = 4.0
@export var sweep_flip_chance: float = 0.3
@export var bob_period_min: float = 2.0
@export var bob_period_max: float = 4.5
@export var bob_amp_min_frac: float = 0.35
@export var destroy_fx: PackedScene
@export var destroy_fx_scale: float = 2.5

var health: float
var dying: bool = false
var _grown: bool = false
var _sweep_phase: float = 0.0
var _sweep_rate: float = 1.0
var _sweep_rate_target: float = 1.0
var _sweep_timer: float = 0.0
var _bob_phase: float = 0.0
var _bob_period: float = 0.0
var _bob_amp: float = 0.0
var _idle_time: float = 0.0

func _ready() -> void:
	health = max_health
	scale = Vector2.ONE * start_scale
	$CollisionShape2D.disabled = true
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

func _set_player_frozen(frozen: bool) -> void:
	var paddle: Node = get_tree().get_first_node_in_group(GameManager.PADDLE)
	if paddle != null:
		paddle.set_process_input(not frozen)
		paddle.set_process(not frozen)
		paddle.set_physics_process(not frozen)
	var ball: Node = get_tree().get_first_node_in_group(&"ball")
	if ball != null:
		ball.set_process_input(not frozen)

func _process(delta: float) -> void:
	var sprite: Sprite2D = $Sprite2D
	_idle_time += delta * idle_fps
	sprite.frame = int(_idle_time) % sprite.hframes

func tick_movement(delta: float) -> void:
	if _grown and not dying:
		_advance_phases(delta)
		global_position = _patrol_point()

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

func accept_damage(damage: float, dmg_type: Array[GameManager.PhaseType]) -> void:
	if dying or not _grown:
		return
	if not dmg_type.has(GameManager.PhaseType.HEALTH):
		return
	SFX.play_sound("enemy_hurt")
	_show_damage_number(damage)
	_flash_hit()
	health -= damage
	Signalbus.encounter_progress.emit(1, 1, maxf(health, 0.0), max_health)
	if health <= 0.0:
		_die()

func responding_gestures() -> Array[GameManager.PhaseType]:
	return []

func _show_damage_number(amount: float) -> void:
	var dn: DamageNumber = DAMAGE_NUMBER.instantiate()
	dn.position = global_position
	dn.z_index = 2000
	get_tree().current_scene.add_child(dn)
	dn.show_damage("-" + DamageNumber.format_amount(amount), DamageNumber.COLOR_DEALT)

func _flash_hit() -> void:
	var mat: ShaderMaterial = $Sprite2D.material as ShaderMaterial
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
