class_name Collector
extends FallingEnemy

const DAMAGE_NUMBER: PackedScene = preload("uid://bedvoohhfbi03")

const STAGE_COUNT: int = 2
const COFFIN_STAGE: int = 1
const HEALTH_STAGE: int = 2
const MIN_GLIDE_TIME: float = 0.35
const FACE_DEADZONE: float = 1.0

@export var max_health: float = 150.0
@export var start_scale: float = 0.2
@export var grow_time: float = 2.5
@export var idle_fps: float = 6.0
@export var procession_points: Array[Vector2] = [Vector2(720, 336), Vector2(1096, 320), Vector2(1480, 336)]
@export var glide_speed: float = 90.0
@export var station_pause: float = 2.5
@export var orbit_period: float = 7.0
@export var corner_points: Array[Vector2] = [Vector2(600, 330), Vector2(1590, 330), Vector2(600, 660), Vector2(1590, 660)]
@export var flee_speed: float = 280.0
@export var corner_dwell: float = 1.6
@export var retreat_trigger_distance: float = 340.0
@export var shield_color: Color = Color(0.55, 0.7, 1.0)
@export var shield_pulse_period: float = 1.6
@export var destroy_fx: PackedScene
@export var destroy_fx_scale: float = 2.5

var health: float
var dying: bool = false
var _grown: bool = false
var _player_frozen: bool = false
var _retreating: bool = false
var _gliding: bool = false
var _glide_start: Vector2 = Vector2.ZERO
var _glide_target: Vector2 = Vector2.ZERO
var _glide_elapsed: float = 0.0
var _glide_duration: float = 0.0
var _pause_timer: float = 0.0
var _dwell_timer: float = 0.0
var _station_index: int = 0
var _orbit_angle: float = 0.0
var _orbit_rate: float = 0.0
var _idle_time: float = 0.0
var _coffins: Array[CollectorCoffin] = []
var _coffin_offsets: Dictionary[CollectorCoffin, Vector2] = {}
var _coffin_total: int = 0
var _shield_tween: Tween

func _ready() -> void:
	health = max_health
	var target_scale: Vector2 = scale
	scale = target_scale * start_scale
	var col: CollisionShape2D = $CollisionShape2D
	col.disabled = true
	for child: Node in get_children():
		var coffin: CollectorCoffin = child as CollectorCoffin
		if coffin != null:
			_coffins.append(coffin)
			_coffin_offsets[coffin] = coffin.position
			coffin.cleared.connect(_on_coffin_cleared)
			coffin.set_interactive(false)
	_coffin_total = _coffins.size()
	_place_coffins()
	_start_shield_pulse()
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", target_scale, grow_time)
	tween.tween_callback(_finish_intro)
	_set_player_frozen.call_deferred(true)

func _exit_tree() -> void:
	if _player_frozen:
		_set_player_frozen(false)

func _finish_intro() -> void:
	_grown = true
	Signalbus.encounter_progress.emit(COFFIN_STAGE, STAGE_COUNT, float(_coffins.size()), float(_coffin_total))
	$CollisionShape2D.set_deferred("disabled", false)
	for coffin: CollectorCoffin in _coffins:
		coffin.set_interactive(true)
	_set_player_frozen(false)
	_station_index = _nearest_station_index()
	_begin_next_glide()

func _set_player_frozen(frozen: bool) -> void:
	_player_frozen = frozen
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

func is_moving() -> bool:
	return _gliding

func tick_movement(delta: float) -> void:
	if dying or not _grown:
		return
	if _gliding:
		_advance_glide(delta)
	elif _retreating:
		_tick_dwell(delta)
	else:
		_tick_station_pause(delta)
	if not _retreating:
		_tick_orbit(delta)

func _advance_glide(delta: float) -> void:
	_glide_elapsed += delta
	var weight: float = clampf(_glide_elapsed / _glide_duration, 0.0, 1.0)
	var eased: float = weight * weight * (3.0 - 2.0 * weight)
	global_position = _glide_start.lerp(_glide_target, eased)
	if weight >= 1.0:
		_gliding = false
		_pause_timer = station_pause
		_dwell_timer = 0.0

func _tick_station_pause(delta: float) -> void:
	_pause_timer -= delta
	if _pause_timer <= 0.0:
		_begin_next_glide()

func _tick_dwell(delta: float) -> void:
	_dwell_timer += delta
	if _dwell_timer >= corner_dwell and _ball_distance() < retreat_trigger_distance:
		_flee()

func _tick_orbit(delta: float) -> void:
	if orbit_period <= 0.0:
		return
	var target_rate: float = TAU / orbit_period if _gliding else 0.0
	_orbit_rate = move_toward(_orbit_rate, target_rate, delta * TAU / orbit_period)
	if _orbit_rate == 0.0 and target_rate == 0.0:
		return
	_orbit_angle = wrapf(_orbit_angle + _orbit_rate * delta, 0.0, TAU)
	_place_coffins()

func _place_coffins() -> void:
	for coffin: CollectorCoffin in _coffins:
		coffin.position = _coffin_offsets[coffin].rotated(_orbit_angle)

func _begin_next_glide() -> void:
	if procession_points.is_empty():
		return
	_station_index = (_station_index + 1) % procession_points.size()
	_start_glide(procession_points[_station_index], glide_speed)

func _nearest_station_index() -> int:
	var best: int = 0
	var best_dist: float = INF
	for i: int in procession_points.size():
		var dist: float = global_position.distance_to(procession_points[i])
		if dist < best_dist:
			best_dist = dist
			best = i
	return best

func _start_glide(target: Vector2, speed: float) -> void:
	_glide_start = global_position
	_glide_target = target
	_glide_duration = maxf(_glide_start.distance_to(target) / speed, MIN_GLIDE_TIME)
	_glide_elapsed = 0.0
	_gliding = true
	_face_toward(target.x - _glide_start.x)

func _flee() -> void:
	if corner_points.is_empty():
		return
	var ball: Node2D = get_tree().get_first_node_in_group(&"ball") as Node2D
	var flee_from: Vector2 = ball.global_position if ball != null else global_position
	var best: Vector2 = corner_points[0]
	var best_dist: float = -1.0
	for point: Vector2 in corner_points:
		var dist: float = point.distance_to(flee_from)
		if dist > best_dist:
			best_dist = dist
			best = point
	_start_glide(best, flee_speed)

func _ball_distance() -> float:
	var ball: Node2D = get_tree().get_first_node_in_group(&"ball") as Node2D
	if ball == null:
		return INF
	return global_position.distance_to(ball.global_position)

func _face_toward(dx: float) -> void:
	if absf(dx) < FACE_DEADZONE:
		return
	var sprite: Sprite2D = $Sprite2D
	sprite.flip_h = dx < 0.0

func _on_coffin_cleared(coffin: CollectorCoffin) -> void:
	_coffins.erase(coffin)
	_coffin_offsets.erase(coffin)
	Signalbus.encounter_progress.emit(COFFIN_STAGE, STAGE_COUNT, float(_coffins.size()), float(_coffin_total))
	if _coffins.is_empty():
		_drop_bubble()

func _start_shield_pulse() -> void:
	var sprite: Sprite2D = $Sprite2D
	_shield_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shield_tween.tween_property(sprite, "modulate", shield_color, shield_pulse_period * 0.5)
	_shield_tween.tween_property(sprite, "modulate", Color.WHITE, shield_pulse_period * 0.5)

func _drop_bubble() -> void:
	_retreating = true
	if _shield_tween != null:
		_shield_tween.kill()
		_shield_tween = null
	var sprite: Sprite2D = $Sprite2D
	sprite.modulate = Color.WHITE
	Signalbus.encounter_progress.emit(HEALTH_STAGE, STAGE_COUNT, health, max_health)
	_flee()

func accept_damage(damage: float, dmg_type: Array[GameManager.PhaseType]) -> void:
	if dying or not _grown:
		return
	if not dmg_type.has(GameManager.PhaseType.HEALTH):
		return
	if not _coffins.is_empty():
		_show_denied_number()
		return
	SFX.play_sound("enemy_hurt")
	_show_damage_number(damage)
	_flash_hit()
	health -= damage
	Signalbus.encounter_progress.emit(HEALTH_STAGE, STAGE_COUNT, maxf(health, 0.0), max_health)
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

func _show_denied_number() -> void:
	var dn: DamageNumber = DAMAGE_NUMBER.instantiate()
	dn.position = global_position
	dn.z_index = 2000
	get_tree().current_scene.add_child(dn)
	dn.show_damage("denied", DamageNumber.COLOR_DEALT)

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
