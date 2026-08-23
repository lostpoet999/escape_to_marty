class_name CollectorHand
extends Area2D

signal hand_died(hand: CollectorHand)
signal hand_spooked(hand: CollectorHand)

const DAMAGE_NUMBER: PackedScene = preload("uid://bedvoohhfbi03")

@export var idle_fps: float = 6.0
@export var mirrored: bool = false
@export var bob_wait_min: float = 2.5
@export var bob_wait_max: float = 7.0
@export var bob_pixels: float = 8.0
@export var bob_time: float = 0.8
@export var twist_wait_min: float = 4.0
@export var twist_wait_max: float = 9.0
@export var twist_degrees: float = 12.0
@export var twist_time: float = 1.0
@export var max_health: float = 30.0
@export var swipe_damage: int = 1
@export var swipe_stun: float = 0.6
@export var swipe_raise_pixels: float = 40.0
@export var swipe_overshoot_pixels: float = 90.0
@export var death_shrink_time: float = 0.35
@export var emerge_rise_pixels: float = 60.0
@export var emerge_rise_time: float = 0.9
@export var emerge_fly_speed: float = 620.0
@export var spook_vanish_seconds: float = 1.5
@export var swipe_flash_color: Color = Color(1.7, 0.3, 0.3)
@export var palm_mouth_texture: Texture2D
@export var mouth_glow_color: Color = Color(2.0, 0.7, 0.4)

var health: float
var _dead: bool = false
var _emerging: bool = false
var _channeling: bool = false
var _spook_vanished: bool = false
var _swiping: bool = false
var _swipe_hit: bool = false
var _idle_time: float = 0.0
var _idle_enabled: bool = true
var _rest_sprite_y: float = 0.0
var _rest_sprite_rotation: float = 0.0
var _bob_wait: float = 0.0
var _twist_wait: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
var _bob_tween: Tween
var _twist_tween: Tween
var _death_tween: Tween
var _mouth_tween: Tween
var _collector: Collector

func _ready() -> void:
	var sprite: Sprite2D = $Sprite2D
	sprite.flip_h = mirrored
	health = max_health
	_base_scale = scale
	_rest_sprite_y = sprite.position.y
	_rest_sprite_rotation = sprite.rotation
	_bob_wait = randf_range(bob_wait_min, bob_wait_max)
	_twist_wait = randf_range(twist_wait_min, twist_wait_max)
	_collector = get_parent() as Collector
	$CollisionShape2D.disabled = true
	body_entered.connect(_on_body_entered)

func is_alive() -> bool:
	return not _dead and not _emerging

func is_dead() -> bool:
	return _dead

func is_working() -> bool:
	return is_alive() and not _spook_vanished

func set_combat_enabled(enabled: bool) -> void:
	$CollisionShape2D.set_deferred("disabled", not enabled)

func set_channeling(channeling: bool) -> void:
	_channeling = channeling

func set_mouth_open(open: bool) -> void:
	var mouth: Sprite2D = get_node_or_null(^"PalmMouth") as Sprite2D
	if palm_mouth_texture != null and mouth != null:
		mouth.texture = palm_mouth_texture
		mouth.visible = open
		return
	var sprite: Sprite2D = $Sprite2D
	if _mouth_tween != null:
		_mouth_tween.kill()
	_mouth_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_mouth_tween.tween_property(sprite, "self_modulate", mouth_glow_color if open else Color.WHITE, 0.25)

func get_muzzle_position() -> Vector2:
	var muzzle: Marker2D = get_node_or_null(^"Muzzle") as Marker2D
	return muzzle.global_position if muzzle != null else global_position

func set_idle_enabled(enabled: bool) -> void:
	_idle_enabled = enabled
	var sprite: Sprite2D = $Sprite2D
	if enabled:
		_rest_sprite_y = sprite.position.y
		_rest_sprite_rotation = sprite.rotation
		_bob_wait = randf_range(bob_wait_min, bob_wait_max)
		_twist_wait = randf_range(twist_wait_min, twist_wait_max)
		return
	if _bob_tween != null:
		_bob_tween.kill()
	if _twist_tween != null:
		_twist_tween.kill()
	sprite.position.y = _rest_sprite_y
	sprite.rotation = _rest_sprite_rotation

func _process(delta: float) -> void:
	var sprite: Sprite2D = $Sprite2D
	_idle_time += delta * idle_fps
	var step: int = int(_idle_time) % sprite.hframes
	sprite.frame = (sprite.hframes - 1 - step) if mirrored else step
	if not _idle_enabled or _dead or _emerging:
		return
	_bob_wait -= delta
	if _bob_wait <= 0.0:
		_bob_wait = randf_range(bob_wait_min, bob_wait_max)
		_start_bob()
	_twist_wait -= delta
	if _twist_wait <= 0.0:
		_twist_wait = randf_range(twist_wait_min, twist_wait_max)
		_start_twist()

func _start_bob() -> void:
	if _bob_tween != null and _bob_tween.is_running():
		return
	var sprite: Sprite2D = $Sprite2D
	_bob_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(sprite, "position:y", _rest_sprite_y - bob_pixels, bob_time * 0.5)
	_bob_tween.tween_property(sprite, "position:y", _rest_sprite_y, bob_time * 0.5)

func _start_twist() -> void:
	if _twist_tween != null and _twist_tween.is_running():
		return
	var sprite: Sprite2D = $Sprite2D
	var direction: float = -1.0 if mirrored else 1.0
	var target: float = _rest_sprite_rotation + deg_to_rad(twist_degrees) * direction
	_twist_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_twist_tween.tween_property(sprite, "rotation", target, twist_time * 0.5)
	_twist_tween.tween_property(sprite, "rotation", _rest_sprite_rotation, twist_time * 0.5)

func accept_damage(damage: float, dmg_type: Array[GameManager.PhaseType]) -> void:
	if _dead or _emerging:
		return
	if not dmg_type.has(GameManager.PhaseType.HEALTH):
		if _channeling and not _spook_vanished:
			_spook()
		return
	if _collector != null and _collector.is_bubbled():
		_show_denied_number()
		return
	SFX.play_sound("enemy_hurt")
	_show_damage_number(damage)
	_flash_hit()
	health -= damage
	if health <= 0.0:
		_die_hand()

func responding_gestures() -> Array[GameManager.PhaseType]:
	if _channeling and is_alive() and not _spook_vanished:
		var gestures: Array[GameManager.PhaseType] = [GameManager.PhaseType.DENIAL]
		return gestures
	return []

func begin_swipe(target_local: Vector2, windup: float, strike_time: float, recover: float) -> void:
	if not is_alive():
		return
	set_idle_enabled(false)
	var start: Vector2 = position
	var raise_target: Vector2 = start + Vector2(0.0, -swipe_raise_pixels)
	var flash_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i: int in 2:
		flash_tween.tween_property(self, "modulate", swipe_flash_color, windup * 0.25)
		flash_tween.tween_property(self, "modulate", Color.WHITE, windup * 0.25)
	var windup_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	windup_tween.tween_property(self, "position", raise_target, windup)
	await windup_tween.finished
	if not is_alive():
		return
	_swiping = true
	_swipe_hit = false
	var through: Vector2 = target_local + (target_local - raise_target).normalized() * swipe_overshoot_pixels
	var strike_tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	strike_tween.tween_property(self, "position", through, strike_time)
	await strike_tween.finished
	_swiping = false
	if not is_alive():
		return
	var recover_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	recover_tween.tween_property(self, "position", start, recover)
	await recover_tween.finished
	set_idle_enabled(true)

func begin_emerge(rest_local: Vector2) -> void:
	if _death_tween != null:
		_death_tween.kill()
		_death_tween = null
	_dead = false
	_emerging = true
	_spook_vanished = false
	visible = true
	scale = _base_scale
	modulate = Color.WHITE
	$Sprite2D.self_modulate = Color.WHITE
	health = max_health
	var rise_tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(self, "position:y", position.y - emerge_rise_pixels, emerge_rise_time)
	await rise_tween.finished
	var parent_node: Node2D = get_parent() as Node2D
	var rest_global: Vector2 = parent_node.to_global(rest_local) if parent_node != null else global_position
	var fly_time: float = maxf(global_position.distance_to(rest_global) / emerge_fly_speed, 0.15)
	var fly_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fly_tween.tween_property(self, "position", rest_local, fly_time)
	await fly_tween.finished
	_emerging = false
	set_combat_enabled(true)
	set_idle_enabled(true)

func _die_hand() -> void:
	_dead = true
	_swiping = false
	set_idle_enabled(false)
	set_combat_enabled(false)
	SFX.play_sound("deon_die")
	hand_died.emit(self)
	_death_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_death_tween.tween_property(self, "scale", Vector2.ZERO, death_shrink_time)
	_death_tween.tween_callback(_finish_death)

func _finish_death() -> void:
	visible = false

func _spook() -> void:
	_spook_vanished = true
	hand_spooked.emit(self)
	set_combat_enabled(false)
	SFX.play_sound("enemy_hurt")
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_interval(spook_vanish_seconds)
	tween.tween_property(self, "scale", _base_scale, 0.2)
	tween.tween_callback(_end_spook)

func _end_spook() -> void:
	_spook_vanished = false
	if not _dead:
		set_combat_enabled(true)

func _on_body_entered(body: Node2D) -> void:
	if not _swiping or _swipe_hit or _dead:
		return
	if not body.is_in_group(GameManager.PADDLE):
		return
	_swipe_hit = true
	if body.has_method("freeze_paddle_for_time"):
		body.freeze_paddle_for_time(swipe_stun)
	PlayerData.accept_damage(swipe_damage)
	SFX.play_sound("cage_hit")

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
