class_name Paddle
extends CharacterBody2D

const HEART_DESTROY_FX: PackedScene = preload("res://scenes_and_scripts/actors/player/heart_destroy_fx.tscn")
const DEATH_SEAL_TEXTURE: Texture2D = preload("res://scenes_and_scripts/bricks/brick-gemstone-facets.png")
const DEATH_SEAL_COLOR: Color = Color("a23e8c")

const WEB_BOX_COLOR: Color = Color(0.87451, 0.517647, 0.647059, 0.85)
const WEB_SHAKE_MIN_PIXELS: float = 6.0
const WEB_BOX_MARGIN: Vector2 = Vector2(24.0, 48.0)

const SHIELD_COLOR: Color = Color(0.5, 0.8, 1.0)
const SHIELD_COLOR_BRIGHT: Color = Color(0.8, 0.95, 1.0)
const SHIELD_COLOR_STRONG: Color = Color("3c5e8b")
const SHIELD_COLOR_STRONG_BRIGHT: Color = Color("4f8fba")
const SHIELD_PULSE_TIME: float = 0.45
const DIP_DEPTH: float = 6.0
const DIP_DOWN_TIME: float = 0.05
const DIP_RETURN_TIME: float = 0.12

@export var paddle_influence: float = 5.0
## Paddle speed (px/s) below which David and the paddle stay upright — no lean.
@export var lean_speed_threshold: float = 330.0
## Paddle speed (px/s) at which the lean reaches its full angle.
@export var lean_full_speed: float = 2600.0
## Full lean angle for the paddle sprite, in degrees.
@export var paddle_lean_degrees: float = 5.5
## Full lean angle for David, in degrees — pivots near his head so his feet trail the motion.
@export var david_lean_degrees: float = 16.9
## How quickly the lean eases toward its target; higher = snappier.
@export var lean_responsiveness: float = 10.0

@export_category("Death Sequence")
## Seconds the killing hit's feedback (red flash, damage number, screen shake) settles before the death sequence starts.
@export var death_damage_settle: float = 0.6
## Seconds of the bad_sting spent shaking David and shrinking him to a point; the catch-seal pops when this ends (sting is ~2.0s total).
@export var death_shrink_time: float = 1.55
## Peak pixels of David's death-shake jitter; ramps up as he shrinks.
@export var death_shake_amount: float = 7.0
## Seconds the catch-seal lingers after its pop before the run ends.
@export var death_seal_hold: float = 0.8
## Seconds the death seal takes to shrink away after the hold, right before the game-over menu shows.
@export var death_seal_exit_time: float = 0.35
## Camera zoom multiplier during the death cinematic (1.0 = no zoom; Camera2D zoom >1 magnifies, framing David like he's speaking). The push toward David is clamped so the view never shows outside the world, exactly like the DialogDirector focus zoom.
@export var death_zoom: float = 1.6
## Seconds to ease the death zoom-in; runs during the settle beat so David is framed before his heart pops.
@export var death_zoom_time: float = 0.55

var is_shielded: bool = false
var _shield_count: int = 0
var _death_running: bool = false
var _ghost_base_pos: Vector2 = Vector2.ZERO
var shield_pulse_tween: Tween
var _dip_tween: Tween
var _sprite_base_y: float
var _david_base_y: float
var paddle_frozen: bool = false
var paddle_click_dmg: float = 1.0
var _webbed: bool = false
var _web_shakes_needed: int = 0
var _web_shakes: int = 0
var _web_last_dir: float = 0.0
var _web_box: ColorRect

var freeze_timer : Timer

# Screen bounds
var left_bound: float = 0.0
var right_bound: float = 0.0
var last_position: Vector2 = Vector2()
var current_speed: float = 0.0

var accumulated_mouse_movement_x: float = 0
var mouse_sensitivity: float = 1.0
var is_tweening_to_david: bool = false


var base_scale_x: float
var base_shape_size_x: float


@onready var sprite: Sprite2D = $PaddleSprite
@onready var paddle_collision_shape: CollisionShape2D = $PaddleCollisionShape

var committed_distance: float = 0.0
var _last_direction: float = 0.0
var _distance_accumulator: float = 0.0



@export var paddle_powerups: Array[PaddlePowerup]
@export var active_paddle_powerup: PaddleActive #will type cast later
@onready var projectiles: Node = $"../Projectiles"
@onready var david: Node2D = $David
@onready var ghost_david: Node2D = $David/GhostDavid
@onready var magnet_refresh: Timer = $Ball_Magnet_Radius/MagnetRefresh
@onready var magnet_radius_outline: ColorRect = $Ball_Magnet_Radius/ColorRect

var _lean_blend: float = 0.0

var blocker_enemies: Array[PlacedEnemy] #hold blocker enemies in paddle path


func _ready() -> void:	
	last_position = global_position
	connect_signals()
	_sprite_base_y = sprite.position.y
	_david_base_y = david.position.y
	base_scale_x = sprite.scale.x
	base_shape_size_x = paddle_collision_shape.scale.x	
	paddle_powerups = PlayerData.inventory.get_items_for_paddle()	
	set_paddle_length_from_items()
	
	_calculate_bounds()
	accumulated_mouse_movement_x = position.x
	active_paddle_powerup = PlayerData.inventory.get_paddle_active()
	_update_magnet_outline()
	# free-miss shields persist run-scoped on PlayerData; re-apply the glow on every paddle
	# spawn (new room/floor) so the visual matches the banked count, not just live grants
	_on_reflect_shield_changed(PlayerData.get_player_shields())

func connect_signals()->void:	
	Signalbus.game_state_click_mode.connect(_on_game_state_click_mode)
	Signalbus.game_state_playing.connect(_on_game_state_playing)
	Signalbus.paddle_active_assigned.connect(_assign_active_powerup)
	Signalbus.paddle_swap_resolved.connect(_assign_active_powerup)
	Signalbus.game_state_special_room.connect(_on_game_state_click_mode)	
	Signalbus.inventory_changed.connect(set_paddle_length_from_items)
	
	Signalbus.player_died.connect(_run_death_sequence)
	Signalbus.level_cleared.connect(_release_web)
	Signalbus.blocker_added.connect(add_blocker_enemy)
	Signalbus.blocker_removed.connect(remove_blocker_enemy)
	Signalbus.blocker_moved.connect(_calculate_blockers_bounds)
	Signalbus.reflect_shield_changed.connect(_on_reflect_shield_changed)
	Signalbus.reset_magnet_refresh.connect(reset_magnet_refresh_timer)

func adjust_paddle_length(modify_by: float) -> void:
	sprite.scale.x *= modify_by
	paddle_collision_shape.scale.x *= modify_by

func reset_paddle_length()->void:
	sprite.scale.x = base_scale_x
	paddle_collision_shape.scale.x = base_shape_size_x

func set_paddle_hidden(hidden: bool, include_david: bool = false) -> void:
	sprite.visible = not hidden
	paddle_collision_shape.set_deferred("disabled", hidden)
	if include_david:
		david.visible = not hidden

func set_paddle_length_from_items()->void:
	paddle_powerups = PlayerData.inventory.get_items_for_paddle()  # refresh first
	if paddle_powerups.is_empty(): return
	reset_paddle_length()
	for item: BaseItem in paddle_powerups:
		var paddle_item: PaddlePowerup = item
		if paddle_item.paddle_length_mod > 0.0:
			adjust_paddle_length(paddle_item.paddle_length_mod)

func _calculate_bounds() -> void:
	var half_width: float = _get_scaled_half_width()
	var walls: Array = get_tree().get_nodes_in_group("walls")
	var min_x: float = INF
	var max_x: float = -INF
	for wall: Area2D in walls:
		min_x = minf(min_x, wall.global_position.x)
		max_x = maxf(max_x, wall.global_position.x)
	# Offset by wall collision half-size (32) to get inner edges
	left_bound = min_x + 32.0 + half_width
	right_bound = max_x - 32.0 - half_width

func add_blocker_enemy(blocker: PlacedEnemy)->void:
	blocker_enemies.push_back(blocker)
	_calculate_blockers_bounds()

func remove_blocker_enemy(blocker: PlacedEnemy)->void:
	blocker_enemies.erase(blocker)
	_calculate_blockers_bounds()
	

func _calculate_blockers_bounds() -> void:
	_calculate_bounds()
	var left_blockers: Array[PlacedEnemy] = blocker_enemies.filter(
		func(e: PlacedEnemy) -> bool: return e.global_position.x < global_position.x	)
	var temp_edge: float = left_bound
	if !left_blockers.is_empty():
		for blocker: PlacedEnemy in left_blockers:
			var blocker_edge:float = blocker.get_edge(self)
			if blocker_edge > temp_edge: temp_edge = blocker_edge
		left_bound = temp_edge
	var right_blockers: Array[PlacedEnemy] = blocker_enemies.filter(
		func(e: PlacedEnemy) -> bool: return e.global_position.x > global_position.x	)
	temp_edge = right_bound
	if !right_blockers.is_empty():
		for blocker: PlacedEnemy in right_blockers:
			var blocker_edge: float = blocker.get_edge(self)
			if blocker_edge < temp_edge: temp_edge = blocker_edge
		right_bound = temp_edge
	accumulated_mouse_movement_x = clamp(accumulated_mouse_movement_x, left_bound, right_bound)

func _assign_active_powerup(item: PaddleActive)->void:
	active_paddle_powerup = item
	_update_magnet_outline()


func _get_scaled_half_width() -> float:	
	var texture_width: float = sprite.texture.get_width()
	return (texture_width * sprite.scale.x * scale.x) / 2.0
	
func _on_game_state_playing() -> void:
	paddle_frozen = false
	_set_desaturate(0.0)

func _on_game_state_click_mode() -> void:
	paddle_frozen = true
	_set_desaturate(1.0)

func _set_desaturate(amount: float) -> void:
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("desaturate_amount", amount)

func freeze_paddle_for_time(time: float)->void:
	if paddle_frozen:
		return
	if freeze_timer == null:
		freeze_timer = Timer.new()
		freeze_timer.one_shot = true	
		freeze_timer.timeout.connect(_on_freeze_timer_expire)
		add_child(freeze_timer)

	var shake_effect = ShakeEffect.new()
	shake_effect.shake_amount = 30
	shake_effect.apply_to(self, sprite)
		
	freeze_timer.wait_time = time
	freeze_timer.start()
	paddle_frozen = true	
	
func _on_freeze_timer_expire()->void:
	if GameManager.current_state != GameManager.GameState.LEVEL_CLEARED:
		paddle_frozen=false

func apply_web(shakes_to_break: int) -> void:
	if _webbed or _death_running:
		return
	_webbed = true
	_web_shakes = 0
	_web_shakes_needed = maxi(shakes_to_break, 1)
	_web_last_dir = 0.0
	_show_web_box()

func _show_web_box() -> void:
	_web_box = ColorRect.new()
	_web_box.color = WEB_BOX_COLOR
	_web_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_web_box.size = Vector2(_get_scaled_half_width() * 2.0 + WEB_BOX_MARGIN.x, WEB_BOX_MARGIN.y)
	_web_box.position = -_web_box.size * 0.5
	_web_box.pivot_offset = _web_box.size * 0.5
	_web_box.z_index = 10
	add_child(_web_box)

func _count_web_shake(relative_x: float) -> void:
	if absf(relative_x) < WEB_SHAKE_MIN_PIXELS:
		return
	var dir: float = signf(relative_x)
	if dir == _web_last_dir:
		return
	if _web_last_dir != 0.0:
		_web_shakes += 1
		_jiggle_web_box()
		if _web_shakes >= _web_shakes_needed:
			_release_web()
			return
	_web_last_dir = dir

func _jiggle_web_box() -> void:
	if _web_box == null:
		return
	var jiggle: Tween = create_tween()
	jiggle.tween_property(_web_box, "rotation", 0.12, 0.04)
	jiggle.tween_property(_web_box, "rotation", 0.0, 0.08)

func _release_web() -> void:
	if not _webbed:
		return
	_webbed = false
	accumulated_mouse_movement_x = clamp(position.x, left_bound, right_bound)
	if _web_box != null:
		_web_box.queue_free()
		_web_box = null

func _input(event: InputEvent) -> void:
	if _webbed:
		var web_motion: InputEventMouseMotion = event as InputEventMouseMotion
		if web_motion:
			_count_web_shake(web_motion.relative.x)
	elif !paddle_frozen:
		var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
		if mouse_event:
			accumulated_mouse_movement_x += mouse_event.relative.x * mouse_sensitivity
			accumulated_mouse_movement_x = clamp(accumulated_mouse_movement_x, left_bound, right_bound)
	if Input.is_action_just_pressed("paddle_active_powerup") and GameManager.current_state != GameManager.GameState.LEVEL_CLEARED and GameManager.current_state != GameManager.GameState.SPECIAL_ROOM:
		if active_paddle_powerup and (GameManager.current_state != GameManager.GameState.BALL_ON_PADDLE or active_paddle_powerup.can_activate_on_paddle()):
			active_paddle_powerup.activate(self, projectiles)

func hit_feedback() -> void:	
	var base_scale: Vector2 = scale
	var tw_scale: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_scale.tween_property(self, "scale", base_scale * 0.9, 0.06)
	tw_scale.tween_property(self, "scale", base_scale, 0.18)

	# red flash on David only
	stop_shield_pulse()
	david.modulate = Color.RED
	var tw_flash: Tween = create_tween()
	tw_flash.tween_property(david, "modulate", _resting_david_color(), 0.22)
	if is_shielded:
		tw_flash.finished.connect(start_shield_pulse, CONNECT_ONE_SHOT)

func bounce_dip() -> void:
	if _dip_tween and _dip_tween.is_valid():
		_dip_tween.kill()
	sprite.position.y = _sprite_base_y
	david.position.y = _david_base_y
	_dip_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_dip_tween.tween_property(sprite, "position:y", _sprite_base_y + DIP_DEPTH, DIP_DOWN_TIME)
	_dip_tween.parallel().tween_property(david, "position:y", _david_base_y + DIP_DEPTH, DIP_DOWN_TIME)
	_dip_tween.tween_property(sprite, "position:y", _sprite_base_y, DIP_RETURN_TIME)
	_dip_tween.parallel().tween_property(david, "position:y", _david_base_y, DIP_RETURN_TIME)

func _on_reflect_shield_changed(count: int) -> void:
	_shield_count = count
	is_shielded = count > 0
	if is_shielded:
		start_shield_pulse()
	else:
		stop_shield_pulse()
		var tw: Tween = create_tween()
		tw.tween_property(david, "modulate", Color.WHITE, 0.2)

func start_shield_pulse() -> void:
	stop_shield_pulse()
	var bright: Color = SHIELD_COLOR_STRONG_BRIGHT if _shield_count >= 2 else SHIELD_COLOR_BRIGHT
	shield_pulse_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	shield_pulse_tween.tween_property(david, "modulate", bright, SHIELD_PULSE_TIME)
	shield_pulse_tween.tween_property(david, "modulate", _resting_david_color(), SHIELD_PULSE_TIME)

func stop_shield_pulse() -> void:
	if shield_pulse_tween and shield_pulse_tween.is_valid():
		shield_pulse_tween.kill()
	shield_pulse_tween = null

func _resting_david_color() -> Color:
	if not is_shielded:
		return Color.WHITE
	return SHIELD_COLOR_STRONG if _shield_count >= 2 else SHIELD_COLOR

func david_global_position() -> Vector2:
	return david.global_position

func _run_death_sequence() -> void:
	if _death_running:
		return
	_death_running = true
	_release_web()
	paddle_frozen = true
	_zoom_camera_on_david()
	var ball: Node = get_tree().get_first_node_in_group("ball")
	if ball != null:
		ball.call("remove_ball")
	await get_tree().create_timer(death_damage_settle).timeout
	stop_shield_pulse()
	david.modulate = Color.WHITE
	ghost_david.visible = true
	ghost_david.rotation = 0.0
	set_paddle_hidden(true)
	_ghost_base_pos = ghost_david.position
	var catch_pos: Vector2 = ghost_david.global_position
	_pop_heart()
	SFX.play_sound("bad_sting")
	var shake_tween: Tween = create_tween()
	shake_tween.tween_method(_death_shake, 0.0, 1.0, death_shrink_time)
	var shrink_tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	shrink_tween.tween_property(ghost_david, "scale", Vector2(0.02, 0.02), death_shrink_time)
	await shrink_tween.finished
	ghost_david.visible = false
	var seal: Sprite2D = _pop_death_seal(catch_pos)
	await get_tree().create_timer(death_seal_hold).timeout
	var exit_tween: Tween = seal.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(seal, "scale", Vector2.ZERO, death_seal_exit_time)
	await exit_tween.finished
	seal.queue_free()
	Signalbus.death_sequence_finished.emit()

func _zoom_camera_on_david() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var base_zoom: Vector2 = cam.zoom
	var base_center: Vector2 = cam.get_screen_center_position()
	var max_shift: Vector2 = cam.get_viewport_rect().size * 0.5 / base_zoom * (1.0 - 1.0 / death_zoom)
	var focus: Vector2 = (ghost_david.get_node("GhostSprite") as Node2D).global_position
	var shift: Vector2 = (focus - base_center).clamp(-max_shift, max_shift)
	var cam_tween: Tween = cam.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	cam_tween.parallel().tween_property(cam, "zoom", base_zoom * death_zoom, death_zoom_time)
	cam_tween.parallel().tween_property(cam, "global_position", cam.global_position + shift, death_zoom_time)

func _pop_heart() -> void:
	var orb: Node2D = david.get_node("DavidHitTarget/LifeForceOrb")
	var fx: Node2D = HEART_DESTROY_FX.instantiate()
	fx.position = orb.global_position
	get_tree().current_scene.add_child(fx)
	orb.visible = false

func _death_shake(ramp: float) -> void:
	ghost_david.position = _ghost_base_pos + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * death_shake_amount * ramp

func _pop_death_seal(catch_pos: Vector2) -> Sprite2D:
	var seal: Sprite2D = Sprite2D.new()
	seal.texture = DEATH_SEAL_TEXTURE
	seal.modulate = DEATH_SEAL_COLOR
	seal.scale = Vector2.ZERO
	get_tree().current_scene.add_child(seal)
	seal.global_position = catch_pos
	var pop: Tween = seal.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(seal, "scale", Vector2.ONE, 0.25)
	pop.tween_method(func(decay: float) -> void:
		seal.global_position = catch_pos + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 4.0 * decay,
		1.0, 0.0, 0.2)
	return seal

func get_movement_direction() -> float:
	return current_speed

func _track_committed_distance(prev_x: float) -> void:
	var direction: float = sign(position.x - prev_x)
	if direction != 0.0:
		if direction != _last_direction:
			_distance_accumulator = 0.0
			_last_direction = direction
		_distance_accumulator += abs(position.x - prev_x)
	committed_distance = _distance_accumulator

func reset_committed_distance() -> void:
	_distance_accumulator = 0.0
	committed_distance = 0.0

func _process(delta: float) -> void:
	magnet_refresh.paused = GameManager.current_state != GameManager.GameState.PLAYING
	var speed: float = 0.0 if paddle_frozen else current_speed
	var lean_target: float = 0.0
	if absf(speed) > lean_speed_threshold:
		var ramp: float = (absf(speed) - lean_speed_threshold) / maxf(lean_full_speed - lean_speed_threshold, 1.0)
		lean_target = signf(speed) * clampf(ramp, 0.0, 1.0)
	_lean_blend = lerpf(_lean_blend, lean_target, 1.0 - exp(-lean_responsiveness * delta))
	sprite.rotation = deg_to_rad(paddle_lean_degrees) * _lean_blend
	ghost_david.rotation = deg_to_rad(david_lean_degrees) * _lean_blend

func _physics_process(delta: float) -> void:
	if abs(current_speed) <= 1500.0: reset_committed_distance()
	if !paddle_frozen and !_webbed:
		var prev_x: float = position.x
		position.x = accumulated_mouse_movement_x
		current_speed = (global_position.x - last_position.x) / delta
		last_position = global_position
		_track_committed_distance(prev_x)

func _on_ball_magnet_radius_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area and area.name == "Ball":
		Signalbus.ball_in_magnet_range.emit(true)

func _on_ball_magnet_radius_area_shape_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area and area.name == "Ball":
		Signalbus.ball_in_magnet_range.emit(false)

func _on_magnet_refresh_timeout() -> void:
	Signalbus.magnet_refresh_timeout.emit()
	_update_magnet_outline()

func reset_magnet_refresh_timer() -> void:
	magnet_refresh.start()
	_update_magnet_outline()

func _update_magnet_outline() -> void:
	magnet_radius_outline.visible = active_paddle_powerup is SupportSystem and magnet_refresh.is_stopped()
