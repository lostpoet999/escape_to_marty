class_name ShadowImp
extends PlacedEnemy

enum ImpState {
	MATERIALIZE = 0,
	WANDER = 1,
	ATTACK = 2,
	BROOD = 3,
	HIDE = 4,
	DIVE = 5,
	DRAIN = 6,
	}

const SPOOK_PITCH_SCALE: float = 0.45
const SPOOK_VOLUME_DROP_DB: float = -6.0

@export var max_health: float = 20.0 ## Real HP pool: HEALTH-type damage subtracts its actual amount. Clicks and other verb types never hurt the imp.
@export var materialize_time: float = 0.8 ## Seconds for the spawn fade-in at the random materialize point; the imp is already hittable while fading.
@export var bob_fps: float = 8.0 ## Idle bob animation speed in frames per second; the bob pauses during attack and dive runs.
@export var facing_deadzone: float = 8.0 ## Horizontal distance (px) to the paddle inside which the imp keeps its current facing, so sitting directly overhead doesn't flip-flicker.
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

@export_category("Dive Attack")
@export var dive_damage_min: int = 3 ## Low end of the player damage a landed dive deals.
@export var dive_damage_max: int = 6 ## High end of the player damage a landed dive deals.
@export var dive_cooldown: float = 10.0 ## Seconds after a dive ends (landed, whiffed, or interrupted) before this imp can dive again. Per-imp, not shared. The felt gap is longer: the dive only starts on the next _decide roll that picks it.
@export var dive_track_speed: float = 260.0 ## Approach speed (px/s) while the imp is still homing on the paddle. Slower than the strike so the approach reads as a wind-up.
@export var dive_commit_distance: float = 200.0 ## Distance (px) to the paddle at which the imp locks its impact point and stops tracking. This is the dodge window: move before it and the imp follows, move after it and the imp is committed to empty air.
@export var dive_strike_time: float = 0.35 ## Seconds the committed arc takes. This is how long the player has to slide clear once the imp has locked on.
@export var dive_hit_radius: float = 64.0 ## How far the paddle can be from the locked impact point and still get clipped. Roughly half a paddle width.
@export var dive_arc_offset: float = 70.0 ## Sideways bow (px) of the committed strike, perpendicular to the dive line. Flip the sign to bow the other way; 0 makes it a straight drop.
@export var dive_retreat_speed: float = 420.0 ## Climb speed (px/s) back to the top half of the flight box after a dive ends. Faster than wander so the exit reads as peeling away, slower than the strike so the ball can still tag it on the way out.
@export var idle_tint: Color = Color(0.55, 0.55, 0.55) ## Sprite brightness multiplier the imp sits at when it is not diving. Below white on purpose: on the dark floor the imp should be hard to pick out until it commits. White = as bright as the sprite allows.
@export var dive_reveal_tint: Color = Color(2.2, 2.2, 2.2) ## Sprite brightness multiplier held from the tell through the strike, so a dive stays readable even though the imp is dimmed the rest of the time. Set equal to idle_tint for no reveal.
@export var dive_reveal_time: float = 0.25 ## Seconds the reveal takes to ramp up and to fade back out.
@export var dark_idle_tint: Color = Color(0.85, 0.3, 0.3) ## Resting tint while the room holds no live light. Red on purpose: the imp is dangerous only in the dark, so darkness has to be readable on the imp itself.
@export var dark_reveal_tint: Color = Color(2.4, 0.9, 0.9) ## Reveal tint used in place of dive_reveal_tint while the room is dark, so an attack run stays red instead of washing to white.
@export var dark_damage_multiplier: float = 1.5 ## Dive damage is multiplied by this when the room was dark at the moment the imp committed. 1.0 makes darkness cosmetic.

@export_category("Bite Animation")
@export var bite_sheet: Texture2D ## Spritesheet swapped in for the committed dive: jaws open across the strike arc, snap shut on impact, recover during the retreat. Empty = the dive keeps the idle sheet.
@export var bite_hframes: int = 12 ## Frame count of bite_sheet. Frames before bite_chomp_frame are the jaw-open run-up; the chomp frame and everything after are the clamped hold and recovery.
@export var bite_chomp_frame: int = 4 ## First jaws-shut frame. Shown on the exact frame dive damage resolves; the run-up frames before it are spread evenly across dive_strike_time.
@export var bite_recover_time: float = 0.45 ## Seconds the post-impact frames (bite_chomp_frame through the end) take before the idle sheet swaps back in.
@export var flap_pitch_min: float = 0.55 ## Low end of the per-imp wingflap pitch, rolled once at spawn. Below 1.0 slows the flap; much under 0.6 starts reading as something bigger than an imp.
@export var flap_pitch_max: float = 0.75 ## High end of the per-imp wingflap pitch. The SPREAD between min and max is what stops four imps sounding like four clones of one sample; set both equal to disable the variation.
@export var strike_shake: float = 0.08 ## Camera trauma added per strike on a light or a statue. Small on purpose: a three-strike run fires it three times and four imps can overlap. 0 = no shake.
@export var statue_hit_fx: PackedScene ## Particle burst spawned on the statue each time this imp lands a drain strike. Empty = no burst.
@export var statue_hit_fx_tint: Color = Color(1, 0.25, 0.25) ## Modulate applied to statue_hit_fx, so the shared brick-hit burst reads as damage rather than as a normal ball bounce.
@export var bite_offset: Vector2 = Vector2(-21, 0) ## Sprite offset held while the bite sheet is active; the bite art sits right of frame center, so this lines its start pose up with the idle sheet and keeps the swap from popping sideways.

var health: float
var _state: ImpState = ImpState.MATERIALIZE
var _target_light: DepressionLight
var _target_statue: DepressionStatue
var _behavior_tween: Tween
var _sprite_tween: Tween
var _effect_tween: Tween
var _reveal_tween: Tween
var _bite_tween: Tween
var _bite_active: bool = false
var _idle_sheet: Texture2D
var _idle_hframes: int = 1
var _dive_cooldown_left: float = 0.0
var _dive_tracking: bool = false
var _dive_committed: bool = false
var _dive_in_dark: bool = false
var _dive_impact: Vector2 = Vector2.ZERO
var _bob_time: float = 0.0

@onready var _sprite: Sprite2D = $EnemySprite
@onready var _flap: AudioStreamPlayer2D = $WingFlap

func _ready() -> void:
	health = max_health
	super()
	modulate = Color.WHITE
	modulate.a = 1.0
	timer.stop()
	_idle_sheet = _sprite.texture
	_idle_hframes = _sprite.hframes
	_sprite.self_modulate = _resting_tint()
	_sprite.modulate.a = 0.0
	_flap.finished.connect(_on_flap_finished)
	_flap.pitch_scale = maxf(randf_range(flap_pitch_min, flap_pitch_max), 0.01)
	_flap.play(_random_flap_offset())
	_materialize.call_deferred()

func _physics_process(delta: float) -> void:
	_dive_cooldown_left = maxf(_dive_cooldown_left - delta, 0.0)
	if _state == ImpState.BROOD:
		health = minf(health + brood_regen_rate * delta, max_health)
	elif _state == ImpState.DIVE and _dive_tracking and not _dive_committed:
		_track_dive(delta)
	if not _dive_committed:
		_update_facing()
	if _state != ImpState.ATTACK and _state != ImpState.DRAIN and _state != ImpState.DIVE and not _bite_active:
		_bob_time += delta
		_sprite.frame = int(_bob_time * bob_fps) % _sprite.hframes
	if _state != ImpState.DRAIN and _state != ImpState.DIVE and (_reveal_tween == null or not _reveal_tween.is_valid()):
		_sprite.self_modulate = _resting_tint()
	_update_flap()

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
	var statues: Array[DepressionStatue] = _drainable_statues()
	var choices: Array[ImpState] = [ImpState.WANDER]
	if not lights.is_empty():
		choices.append(ImpState.ATTACK)
	if not statues.is_empty():
		choices.append(ImpState.DRAIN)
	if health < max_health:
		choices.append(ImpState.BROOD)
	if _dive_ready():
		choices.append(ImpState.DIVE)
	var choice: ImpState = choices.pick_random()
	match choice:
		ImpState.ATTACK:
			var light: DepressionLight = lights.pick_random()
			_start_attack(light)
		ImpState.DRAIN:
			var statue: DepressionStatue = statues.pick_random()
			_start_drain(statue)
		ImpState.BROOD:
			_start_brood()
		ImpState.DIVE:
			_start_dive()
		_:
			_start_wander()

func _dive_ready() -> bool:
	if _dive_cooldown_left > 0.0:
		return false
	return _david_hit_target() != null

func _should_flap() -> bool:
	if is_queued_for_deletion():
		return false
	return _state != ImpState.DIVE and _state != ImpState.ATTACK and _state != ImpState.DRAIN

func _update_flap() -> void:
	if _should_flap():
		if not _flap.playing:
			_flap.play()
	elif _flap.playing:
		_flap.stop()

func _on_flap_finished() -> void:
	if _should_flap():
		_flap.play()

func _random_flap_offset() -> float:
	if _flap.stream == null:
		return 0.0
	return randf() * _flap.stream.get_length()

func _room_is_dark() -> bool:
	var gestures: MouseGestures = _gestures()
	return gestures != null and gestures.live_light_count() == 0

func _resting_tint() -> Color:
	return dark_idle_tint if _room_is_dark() else idle_tint

func _reveal_tint() -> Color:
	return dark_reveal_tint if _room_is_dark() else dive_reveal_tint

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
	_sprite.frame = 0
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
	SFX.play_sound("imp_bite_light")
	_shake_camera(strike_shake)
	_punch_sprite()
	if not is_instance_valid(_target_light):
		return
	if final:
		_target_light.extinguish()

func _finish_attack() -> void:
	_target_light = null
	_decide()

func _start_drain(statue: DepressionStatue) -> void:
	_state = ImpState.DRAIN
	_sprite.frame = 0
	_target_statue = statue
	statue.claim_drain(self)
	_play_tell()
	_play_reveal(_reveal_tint())
	_behavior_tween = create_tween()
	_behavior_tween.tween_interval(tell_duration + pause_duration)
	_behavior_tween.tween_callback(_fly_to_statue)

func _fly_to_statue() -> void:
	if not is_instance_valid(_target_statue):
		_finish_drain()
		return
	var target: Vector2 = _clamp_to_flight(_target_statue.global_position)
	var travel: float = maxf(global_position.distance_to(target) / attack_speed, 0.05)
	_behavior_tween = create_tween()
	_behavior_tween.tween_property(self, "global_position", target, travel)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for i: int in strikes_to_break:
		if i > 0:
			_behavior_tween.tween_interval(strike_delay)
		_behavior_tween.tween_callback(_drain_strike)
	_behavior_tween.tween_callback(_finish_drain)

func _drain_strike() -> void:
	SFX.play_sound("imp_bite_statue")
	_shake_camera(strike_shake)
	_punch_sprite()
	if not is_instance_valid(_target_statue):
		return
	_spawn_statue_hit_fx(_target_statue.global_position)
	_target_statue.apply_imp_strike()

func _spawn_statue_hit_fx(at: Vector2) -> void:
	if statue_hit_fx == null:
		return
	var fx: Node2D = statue_hit_fx.instantiate() as Node2D
	if fx == null:
		return
	fx.position = at
	fx.modulate = statue_hit_fx_tint
	get_tree().current_scene.add_child(fx)

func _shake_camera(amount: float) -> void:
	if amount <= 0.0:
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null or not camera.has_method(&"add_trauma"):
		return
	@warning_ignore("unsafe_method_access")
	camera.add_trauma(amount)

func _finish_drain() -> void:
	_release_statue()
	_play_reveal(_resting_tint())
	_decide()

func _release_statue() -> void:
	if is_instance_valid(_target_statue):
		_target_statue.release_drain(self)
	_target_statue = null

func _start_dive() -> void:
	_state = ImpState.DIVE
	SFX.play_sound("imp_dive")
	_sprite.frame = 0
	_dive_tracking = false
	_dive_committed = false
	_play_tell()
	_play_reveal(_reveal_tint())
	_behavior_tween = create_tween()
	_behavior_tween.tween_interval(tell_duration + pause_duration)
	_behavior_tween.tween_callback(func() -> void: _dive_tracking = true)

func _track_dive(delta: float) -> void:
	var david: Node2D = _david_hit_target()
	if david == null:
		_end_dive()
		return
	var target: Vector2 = david.global_position
	global_position = global_position.move_toward(target, dive_track_speed * delta)
	if global_position.distance_to(target) <= dive_commit_distance:
		_commit_dive(target)

func _commit_dive(target: Vector2) -> void:
	_dive_tracking = false
	_dive_committed = true
	_dive_in_dark = _room_is_dark()
	_dive_impact = target
	_face_toward(target.x)
	_punch_sprite()
	SFX.play_sound("imp_cry")
	_start_bite()
	var start: Vector2 = global_position
	var line: Vector2 = target - start
	var perp: Vector2 = Vector2(-line.y, line.x).normalized()
	var mid: Vector2 = (start + target) * 0.5 + perp * dive_arc_offset
	_behavior_tween = create_tween()
	_behavior_tween.tween_method(
		func(t: float) -> void: global_position = _bezier(t, start, mid, target),
		0.0, 1.0, dive_strike_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_behavior_tween.tween_callback(_resolve_dive)

func _resolve_dive() -> void:
	SFX.play_sound("imp_bite")
	_chomp()
	var david: Node2D = _david_hit_target()
	if david != null and david.global_position.distance_to(_dive_impact) <= dive_hit_radius:
		var damage: int = randi_range(dive_damage_min, dive_damage_max)
		if _dive_in_dark:
			damage = roundi(damage * dark_damage_multiplier)
		PlayerData.accept_damage(damage)
	_punch_sprite()
	_end_dive()

func _end_dive() -> void:
	_dive_tracking = false
	_dive_committed = false
	_dive_in_dark = false
	_dive_cooldown_left = dive_cooldown
	_play_reveal(_resting_tint())
	_retreat_to_top()

func _retreat_to_top() -> void:
	_state = ImpState.WANDER
	var mid_y: float = (flight_min_y + flight_max_y) * 0.5
	var target: Vector2 = Vector2(randf_range(flight_min_x, flight_max_x), randf_range(flight_min_y, mid_y))
	var travel: float = maxf(global_position.distance_to(target) / dive_retreat_speed, 0.05)
	_behavior_tween = create_tween()
	_behavior_tween.tween_property(self, "global_position", target, travel)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_behavior_tween.tween_callback(_decide)

func _abort_dive() -> void:
	if _state != ImpState.DIVE:
		return
	_dive_tracking = false
	_dive_committed = false
	_dive_cooldown_left = dive_cooldown

func _start_bite() -> void:
	if bite_sheet == null:
		return
	_bite_active = true
	_sprite.texture = bite_sheet
	_sprite.hframes = bite_hframes
	_apply_bite_offset()
	_sprite.frame = 0
	_kill_bite_tween()
	_bite_tween = create_tween()
	_bite_tween.tween_method(
		func(f: float) -> void: _sprite.frame = mini(int(f), bite_chomp_frame - 1),
		0.0, float(bite_chomp_frame), dive_strike_time
	)

func _chomp() -> void:
	if not _bite_active:
		return
	_kill_bite_tween()
	_sprite.frame = bite_chomp_frame
	_bite_tween = create_tween()
	_bite_tween.tween_method(
		func(f: float) -> void: _sprite.frame = mini(int(f), bite_hframes - 1),
		float(bite_chomp_frame), float(bite_hframes), bite_recover_time
	)
	_bite_tween.tween_callback(_restore_idle_sprite)

func _update_facing() -> void:
	if _state == ImpState.DRAIN and is_instance_valid(_target_statue):
		_face_toward(_target_statue.global_position.x)
		return
	if _state == ImpState.ATTACK and is_instance_valid(_target_light):
		_face_toward(_target_light.global_position.x)
		return
	var david: Node2D = get_tree().get_first_node_in_group(&"david") as Node2D
	if david == null:
		return
	_face_toward(david.global_position.x)

func _face_toward(x: float) -> void:
	var dx: float = x - global_position.x
	if absf(dx) < facing_deadzone:
		return
	var flipped: bool = dx > 0.0
	if flipped == _sprite.flip_h:
		return
	_sprite.flip_h = flipped
	if _bite_active:
		_apply_bite_offset()

func _apply_bite_offset() -> void:
	var flip_sign: float = -1.0 if _sprite.flip_h else 1.0
	_sprite.offset = Vector2(bite_offset.x * flip_sign, bite_offset.y)

func _restore_idle_sprite() -> void:
	_bite_active = false
	_sprite.texture = _idle_sheet
	_sprite.hframes = _idle_hframes
	_sprite.offset = Vector2.ZERO
	_sprite.frame = 0

func _kill_bite_tween() -> void:
	if _bite_tween != null and _bite_tween.is_valid():
		_bite_tween.kill()

func _play_reveal(tint: Color) -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_reveal_tween = create_tween()
	_reveal_tween.tween_property(_sprite, "self_modulate", tint, dive_reveal_time)

func _bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var u: float = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

func _gestures() -> MouseGestures:
	return get_tree().get_first_node_in_group(&"mouse_gestures") as MouseGestures

func _david_hit_target() -> Node2D:
	var david: Node2D = get_tree().get_first_node_in_group(&"david") as Node2D
	if david == null:
		return null
	return david.get_node_or_null("DavidHitTarget") as Node2D

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
	_abort_dive()
	_kill_behavior_tweens()
	_state = ImpState.HIDE
	_target_light = null
	_release_statue()
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
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_kill_bite_tween()
	if _bite_active:
		_restore_idle_sprite()
	_sprite.position = Vector2.ZERO
	_sprite.scale = Vector2.ONE
	_sprite.self_modulate = _resting_tint()
	modulate = Color(1.0, 1.0, 1.0, modulate.a)

func accept_damage(damage: float, dmg_type: Array[GameManager.PhaseType]) -> void:
	if not dmg_type.has(GameManager.PhaseType.HEALTH):
		if _dive_committed:
			return
		var spook_sound: AudioStreamPlayer = SFX.play_sound("enemy_hurt")
		if spook_sound != null:
			spook_sound.pitch_scale = SPOOK_PITCH_SCALE
			spook_sound.volume_db += SPOOK_VOLUME_DROP_DB
		_start_hide()
		return
	SFX.play_sound("enemy_hurt")
	show_damage_number(damage)
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
	_abort_dive()
	_kill_behavior_tweens()
	_release_statue()
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
		if depression_light != null and not depression_light.is_queued_for_deletion() and depression_light.is_lit():
			out.append(depression_light)
	return out

func _drainable_statues() -> Array[DepressionStatue]:
	var out: Array[DepressionStatue] = []
	for node: Node in get_tree().get_nodes_in_group(&"depression_statue"):
		var statue: DepressionStatue = node as DepressionStatue
		if statue != null and not statue.is_queued_for_deletion() and statue.is_drainable(self):
			out.append(statue)
	return out
