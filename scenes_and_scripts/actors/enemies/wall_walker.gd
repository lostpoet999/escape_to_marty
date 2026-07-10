class_name WallWalker
extends PlacedEnemy

enum WallSide { LEFT, RIGHT, TOP }

@export var wall_side: WallSide ## Which wall this walker clings to; sets the emerge axis and the escape direction.
@export var emerge_time: float ## Seconds for the sprite to grow out of the wall on spawn; the physics body never scales.
@export var escape_time: float ## Seconds of active play before the walker flees; the timer only counts down during PLAYING.
@export var escape_run_speed: float ## Seconds to sprint offscreen once the escape timer expires.

@onready var _escape_bar: ProgressBar = get_node_or_null("EscapeIndicator")
var _escape_timer: Timer
var _escaping: bool = false
var _blink_t: float = 0.0

func _ready() -> void:
	super()
	modulate = Color.WHITE
	modulate.a = 1.0
	timer.stop()
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

func die() -> void:
	if is_queued_for_deletion(): return
	ready_to_remove.emit(self)
	_on_death(denial_health <= -1)
	@warning_ignore("unsafe_method_access")
	get_viewport().get_camera_2d().add_trauma(0.5)
	SFX.play_sound("enemy_hurt")
	queue_free()

## Virtual death hook. killed_by_damage == (denial_health <= -1): true means the ball
## killed it (accept_damage drove health negative), false means the level_cleared sweep.
## Subclasses (MoneyThiefSpider) override to burst the hoard only on a damage kill.
func _on_death(_killed_by_damage: bool) -> void:
	pass

## Extends the escape countdown, clamped to the original escape_time. MoneyThiefSpider
## calls this on a steal so the player gets a window to reclaim the lost gold.
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

## Virtual hook fired when the escape run begins. MoneyThiefSpider releases captured
## gold and disables its steal zone here in a later phase.
func _on_escape_started() -> void:
	pass

func start_action_timer() -> void:
	if _escaping: return
	super()

func stun_for_time(duration: float) -> void:
	if _escaping: return
	super(duration)
