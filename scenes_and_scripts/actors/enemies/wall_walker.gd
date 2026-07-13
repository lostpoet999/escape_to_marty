class_name WallWalker
extends PlacedEnemy

enum WallSide { LEFT, RIGHT, TOP }

const WALL_TILE_SIZE: float = 64.0
const SHOCK_COOLDOWN_MS: int = 100

@export var wall_side: WallSide ## Which wall this walker clings to; sets the emerge axis and the escape direction.
@export var emerge_time: float ## Seconds for the sprite to grow out of the wall on spawn; the physics body never scales.
@export var escape_time: float ## Seconds of active play before the walker flees; the timer only counts down during PLAYING.
@export var escape_run_speed: float ## Seconds to sprint offscreen once the escape timer expires.
@export var wall_shock_bricks: int = 3 ## A ball bounce or HEALTH-damage projectile hit on this walker's wall within this many tiles to either side counts as a hit on the walker; the tiles between the impact and the walker shake. 0 disables the shockwave.
@export var max_health: float = 3.0 ## Real HP pool: HEALTH-type damage subtracts its actual amount. Replaces the base class's one-per-hit denial_health counting for wall walkers.

@onready var _escape_bar: ProgressBar = get_node_or_null("EscapeIndicator")
var _escape_timer: Timer
var _escaping: bool = false
var _blink_t: float = 0.0
var _last_shock_ms: int = -SHOCK_COOLDOWN_MS
var health: float

func _ready() -> void:
	health = max_health
	add_to_group(&"wall_walkers")
	super()
	modulate = Color.WHITE
	modulate.a = 1.0
	timer.stop()
	Signalbus.wall_hit.connect(_on_wall_hit)
	_setup_escape()
	_play_emerge()

func _setup_escape() -> void:
	_escape_timer = Timer.new()
	_escape_timer.one_shot = true
	_escape_timer.wait_time = escape_time
	_escape_timer.timeout.connect(_on_escape_timeout)
	add_child(_escape_timer)
	_escape_timer.start()
	_escape_timer.paused = true
	if _escape_bar != null:
		_escape_bar.max_value = escape_time
		_escape_bar.value = escape_time

func _process(delta: float) -> void:
	if _escaping or _escape_timer == null:
		return
	_escape_timer.paused = GameManager.current_state != GameManager.GameState.PLAYING
	if _escape_bar != null:
		_escape_bar.value = _escape_timer.time_left
		_update_blink(delta)

func _update_blink(delta: float) -> void:
	if _escape_timer.time_left < 3.0:
		_blink_t += delta
		_escape_bar.modulate.a = 0.5 + 0.5 * sin(_blink_t * 12.0)
	else:
		_escape_bar.modulate.a = 1.0

func _play_emerge() -> void:
	var sprite: Node2D = get_node_or_null("EnemySprite")
	if sprite == null:
		start_action_timer()
		return
	var full_scale: Vector2 = sprite.scale
	var start_scale: Vector2 = full_scale
	var out_dir: Vector2
	match wall_side:
		WallSide.TOP: out_dir = Vector2.DOWN
		WallSide.LEFT: out_dir = Vector2.RIGHT
		_: out_dir = Vector2.LEFT
	var local_out: Vector2 = out_dir.rotated(-sprite.rotation)
	if absf(local_out.x) >= absf(local_out.y):
		start_scale.x = 0.0
	else:
		start_scale.y = 0.0
	sprite.scale = start_scale
	var emerge_tween: Tween = create_tween()
	emerge_tween.tween_property(sprite, "scale", full_scale, emerge_time)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	emerge_tween.tween_callback(start_action_timer)

func accept_damage(damage: float, dmg_type: Array[GameManager.PhaseType]) -> void:
	if not dmg_type.has(GameManager.PhaseType.HEALTH):
		return
	SFX.play_sound("enemy_hurt")
	show_damage_number(roundi(damage))
	health -= damage
	if health <= 0.0:
		die()

func _on_wall_hit(_source: Node2D, wall: Node2D, damage: float, dmg_types: Array) -> void:
	if wall_shock_bricks <= 0 or is_queued_for_deletion():
		return
	if not GameManager.PhaseType.HEALTH in dmg_types:
		return
	if Time.get_ticks_msec() - _last_shock_ms < SHOCK_COOLDOWN_MS:
		return
	var along: int = Vector2.AXIS_X if wall_side == WallSide.TOP else Vector2.AXIS_Y
	var perp: int = Vector2.AXIS_Y if wall_side == WallSide.TOP else Vector2.AXIS_X
	if absf(wall.global_position[perp] - global_position[perp]) > WALL_TILE_SIZE:
		return
	if absf(wall.global_position[along] - global_position[along]) > (float(wall_shock_bricks) + 0.5) * WALL_TILE_SIZE:
		return
	_last_shock_ms = Time.get_ticks_msec()
	_shake_wall_run(wall, along, perp)
	var typed_types: Array[GameManager.PhaseType] = []
	for dmg_type: GameManager.PhaseType in dmg_types:
		typed_types.append(dmg_type)
	accept_damage(damage, typed_types)

func _shake_wall_run(hit_wall: Node2D, along: int, perp: int) -> void:
	var lo: float = minf(hit_wall.global_position[along], global_position[along]) - WALL_TILE_SIZE * 0.5
	var hi: float = maxf(hit_wall.global_position[along], global_position[along]) + WALL_TILE_SIZE * 0.5
	for tile_node: Node in get_tree().get_nodes_in_group("walls"):
		var tile: Node2D = tile_node as Node2D
		if tile == null or absf(tile.global_position[perp] - hit_wall.global_position[perp]) > WALL_TILE_SIZE * 0.5:
			continue
		if tile.global_position[along] < lo or tile.global_position[along] > hi:
			continue
		var delay: float = absf(tile.global_position[along] - hit_wall.global_position[along]) / WALL_TILE_SIZE * 0.04
		TileShake.shake(tile, delay)

func die() -> void:
	if is_queued_for_deletion(): return
	ready_to_remove.emit(self)
	_on_death(health <= 0.0)
	@warning_ignore("unsafe_method_access")
	get_viewport().get_camera_2d().add_trauma(0.5)
	SFX.play_sound("enemy_hurt")
	queue_free()
	Signalbus.wall_walker_removed.emit(self)

func _on_death(_killed_by_damage: bool) -> void:
	pass

func holds_player_gold() -> bool:
	return false

func add_escape_time(seconds: float) -> void:
	if _escaping or _escape_timer == null:
		return
	_escape_timer.start(minf(escape_time, _escape_timer.time_left + seconds))

func _on_escape_timeout() -> void:
	if is_queued_for_deletion(): return
	if GameManager.current_state == GameManager.GameState.LEVEL_CLEARED: return
	_escaping = true
	timer.stop()
	if current_action != null:
		current_action.cancel_to_origin(self)
	if _escape_bar != null:
		_escape_bar.visible = false
	_on_escape_started()
	var flee_tween: Tween = create_tween()
	match wall_side:
		WallSide.TOP:
			flee_tween.tween_property(self, "global_position:x", 2200.0, escape_run_speed)\
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		_:
			flee_tween.tween_property(self, "global_position:y", -300.0, escape_run_speed)\
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	flee_tween.tween_callback(_finish_escape)

func _finish_escape() -> void:
	ready_to_remove.emit(self)
	queue_free()
	Signalbus.wall_walker_removed.emit(self)

func _on_escape_started() -> void:
	pass

func start_action_timer() -> void:
	if _escaping: return
	super()

func stun_for_time(duration: float) -> void:
	if _escaping: return
	super(duration)
