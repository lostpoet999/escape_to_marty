class_name ShadowImp
extends PlacedEnemy

enum ImpState {
	MATERIALIZE = 0,
	WANDER = 1,
	ATTACK = 2,
	BROOD = 3,
	HIDE = 4,
	}

@export var max_health: float = 20.0 ## Real HP pool: HEALTH-type damage subtracts its actual amount. Clicks and other verb types never hurt the imp.
@export var materialize_time: float = 0.8 ## Seconds for the spawn fade-in at the random materialize point; the imp is already hittable while fading.
@export var decide_interval: float = 2.5 ## Target seconds per wander leg before the next behavior roll; travel shorter than this pads out with idle hover.
@export var wander_range: float = 340.0 ## Max px offset from the current position when picking the next wander point.
@export var wander_speed: float = 150.0 ## Cruise speed (px/s) for wandering and the brood retreat.
@export var attack_speed: float = 182.0 ## Dive speed (px/s) when flying at a targeted depression light.
@export var tell_duration: float = 0.6 ## Seconds of sprite-shake wind-up before an attack run.
@export var pause_duration: float = 0.4 ## Seconds of dead stillness between the tell and the dive.
@export var strike_delay: float = 0.5 ## Seconds between consecutive strikes on a light.
@export var strikes_to_break: int = 3 ## Strikes needed to snuff a light; only the final strike extinguishes it.
@export var flee_speed: float = 700.0 ## Sprint speed (px/s) toward the nearest wall when a click spooks the imp.
@export var hide_duration: float = 4.0 ## Seconds spent faded out against the wall before re-emerging.
@export var hide_alpha: float = 0.15 ## Sprite alpha while hiding: barely visible, but the collider stays live so the ball can still hit it.
@export var brood_duration: float = 4.0 ## Seconds spent perched at the wall regenerating before the next behavior roll.
@export var brood_regen_rate: float = 1.5 ## HP regained per second while brooding, capped at max_health.
@export var flight_min_x: float = 352.0 ## Left bound (world) for the imp's center; keeps the box clear of the left wall inner face at x 320.
@export var flight_max_x: float = 1824.0 ## Right bound (world) for the imp's center; keeps the box clear of the right wall inner face at x 1856.
@export var flight_min_y: float = 96.0 ## Top bound (world) for the imp's center; keeps the box clear of the top wall inner face at y 64.
@export var flight_max_y: float = 880.0 ## Bottom bound (world) for the imp's center; stays above the paddle and the DeathWall band that starts near y 960.
@export var destroy_fx: PackedScene ## Particle burst instanced at the imp's position when it dies. Empty = no burst.

var health: float
var _state: ImpState = ImpState.MATERIALIZE
var _target_light: DepressionLight
var _behavior_tween: Tween
var _sprite_tween: Tween
var _effect_tween: Tween

@onready var _sprite: Sprite2D = $EnemySprite

func _ready() -> void:
	health = max_health
	super()
	modulate = Color.WHITE
	modulate.a = 1.0
	timer.stop()
	_sprite.modulate.a = 0.0
	_materialize.call_deferred()

func _physics_process(delta: float) -> void:
	if _state == ImpState.BROOD:
		health = minf(health + brood_regen_rate * delta, max_health)

func _materialize() -> void:
	if is_queued_for_deletion():
		return
	_state = ImpState.MATERIALIZE
	global_position = _random_flight_point()
	_behavior_tween = create_tween()
	_behavior_tween.tween_property(_sprite, "modulate:a", 1.0, materialize_time).from(0.0)
	_behavior_tween.tween_callback(_decide)

func _decide() -> void:
	if is_queued_for_deletion():
		return
	if GameManager.current_state == GameManager.GameState.LEVEL_CLEARED:
		return
	var lights: Array[DepressionLight] = _live_lights()
	var choices: Array[ImpState] = [ImpState.WANDER]
	if not lights.is_empty():
		choices.append(ImpState.ATTACK)
	if health < max_health:
		choices.append(ImpState.BROOD)
	var choice: ImpState = choices.pick_random()
	match choice:
		ImpState.ATTACK:
			var light: DepressionLight = lights.pick_random()
			_start_attack(light)
		ImpState.BROOD:
			_start_brood()
		_:
			_start_wander()

func _start_wander() -> void:
	_state = ImpState.WANDER
	var offset: Vector2 = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	var target: Vector2 = _clamp_to_flight(global_position + offset)
	var travel: float = maxf(global_position.distance_to(target) / wander_speed, 0.05)
	_behavior_tween = create_tween()
	_behavior_tween.tween_property(self, "global_position", target, travel)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if travel < decide_interval:
		_behavior_tween.tween_interval(decide_interval - travel)
	_behavior_tween.tween_callback(_decide)

func _start_attack(light: DepressionLight) -> void:
	_state = ImpState.ATTACK
	_target_light = light
	_play_tell()
	_behavior_tween = create_tween()
	_behavior_tween.tween_interval(tell_duration + pause_duration)
	_behavior_tween.tween_callback(_fly_to_light)

func _fly_to_light() -> void:
	if not is_instance_valid(_target_light):
		_finish_attack()
		return
	var target: Vector2 = _clamp_to_flight(_target_light.global_position)
	var travel: float = maxf(global_position.distance_to(target) / attack_speed, 0.05)
	_behavior_tween = create_tween()
	_behavior_tween.tween_property(self, "global_position", target, travel)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for i: int in strikes_to_break:
		if i > 0:
			_behavior_tween.tween_interval(strike_delay)
		_behavior_tween.tween_callback(_strike.bind(i == strikes_to_break - 1))
	_behavior_tween.tween_callback(_finish_attack)

func _strike(final: bool) -> void:
	_punch_sprite()
	if not is_instance_valid(_target_light):
		return
	if final:
		_target_light.extinguish()

func _finish_attack() -> void:
	_target_light = null
	_decide()

func _start_brood() -> void:
	_state = ImpState.BROOD
	var perch: Vector2 = _nearest_wall_point()
	var travel: float = maxf(global_position.distance_to(perch) / wander_speed, 0.05)
	_behavior_tween = create_tween()
	_behavior_tween.tween_property(self, "global_position", perch, travel)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_behavior_tween.tween_interval(brood_duration)
	_behavior_tween.tween_callback(_decide)

func _start_hide() -> void:
	_kill_behavior_tweens()
	_state = ImpState.HIDE
	_target_light = null
	var refuge: Vector2 = _nearest_wall_point()
	var travel: float = maxf(global_position.distance_to(refuge) / flee_speed, 0.05)
	_behavior_tween = create_tween()
	_behavior_tween.tween_property(self, "global_position", refuge, travel)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_behavior_tween.tween_interval(hide_duration)
	_behavior_tween.tween_callback(_unhide)
	_sprite_tween = create_tween()
	_sprite_tween.tween_property(_sprite, "modulate:a", hide_alpha, 0.25)

func _unhide() -> void:
	_sprite_tween = create_tween()
	_sprite_tween.tween_property(_sprite, "modulate:a", 1.0, 0.3)
	_decide()

func _play_tell() -> void:
	_sprite_tween = create_tween()
	var cycles: int = maxi(roundi(tell_duration / 0.1), 1)
	for i: int in cycles:
		var shake_x: float = 6.0 if i % 2 == 0 else -6.0
		_sprite_tween.tween_property(_sprite, "position:x", shake_x, 0.05)
	_sprite_tween.tween_property(_sprite, "position:x", 0.0, 0.05)

func _punch_sprite() -> void:
	_effect_tween = create_tween()
	_effect_tween.tween_property(_sprite, "scale", Vector2(1.25, 1.25), 0.06)
	_effect_tween.tween_property(_sprite, "scale", Vector2.ONE, 0.1)

func _flash_hit() -> void:
	var mat: ShaderMaterial = _sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_amount", 1.0)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("flash_amount", v),
		1.0, 0.0, 0.05
	)
	var before_shake_pos: Vector2 = global_position
	var shake_effect: ShakeEffect = ShakeEffect.new()
	shake_effect.apply_to(self, _sprite)
	global_position = before_shake_pos

func _kill_behavior_tweens() -> void:
	if _behavior_tween != null and _behavior_tween.is_valid():
		_behavior_tween.kill()
	if _sprite_tween != null and _sprite_tween.is_valid():
		_sprite_tween.kill()
	if _effect_tween != null and _effect_tween.is_valid():
		_effect_tween.kill()
	_sprite.position = Vector2.ZERO
	_sprite.scale = Vector2.ONE

func accept_damage(damage: float, dmg_type: Array[GameManager.PhaseType]) -> void:
	if not dmg_type.has(GameManager.PhaseType.HEALTH):
		_start_hide()
		return
	SFX.play_sound("enemy_hurt")
	show_damage_number(roundi(damage))
	_flash_hit()
	health -= damage
	if health <= 0.0:
		die()

func die() -> void:
	if is_queued_for_deletion(): return
	ready_to_remove.emit(self)
	@warning_ignore("unsafe_method_access")
	get_viewport().get_camera_2d().add_trauma(0.5)
	SFX.play_sound("deon_die")
	if destroy_fx != null:
		var fx: Node2D = destroy_fx.instantiate()
		fx.position = global_position
		get_tree().current_scene.add_child(fx)
	queue_free()

func stun_for_time(duration: float) -> void:
	_kill_behavior_tweens()
	_sprite.modulate.a = 1.0
	_state = ImpState.WANDER
	var original_modulate: Color = modulate
	var pulse_color: Color = Color(1.0, 0.25, 0.25, original_modulate.a)
	var cycles: int = maxi(roundi(duration / 0.4), 1)
	_behavior_tween = create_tween()
	for _i: int in cycles:
		_behavior_tween.tween_property(self, "modulate", pulse_color, 0.2)
		_behavior_tween.tween_property(self, "modulate", original_modulate, 0.2)
	_behavior_tween.tween_callback(_decide)

func _random_flight_point() -> Vector2:
	return Vector2(randf_range(flight_min_x, flight_max_x), randf_range(flight_min_y, flight_max_y))

func _clamp_to_flight(point: Vector2) -> Vector2:
	return Vector2(clampf(point.x, flight_min_x, flight_max_x), clampf(point.y, flight_min_y, flight_max_y))

func _nearest_wall_point() -> Vector2:
	var here: Vector2 = global_position
	var candidates: Array[Vector2] = [
		Vector2(flight_min_x, clampf(here.y, flight_min_y, flight_max_y)),
		Vector2(flight_max_x, clampf(here.y, flight_min_y, flight_max_y)),
		Vector2(clampf(here.x, flight_min_x, flight_max_x), flight_min_y),
	]
	var best: Vector2 = candidates[0]
	for candidate: Vector2 in candidates:
		if here.distance_squared_to(candidate) < here.distance_squared_to(best):
			best = candidate
	return best

func _live_lights() -> Array[DepressionLight]:
	var out: Array[DepressionLight] = []
	var gestures: MouseGestures = get_tree().get_first_node_in_group(&"mouse_gestures") as MouseGestures
	if gestures == null:
		return out
	for light: Node2D in gestures.depression_lights:
		var depression_light: DepressionLight = light as DepressionLight
		if depression_light != null and not depression_light.is_queued_for_deletion():
			out.append(depression_light)
	return out
