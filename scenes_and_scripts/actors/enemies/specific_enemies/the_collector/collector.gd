class_name Collector
extends FallingEnemy

const DAMAGE_NUMBER: PackedScene = preload("uid://bedvoohhfbi03")
const SPIT_COIN: PackedScene = preload("res://scenes_and_scripts/actors/enemies/specific_enemies/repayment_spider/spit_coin.tscn")
const GOLD_PAYLOAD: BonusPayload = preload("res://scenes_and_scripts/collectibles/bonus_drops/currency_payload.tres")
const DARK_CAGE: PackedScene = preload("res://scenes_and_scripts/actors/enemies/specific_enemies/dark_cage/dark_cage.tscn")
const SHADOW_IMP: PackedScene = preload("res://scenes_and_scripts/actors/enemies/specific_enemies/shadow_imp/shadow_imp.tscn")
const CODEC_PLAYER: PackedScene = preload("uid://ccodecplayer")

enum AttackKind {
	SWIPE = 0,
	DENIAL = 1,
	ANGER = 2,
	DEPRESSION = 3,
	}

enum AngerPattern {
	CROSSFIRE = 0,
	RAIN = 1,
	CONVERGE = 2,
	}

const STAGE_COUNT: int = 2
const COFFIN_STAGE: int = 1
const HEALTH_STAGE: int = 2
const MIN_GLIDE_TIME: float = 0.35
const FACE_DEADZONE: float = 1.0
const ATTACK_STATION_EPSILON: float = 8.0

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
@export var coin_respawn_min: float = 9.0
@export var coin_respawn_max: float = 16.0
@export var coin_toss_telegraph: float = 0.4
@export var coin_speed_x_min: float = 155.0
@export var coin_speed_x_max: float = 250.0
@export var coin_arc_y_min: float = -380.0
@export var coin_arc_y_max: float = -200.0
@export var eye_coin_rest_size: float = 18.0
@export var eye_coin_attack_size: float = 32.0
@export var eye_coin_refill_seconds: float = 6.0
@export var eye_coin_pulse_period: float = 1.4
@export var eye_coin_pulse_color: Color = Color(1.9, 0.35, 0.35)
@export var attack_delay_min: float = 8.0
@export var attack_delay_max: float = 14.0
@export var attack_retry_interval: float = 0.75
@export var attack_point: Vector2 = Vector2(1096, 336)
@export var attack_glide_speed: float = 260.0
@export var min_free_pauses: int = 1
@export var denial_windup: float = 0.8
@export var denial_punch_time: float = 0.35
@export var denial_wall_left_x: float = 352.0
@export var denial_wall_right_x: float = 1824.0
@export var denial_wall_inset: float = 30.0
@export var denial_slam_trauma: float = 1.5
@export var denial_cage_count: int = 3
@export var denial_cage_lanes: Array[float] = [480.0, 704.0, 928.0, 1152.0, 1376.0, 1600.0]
@export var denial_cage_spawn_y: float = 111.0
@export var denial_cage_stagger: float = 0.25
@export var denial_recover: float = 0.6
@export var hand_respawn_seconds: float = 8.0
@export var hand_emerge_y: float = 1000.0
@export var hand_emerge_side_offset: float = 120.0
@export var swipe_windup: float = 0.6
@export var swipe_time: float = 0.35
@export var swipe_recover: float = 0.5
@export var anger_shot_scene: PackedScene
@export var anger_windup: float = 1.2
@export var anger_volley_count: int = 10
@export var anger_interval: float = 0.3
@export var anger_spread_degrees: float = 90.0
@export var anger_converge_lead: float = 0.35
@export var anger_raise_offset: Vector2 = Vector2(0, -60)
@export var anger_recover: float = 0.5
@export var snuff_windup: float = 1.0
@export var snuff_seconds_two_hands: float = 4.0
@export var snuff_seconds_one_hand: float = 8.0
@export var snuff_clasp_pos: Vector2 = Vector2(0, -40)
@export var snuff_clasp_gap: float = 50.0
@export var snuff_recover: float = 0.5
@export var imps_per_snuff_min: int = 2
@export var imps_per_snuff_max: int = 3
@export var imp_respawn_interval: float = 2.5
@export var surrender_receptions: int = 4
@export var surrender_time_scale: float = 0.6
@export var surrender_reel_time: float = 0.9
@export var surrender_reel_scale: float = 0.85
@export var surrender_reel_color: Color = Color(0.35, 0.35, 0.45)
@export var surrender_hold_time: float = 0.6
@export var surrender_rise_time: float = 0.8
@export var surrender_transition_trauma: float = 2.0
@export var surrender_reject_color: Color = Color(1.0, 0.15, 0.15)
@export var surrender_reject_trauma: float = 0.25
@export var surrender_exit_time: float = 1.2
@export var surrender_beat_trees: Array[DialogTree] = [] ## One reveal beat per reception, in order. Empty or null entries are skipped.

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
var _coffin_stages: Dictionary[CollectorCoffin, GameManager.PhaseType] = {}
var _coffin_total: int = 0
var _shield_tween: Tween
var _denial_unlocked: bool = false
var _anger_unlocked: bool = false
var _bargaining_unlocked: bool = false
var _depression_unlocked: bool = false
var _coin_timer: Timer
var _live_coin: SpitCoin
var _eye_coins: Dictionary[Marker2D, Sprite2D] = {}
var _eye_pulses: Dictionary[Sprite2D, Tween] = {}
var _eye_rests: Dictionary[Marker2D, Vector2] = {}
var _attack_running: bool = false
var _attack_timer: Timer
var _free_pauses: int = 0
var _hand_rests: Dictionary[CollectorHand, Vector2] = {}
var _hand_respawn_timer: Timer
var _pending_hand: CollectorHand
var _anger_pattern_index: int = 0
var _statues: Array[DepressionStatue] = []
var _imps: Array[ShadowImp] = []
var _snuffing: bool = false
var _depression_event_active: bool = false
var _imp_timer: Timer
var _imp_target: int = 0
var _surrendering: bool = false
var _surrender_ready: bool = false
var _surrender_done: bool = false
var _receptions_left: int = 0

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
			_coffin_stages[coffin] = _coffin_identity(coffin)
			coffin.cleared.connect(_on_coffin_cleared)
			coffin.set_interactive(false)
	_coffin_total = _coffins.size()
	for hand: CollectorHand in _hands():
		_hand_rests[hand] = hand.position
		hand.hand_died.connect(_on_hand_died)
	for eye: Marker2D in _eyes():
		_eye_rests[eye] = eye.position
	_place_coffins()
	_start_shield_pulse()
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", target_scale, grow_time)
	tween.tween_callback(_finish_intro)
	_set_player_frozen.call_deferred(true)
	_setup_statues.call_deferred()

func _exit_tree() -> void:
	if _player_frozen:
		_set_player_frozen(false)
	if _surrendering:
		GameManager.set_time_scale_modifier(1.0)

func _finish_intro() -> void:
	_grown = true
	Signalbus.encounter_progress.emit(COFFIN_STAGE, STAGE_COUNT, float(_coffins.size()), float(_coffin_total))
	$CollisionShape2D.set_deferred("disabled", false)
	for coffin: CollectorCoffin in _coffins:
		coffin.set_interactive(true)
	_set_player_frozen(false)
	for hand: CollectorHand in _hands():
		hand.set_combat_enabled(true)
	_station_index = _nearest_station_index()
	_begin_next_glide()
	_setup_attack_timer()

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
	return _gliding or _attack_running

func is_bubbled() -> bool:
	return not _coffins.is_empty()

func _hands() -> Array[CollectorHand]:
	var hands: Array[CollectorHand] = []
	for child: Node in [get_node_or_null(^"HandLeft"), get_node_or_null(^"HandRight")]:
		var hand: CollectorHand = child as CollectorHand
		if hand != null:
			hands.append(hand)
	return hands

func _alive_hands() -> Array[CollectorHand]:
	var alive: Array[CollectorHand] = []
	for hand: CollectorHand in _hands():
		if hand.is_alive():
			alive.append(hand)
	return alive

func tick_movement(delta: float) -> void:
	if dying or not _grown:
		return
	if _gliding:
		_advance_glide(delta)
	elif _attack_running:
		return
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
		_free_pauses += 1
		_begin_next_glide()

func _tick_dwell(delta: float) -> void:
	var before: float = _dwell_timer
	_dwell_timer += delta
	if before < corner_dwell and _dwell_timer >= corner_dwell:
		_free_pauses += 1
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
	_place_eyes()

func _place_eyes() -> void:
	var sprite: Sprite2D = $Sprite2D
	for eye: Marker2D in _eyes():
		var rest: Vector2 = _eye_rests.get(eye, eye.position)
		var x: float = (2.0 * sprite.position.x - rest.x) if sprite.flip_h else rest.x
		eye.position = Vector2(x, rest.y)

func _on_coffin_cleared(coffin: CollectorCoffin) -> void:
	var stage: GameManager.PhaseType = _coffin_stages.get(coffin, GameManager.PhaseType.HEALTH)
	_unlock_stage(stage)
	_coffins.erase(coffin)
	_coffin_stages.erase(coffin)
	_coffin_offsets.erase(coffin)
	Signalbus.encounter_progress.emit(COFFIN_STAGE, STAGE_COUNT, float(_coffins.size()), float(_coffin_total))
	if _coffins.is_empty():
		_drop_bubble()

func _coffin_identity(coffin: CollectorCoffin) -> GameManager.PhaseType:
	for stage: GameManager.PhaseType in coffin.stages:
		if stage != GameManager.PhaseType.HEALTH:
			return stage
	return GameManager.PhaseType.HEALTH

func _unlock_stage(stage: GameManager.PhaseType) -> void:
	match stage:
		GameManager.PhaseType.DENIAL:
			_denial_unlocked = true
		GameManager.PhaseType.ANGER:
			_anger_unlocked = true
		GameManager.PhaseType.BARGAINING:
			_bargaining_unlocked = true
			_spawn_eye_coins()
			_setup_coin_timer()
		GameManager.PhaseType.DEPRESSION:
			_depression_unlocked = true

func _setup_coin_timer() -> void:
	if _coin_timer != null:
		return
	_coin_timer = Timer.new()
	_coin_timer.one_shot = true
	_coin_timer.timeout.connect(_on_coin_timer_timeout)
	add_child(_coin_timer)
	_restart_coin_timer()

func _restart_coin_timer() -> void:
	_coin_timer.start(randf_range(coin_respawn_min, coin_respawn_max))

func _on_coin_timer_timeout() -> void:
	if _halted():
		return
	if is_instance_valid(_live_coin) or _pick_filled_eye() == null \
			or GameManager.current_state == GameManager.GameState.LEVEL_CLEARED:
		_coin_timer.start(1.0)
		return
	_toss_coin()
	_restart_coin_timer()

func _spawn_eye_coins() -> void:
	for eye: Marker2D in _eyes():
		if _eye_coins.has(eye):
			continue
		var rest: Sprite2D = Sprite2D.new()
		rest.texture = GOLD_PAYLOAD.drop_texture
		rest.hframes = maxi(GOLD_PAYLOAD.drop_hframes, 1)
		rest.frame = mini(1, rest.hframes - 1)
		rest.modulate = SpitCoin.MISS_TINT
		rest.scale = Vector2.ZERO
		eye.add_child(rest)
		_eye_coins[eye] = rest
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(rest, "scale", _eye_coin_scale(eye_coin_rest_size), 0.35)
		_start_eye_pulse(rest)

func _start_eye_pulse(rest: Sprite2D) -> void:
	_stop_eye_pulse(rest)
	var pulse: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(rest, "modulate", eye_coin_pulse_color, eye_coin_pulse_period * 0.5)
	pulse.tween_property(rest, "modulate", SpitCoin.MISS_TINT, eye_coin_pulse_period * 0.5)
	_eye_pulses[rest] = pulse

func _stop_eye_pulse(rest: Sprite2D) -> void:
	var pulse: Tween = _eye_pulses.get(rest)
	if pulse != null:
		pulse.kill()
		_eye_pulses.erase(rest)
	rest.modulate = SpitCoin.MISS_TINT

func _eyes() -> Array[Marker2D]:
	var eyes: Array[Marker2D] = []
	for child: Node in [get_node_or_null(^"EyeLeft"), get_node_or_null(^"EyeRight")]:
		var eye: Marker2D = child as Marker2D
		if eye != null:
			eyes.append(eye)
	return eyes

func _eye_coin_scale(world_px: float) -> Vector2:
	var tex: Texture2D = GOLD_PAYLOAD.drop_texture
	if tex == null:
		return Vector2.ONE
	var frame_size: Vector2 = Vector2(tex.get_size().x / maxi(GOLD_PAYLOAD.drop_hframes, 1), tex.get_size().y)
	var frame_px: float = maxf(maxf(frame_size.x, frame_size.y), 1.0)
	var parent_scale: float = maxf(global_scale.x, 0.001)
	return Vector2.ONE * (world_px / frame_px / parent_scale)

func _pick_filled_eye() -> Marker2D:
	var filled: Array[Marker2D] = []
	for eye: Marker2D in _eyes():
		var rest: Sprite2D = _eye_coins.get(eye)
		if rest != null and rest.visible:
			filled.append(eye)
	if filled.is_empty():
		return null
	var choice: Marker2D = filled.pick_random()
	return choice

func _toss_coin() -> void:
	var eye: Marker2D = _pick_filled_eye()
	if eye == null:
		return
	var rest: Sprite2D = _eye_coins.get(eye)
	_stop_eye_pulse(rest)
	var grow_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	grow_tween.tween_property(rest, "scale", _eye_coin_scale(eye_coin_attack_size), coin_toss_telegraph)
	var flash_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flash_tween.tween_property(rest, "modulate", Color(2.5, 2.5, 2.5, 1.0), coin_toss_telegraph * 0.5)
	flash_tween.tween_property(rest, "modulate", SpitCoin.MISS_TINT, coin_toss_telegraph * 0.5)
	await grow_tween.finished
	if dying or not is_instance_valid(rest):
		return
	rest.visible = false
	rest.scale = _eye_coin_scale(eye_coin_rest_size)
	rest.modulate = SpitCoin.MISS_TINT
	var coin: SpitCoin = SPIT_COIN.instantiate()
	coin.payload = GOLD_PAYLOAD
	coin.hurts_on_miss = true
	coin.launch_velocity = _coin_launch_velocity(eye.global_position)
	get_parent().add_child(coin)
	coin.global_position = eye.global_position
	_live_coin = coin
	Signalbus.gold_spawned.emit(1)
	_refill_eye(eye)

func _refill_eye(eye: Marker2D) -> void:
	await get_tree().create_timer(eye_coin_refill_seconds, false).timeout
	if dying or not is_instance_valid(eye):
		return
	var rest: Sprite2D = _eye_coins.get(eye)
	if rest == null or rest.visible:
		return
	rest.visible = true
	rest.scale = Vector2.ZERO
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(rest, "scale", _eye_coin_scale(eye_coin_rest_size), 0.3)
	_start_eye_pulse(rest)

func _coin_launch_velocity(from: Vector2) -> Vector2:
	var paddle: Node2D = get_tree().get_first_node_in_group(GameManager.PADDLE) as Node2D
	var dir_sign: float = 1.0
	if paddle != null and paddle.global_position.x < from.x:
		dir_sign = -1.0
	return Vector2(randf_range(coin_speed_x_min, coin_speed_x_max) * dir_sign, randf_range(coin_arc_y_min, coin_arc_y_max))

func _setup_attack_timer() -> void:
	if _attack_timer != null:
		return
	_attack_timer = Timer.new()
	_attack_timer.one_shot = true
	_attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(_attack_timer)
	_restart_attack_timer()

func _restart_attack_timer() -> void:
	_attack_timer.start(randf_range(attack_delay_min, attack_delay_max))

func _on_attack_timer_timeout() -> void:
	if _halted():
		return
	if _attack_running or _gliding or _free_pauses < min_free_pauses \
			or GameManager.current_state == GameManager.GameState.LEVEL_CLEARED \
			or GameManager.current_state == GameManager.GameState.BALL_ON_PADDLE:
		_attack_timer.start(attack_retry_interval)
		return
	var kind: int = _roll_attack()
	if kind < 0:
		_attack_timer.start(attack_retry_interval)
		return
	_run_attack(kind)

func _roll_attack() -> int:
	if _halted():
		return -1
	var pool: Array[AttackKind] = []
	var hands_alive: bool = not _alive_hands().is_empty()
	if hands_alive:
		pool.append(AttackKind.SWIPE)
	if _denial_unlocked and hands_alive:
		pool.append(AttackKind.DENIAL)
	if _anger_unlocked and hands_alive:
		pool.append(AttackKind.ANGER)
	if _depression_unlocked and hands_alive and not _depression_event_active and _any_statue_holding_charge():
		pool.append(AttackKind.DEPRESSION)
	if pool.is_empty():
		return -1
	var choice: AttackKind = pool.pick_random()
	return choice

func _run_attack(kind: int) -> void:
	_attack_running = true
	var station: Vector2 = _attack_station(kind)
	if station.distance_to(global_position) > ATTACK_STATION_EPSILON:
		_start_glide(station, flee_speed if _retreating else attack_glide_speed)
		while _gliding:
			if _halted():
				return
			await get_tree().physics_frame
	match kind:
		AttackKind.SWIPE:
			await _attack_swipe()
		AttackKind.DENIAL:
			await _attack_denial()
		AttackKind.ANGER:
			await _attack_anger()
		AttackKind.DEPRESSION:
			await _attack_depression()
	if _halted():
		return
	_finish_attack()

func _attack_station(kind: int) -> Vector2:
	if kind == AttackKind.SWIPE:
		return global_position
	if not _retreating:
		return attack_point
	match kind:
		AttackKind.DENIAL:
			return Vector2((denial_wall_left_x + denial_wall_right_x) * 0.5, global_position.y)
		AttackKind.ANGER:
			return Vector2(global_position.x, _high_lane_y())
	return global_position

func _high_lane_y() -> float:
	var best: float = global_position.y
	for point: Vector2 in corner_points:
		best = minf(best, point.y)
	return best

func _attack_swipe() -> void:
	var hand: CollectorHand = _swipe_hand()
	if hand == null:
		return
	var paddle: Node2D = get_tree().get_first_node_in_group(GameManager.PADDLE) as Node2D
	var target_world: Vector2 = paddle.global_position if paddle != null else global_position + Vector2(0.0, 400.0)
	await hand.begin_swipe(to_local(target_world), swipe_windup, swipe_time, swipe_recover)

func _swipe_hand() -> CollectorHand:
	var paddle: Node2D = get_tree().get_first_node_in_group(GameManager.PADDLE) as Node2D
	var best: CollectorHand = null
	var best_dist: float = INF
	for hand: CollectorHand in _alive_hands():
		if paddle == null:
			return hand
		var dist: float = absf(hand.global_position.x - paddle.global_position.x)
		if dist < best_dist:
			best_dist = dist
			best = hand
	return best

func _on_hand_died(hand: CollectorHand) -> void:
	var other: CollectorHand = _other_hand(hand)
	if other != null and other.is_dead():
		if _hand_respawn_timer != null:
			_hand_respawn_timer.stop()
		if _pending_hand == other:
			_pending_hand = null
		_respawn_hand(other)
	_pending_hand = hand
	_start_hand_respawn_timer()

func _other_hand(hand: CollectorHand) -> CollectorHand:
	for other: CollectorHand in _hands():
		if other != hand:
			return other
	return null

func _start_hand_respawn_timer() -> void:
	if _hand_respawn_timer == null:
		_hand_respawn_timer = Timer.new()
		_hand_respawn_timer.one_shot = true
		_hand_respawn_timer.timeout.connect(_on_hand_respawn_timeout)
		add_child(_hand_respawn_timer)
	_hand_respawn_timer.start(hand_respawn_seconds)

func _on_hand_respawn_timeout() -> void:
	if dying or _pending_hand == null:
		return
	if _pending_hand.is_dead():
		_respawn_hand(_pending_hand)
	_pending_hand = null

func _respawn_hand(hand: CollectorHand) -> void:
	var rest_local: Vector2 = _hand_rests.get(hand, hand.position)
	var emerge_world: Vector2 = Vector2(global_position.x + signf(rest_local.x) * hand_emerge_side_offset, hand_emerge_y)
	hand.position = to_local(emerge_world)
	hand.begin_emerge(rest_local)

func _finish_attack() -> void:
	_attack_running = false
	if _surrendering:
		return
	_free_pauses = 0
	_restart_attack_timer()
	if _retreating:
		_flee()
	else:
		_pause_timer = station_pause
		_dwell_timer = 0.0

func _attack_denial() -> void:
	await _pulse_telegraph(denial_windup)
	if _halted():
		return
	await _punch_walls()
	if _halted():
		return
	await _drop_cages()
	if _halted():
		return
	await _return_hands()

func _pulse_telegraph(duration: float) -> void:
	var sprite: Sprite2D = $Sprite2D
	var base_scale: Vector2 = sprite.scale
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i: int in 2:
		tween.tween_property(sprite, "scale", base_scale * 1.12, duration * 0.25)
		tween.tween_property(sprite, "scale", base_scale, duration * 0.25)
	await tween.finished

func _punch_walls() -> void:
	var hands: Array[CollectorHand] = _alive_hands()
	if hands.is_empty():
		return
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	for hand: CollectorHand in hands:
		hand.set_idle_enabled(false)
		hand.set_fist(true)
		var rest_local: Vector2 = _hand_rests.get(hand, hand.position)
		var wall_x: float = denial_wall_left_x + denial_wall_inset if rest_local.x < 0.0 else denial_wall_right_x - denial_wall_inset
		tween.tween_property(hand, "position", to_local(Vector2(wall_x, global_position.y)), denial_punch_time)
	await tween.finished
	SFX.play_sound("cage_hit")
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		@warning_ignore("unsafe_method_access")
		camera.add_trauma(denial_slam_trauma)

func _drop_cages() -> void:
	var lanes: Array[float] = denial_cage_lanes.duplicate()
	lanes.shuffle()
	var count: int = mini(denial_cage_count, lanes.size())
	for i: int in count:
		if _halted():
			return
		var cage: DarkCage = DARK_CAGE.instantiate()
		cage.add_collision_exception_with(self)
		get_parent().add_child(cage)
		cage.global_position = Vector2(lanes[i], denial_cage_spawn_y)
		await get_tree().create_timer(denial_cage_stagger, false).timeout

func _attack_anger() -> void:
	await _raise_hands()
	if _halted():
		return
	await _fire_anger_volley()
	if _halted():
		return
	await _lower_hands()

func _raise_hands() -> void:
	var hands: Array[CollectorHand] = _alive_hands()
	if hands.is_empty():
		return
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for hand: CollectorHand in hands:
		hand.set_idle_enabled(false)
		hand.set_mouth_open(true)
		var rest_local: Vector2 = _hand_rests.get(hand, hand.position)
		tween.tween_property(hand, "position", rest_local + anger_raise_offset, anger_windup)
	await tween.finished

func _fire_anger_volley() -> void:
	var pattern: int = _anger_pattern_index % AngerPattern.size()
	_anger_pattern_index += 1
	var hand_toggle: int = 0
	for i: int in anger_volley_count:
		if _halted():
			return
		var hands: Array[CollectorHand] = _alive_hands()
		if hands.is_empty():
			return
		var hand: CollectorHand = hands[hand_toggle % hands.size()]
		hand_toggle += 1
		_fire_anger_shot(hand, i, pattern)
		await get_tree().create_timer(anger_interval, false).timeout

func _fire_anger_shot(hand: CollectorHand, index: int, pattern: int) -> void:
	if anger_shot_scene == null:
		return
	var shot: RageShot = anger_shot_scene.instantiate() as RageShot
	if shot == null:
		return
	shot.add_collision_exception_with(self)
	shot.direction = _anger_shot_direction(hand, index, pattern)
	get_parent().add_child(shot)
	shot.global_position = hand.get_muzzle_position()

func _anger_shot_direction(hand: CollectorHand, index: int, pattern: int) -> Vector2:
	var half_spread: float = deg_to_rad(anger_spread_degrees) * 0.5
	match pattern:
		AngerPattern.CROSSFIRE:
			var t: float = float(index) / float(maxi(anger_volley_count - 1, 1))
			var inward: float = -half_spread if hand.global_position.x > global_position.x else half_spread
			return Vector2.DOWN.rotated(lerpf(inward * 0.2, inward, t))
		AngerPattern.RAIN:
			return Vector2.DOWN.rotated(randf_range(-half_spread, half_spread))
		AngerPattern.CONVERGE:
			var paddle: Node2D = get_tree().get_first_node_in_group(GameManager.PADDLE) as Node2D
			if paddle == null:
				return Vector2.DOWN
			var lead: Vector2 = Vector2.ZERO
			var body: CharacterBody2D = paddle as CharacterBody2D
			if body != null:
				lead = body.velocity * anger_converge_lead
			var aim: Vector2 = (paddle.global_position + lead - hand.get_muzzle_position()).normalized()
			return aim.rotated(deg_to_rad(randf_range(-4.0, 4.0)))
	return Vector2.DOWN

func _lower_hands() -> void:
	var hands: Array[CollectorHand] = _alive_hands()
	for hand: CollectorHand in hands:
		hand.set_mouth_open(false)
	if hands.is_empty():
		return
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for hand: CollectorHand in hands:
		var rest_local: Vector2 = _hand_rests.get(hand, hand.position)
		tween.tween_property(hand, "position", rest_local, anger_recover)
	await tween.finished
	for hand: CollectorHand in hands:
		hand.set_idle_enabled(true)

func _setup_statues() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"depression_statue"):
		var statue: DepressionStatue = node as DepressionStatue
		if statue == null:
			continue
		_statues.append(statue)
		statue.visible = true
		statue.process_mode = Node.PROCESS_MODE_INHERIT
		statue.force_charged(false, false)
		statue.charge_changed.connect(_on_statue_charge_changed)

func _any_statue_holding_charge() -> bool:
	for statue: DepressionStatue in _statues:
		if is_instance_valid(statue) and statue.charge > 0.0:
			return true
	return false

func _all_statues_charged() -> bool:
	if _statues.is_empty():
		return false
	for statue: DepressionStatue in _statues:
		if is_instance_valid(statue) and not statue.is_charged():
			return false
	return true

func _attack_depression() -> void:
	await _clasp_hands()
	if _halted():
		return
	await _channel_snuff()
	if _halted():
		return
	await _unclasp_hands()

func _clasp_hands() -> void:
	var hands: Array[CollectorHand] = _alive_hands()
	if hands.is_empty():
		return
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for hand: CollectorHand in hands:
		hand.set_idle_enabled(false)
		hand.set_channeling(true)
		var rest_local: Vector2 = _hand_rests.get(hand, hand.position)
		var side: float = -1.0 if rest_local.x < 0.0 else 1.0
		var target: Vector2 = snuff_clasp_pos + Vector2(side * snuff_clasp_gap * 0.5, 0.0)
		tween.tween_property(hand, "position", target, snuff_windup)
	await tween.finished

func _channel_snuff() -> void:
	_snuffing = true
	var elapsed: float = 0.0
	var completed: bool = false
	while true:
		if _halted():
			return
		if GameManager.current_state == GameManager.GameState.BALL_ON_PADDLE:
			await get_tree().physics_frame
			continue
		var working: int = _working_hand_count()
		if working <= 0:
			break
		var delta: float = get_physics_process_delta_time()
		var duration: float = snuff_seconds_two_hands if working >= 2 else snuff_seconds_one_hand
		var any_left: bool = false
		for statue: DepressionStatue in _statues:
			if not is_instance_valid(statue):
				continue
			statue.drain(statue.charge_seconds / duration * delta)
			if statue.charge > 0.0:
				any_left = true
		elapsed += delta
		_tremble_hands(elapsed)
		if not any_left:
			_complete_snuff()
			completed = true
			break
		await get_tree().physics_frame
	_snuffing = false
	if not completed:
		_restore_statues()

func _restore_statues() -> void:
	for statue: DepressionStatue in _statues:
		if is_instance_valid(statue) and not statue.is_charged():
			statue.force_charged(false, false)

func _working_hand_count() -> int:
	var count: int = 0
	for hand: CollectorHand in _hands():
		if hand.is_working():
			count += 1
	return count

func _tremble_hands(elapsed: float) -> void:
	for hand: CollectorHand in _alive_hands():
		hand.rotation = sin(elapsed * 28.0) * 0.05

func _complete_snuff() -> void:
	_depression_event_active = true
	var driver: DarknessDriver = get_tree().get_first_node_in_group(&"darkness_driver") as DarknessDriver
	if driver != null:
		driver.fade_dark()
	_imp_target = randi_range(imps_per_snuff_min, imps_per_snuff_max)
	_spawn_imps_to_target()
	_start_imp_timer()

func _unclasp_hands() -> void:
	var hands: Array[CollectorHand] = _alive_hands()
	for hand: CollectorHand in _hands():
		hand.set_channeling(false)
		hand.rotation = 0.0
	if hands.is_empty():
		return
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for hand: CollectorHand in hands:
		var rest_local: Vector2 = _hand_rests.get(hand, hand.position)
		tween.tween_property(hand, "position", rest_local, snuff_recover)
	await tween.finished
	for hand: CollectorHand in hands:
		hand.set_idle_enabled(true)

func _spawn_imps_to_target() -> void:
	_prune_imps()
	while _imps.size() < _imp_target:
		var imp: ShadowImp = SHADOW_IMP.instantiate()
		get_parent().add_child(imp)
		imp.global_position = Vector2(randf_range(600.0, 1500.0), 200.0)
		_imps.append(imp)

func _start_imp_timer() -> void:
	if _imp_timer == null:
		_imp_timer = Timer.new()
		_imp_timer.one_shot = true
		_imp_timer.timeout.connect(_on_imp_timer_timeout)
		add_child(_imp_timer)
	_imp_timer.start(imp_respawn_interval)

func _on_imp_timer_timeout() -> void:
	if dying or not _depression_event_active:
		return
	_prune_imps()
	if _imps.size() < _imp_target:
		var imp: ShadowImp = SHADOW_IMP.instantiate()
		get_parent().add_child(imp)
		imp.global_position = Vector2(randf_range(600.0, 1500.0), 200.0)
		_imps.append(imp)
	_imp_timer.start(imp_respawn_interval)

func _prune_imps() -> void:
	for i: int in range(_imps.size() - 1, -1, -1):
		if not is_instance_valid(_imps[i]):
			_imps.remove_at(i)

func _on_statue_charge_changed() -> void:
	if not _depression_event_active or not _all_statues_charged():
		return
	_end_depression_event()

func _end_depression_event() -> void:
	_depression_event_active = false
	if _imp_timer != null:
		_imp_timer.stop()
	var driver: DarknessDriver = get_tree().get_first_node_in_group(&"darkness_driver") as DarknessDriver
	if driver != null:
		driver.fade_light()
	_despawn_imps()

func _despawn_imps() -> void:
	_prune_imps()
	var imps: Array[ShadowImp] = _imps.duplicate()
	_imps.clear()
	for imp: ShadowImp in imps:
		if not is_instance_valid(imp):
			continue
		imp.die()
		await get_tree().create_timer(0.12, false).timeout

func _return_hands() -> void:
	var hands: Array[CollectorHand] = _alive_hands()
	if hands.is_empty():
		return
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for hand: CollectorHand in hands:
		var rest_local: Vector2 = _hand_rests.get(hand, hand.position)
		tween.tween_property(hand, "position", rest_local, denial_recover)
	await tween.finished
	for hand: CollectorHand in hands:
		hand.set_fist(false)
		hand.set_idle_enabled(true)

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
	if not _attack_running:
		_flee()

func accept_damage(damage: float, dmg_type: Array[GameManager.PhaseType]) -> void:
	if dying or not _grown:
		return
	if not dmg_type.has(GameManager.PhaseType.HEALTH):
		return
	if _surrendering:
		_reject_hit()
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
		_begin_surrender()

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

func is_surrendering() -> bool:
	return _surrendering

func _halted() -> bool:
	return dying or _surrendering

func _begin_surrender() -> void:
	if _surrendering:
		return
	_surrendering = true
	health = 0.0
	_receptions_left = maxi(surrender_receptions, 1)
	add_to_group(GameManager.SURRENDER)
	_stop_stage_one_systems()
	_set_player_frozen(true)
	await _play_surrender_transition()
	if not is_inside_tree():
		return
	GameManager.set_time_scale_modifier(surrender_time_scale)
	_emit_surrender_progress()
	_retreating = false
	_station_index = _nearest_station_index()
	_begin_next_glide()
	_set_player_frozen(false)
	_surrender_ready = true

func _stop_stage_one_systems() -> void:
	_attack_running = false
	_gliding = false
	_orbit_rate = 0.0
	if _attack_timer != null:
		_attack_timer.stop()
	if _coin_timer != null:
		_coin_timer.stop()
	if _hand_respawn_timer != null:
		_hand_respawn_timer.stop()
	if _depression_event_active:
		_end_depression_event()
	_restore_statues()
	if is_instance_valid(_live_coin):
		_live_coin.queue_free()
	for eye: Marker2D in _eyes():
		var rest: Sprite2D = _eye_coins.get(eye)
		if rest != null:
			_stop_eye_pulse(rest)
			rest.visible = false
	for hand: CollectorHand in _hands():
		hand.set_combat_enabled(false)
		hand.set_channeling(false)
		hand.set_fist(false)
		hand.set_mouth_open(false)
		hand.rotation = 0.0
		if hand.is_alive():
			hand.position = _hand_rests.get(hand, hand.position)
			hand.set_idle_enabled(true)
	_clear_stage_one_threats()

func _clear_stage_one_threats() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	for child: Node in parent.get_children():
		if child == self or child.is_queued_for_deletion():
			continue
		if child is DarkCage or child is RageShot or child is ShadowImp:
			child.queue_free()
			continue
		var coin: SpitCoin = child as SpitCoin
		if coin != null and coin.hurts_on_miss:
			coin.queue_free()

func _play_surrender_transition() -> void:
	var sprite: Sprite2D = $Sprite2D
	if _shield_tween != null:
		_shield_tween.kill()
		_shield_tween = null
	SFX.play_sound("deon_die")
	_flash_hit()
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		@warning_ignore("unsafe_method_access")
		camera.add_trauma(surrender_transition_trauma)
	var full_scale: Vector2 = sprite.scale
	var reel: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	reel.tween_property(sprite, "scale", full_scale * surrender_reel_scale, surrender_reel_time)
	reel.tween_property(sprite, "modulate", surrender_reel_color, surrender_reel_time)
	await reel.finished
	await get_tree().create_timer(surrender_hold_time, false).timeout
	if not is_inside_tree():
		return
	SFX.play_sound("boss_fight_start")
	Signalbus.screen_flash.emit(Color.GOLD)
	var rise: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_property(sprite, "scale", full_scale, surrender_rise_time)
	rise.tween_property(sprite, "modulate", Color.WHITE, surrender_rise_time)
	await rise.finished

func _emit_surrender_progress() -> void:
	Signalbus.encounter_progress.emit(1, 1, float(maxi(_receptions_left, 0)), float(maxi(surrender_receptions, 1)))

func receive_ball() -> void:
	if not _surrender_ready or _surrender_done:
		return
	_receptions_left -= 1
	_emit_surrender_progress()
	if _receptions_left <= 0:
		_complete_surrender()
		return
	Signalbus.screen_flash.emit(Color.GOLD)
	SFX.play_sound("win_sting")
	var paddle: Node = get_tree().get_first_node_in_group(GameManager.PADDLE)
	if paddle != null and paddle.has_method("soft_catch_flash"):
		@warning_ignore("unsafe_method_access")
		paddle.soft_catch_flash()
	_play_surrender_beat(maxi(surrender_receptions, 1) - _receptions_left - 1)

func _play_surrender_beat(index: int) -> void:
	if index < 0 or index >= surrender_beat_trees.size():
		return
	var tree: DialogTree = surrender_beat_trees[index]
	if tree == null or tree.beats.is_empty():
		return
	var player: MemoryCodecPlayer = CODEC_PLAYER.instantiate()
	player.memory_tree = tree
	add_child(player)
	await player.play()
	if is_instance_valid(player):
		player.queue_free()

func _complete_surrender() -> void:
	if _surrender_done:
		return
	_surrender_done = true
	dying = true
	remove_from_group(GameManager.SURRENDER)
	GameManager.set_time_scale_modifier(1.0)
	var fade: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade.tween_property(self, "modulate:a", 0.0, surrender_exit_time)
	await fade.finished
	if not is_inside_tree():
		return
	queue_free()
	Signalbus.boss_defeated.emit()

func _reject_hit() -> void:
	SFX.play_sound("enemy_hurt")
	_flash_reject()
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		@warning_ignore("unsafe_method_access")
		camera.add_trauma(surrender_reject_trauma)

func _flash_reject() -> void:
	var mat: ShaderMaterial = $Sprite2D.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_color", Vector3(surrender_reject_color.r, surrender_reject_color.g, surrender_reject_color.b))
	mat.set_shader_parameter("flash_amount", 1.0)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("flash_amount", v),
		1.0, 0.0, 0.18
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
