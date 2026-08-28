class_name CollectorCoffin
extends BaseSeal

signal cleared(coffin: CollectorCoffin)

@export var bargain_deals_required: int = 1
@export var deal_price_min: int = 35
@export var deal_price_max: int = 55
@export var stage_health_min: int = 0
@export var stage_health_max: int = 0
@export var art_rotation_degrees: float = 0.0
@export var sway_degrees: float = 4.0
@export var sway_period: float = 2.2
@export var health_hit_cooldown: float = 0.25

var _deals_settled: int = 0
var _sway_tween: Tween
var _last_health_hit_ms: int = -10000
var _interactive: bool = true

func _ready() -> void:
	super()
	for sprite: Sprite2D in _juice_sprites:
		sprite.rotation_degrees = art_rotation_degrees
	_start_sway()
	if stage_health_max > 0 and current_stage != GameManager.PhaseType.HEALTH:
		_roll_stage_health()
	if current_stage == GameManager.PhaseType.BARGAINING and bargain_deals_required > 1:
		_roll_deal_price()

func _roll_stage_health() -> void:
	var rolled: float = float(randi_range(stage_health_min, stage_health_max))
	stages[current_stage] = rolled
	health_temp = rolled
	health_max = rolled
	if current_stage == GameManager.PhaseType.DEPRESSION:
		_depression_max = rolled
	_update_damage_cracks()
	_update_stage_label()

func set_interactive(enabled: bool) -> void:
	_interactive = enabled
	$CollisionShape2D.set_deferred("disabled", not enabled)

func responding_gestures(revert_window_seconds: float) -> Array[GameManager.PhaseType]:
	if not _interactive:
		return [] as Array[GameManager.PhaseType]
	return super(revert_window_seconds)

func accept_damage(damage: float, damage_types: Array, score_mult: float = 1.0, via_click: bool = false) -> void:
	if damage_types.has(GameManager.PhaseType.HEALTH):
		var now: int = Time.get_ticks_msec()
		if now - _last_health_hit_ms < int(health_hit_cooldown * 1000.0):
			return
		_last_health_hit_ms = now
	super(damage, damage_types, score_mult, via_click)

func _process(delta: float) -> void:
	if current_stage == GameManager.PhaseType.DEPRESSION and not _regen_allowed():
		return
	super(delta)

func _regen_allowed() -> bool:
	var collector: Collector = get_parent() as Collector
	if collector != null and collector.is_moving():
		return false
	var gestures: MouseGestures = get_tree().get_first_node_in_group(&"mouse_gestures") as MouseGestures
	if gestures != null and gestures.live_light_count() > 0:
		return false
	return true

func _start_sway() -> void:
	if sway_degrees <= 0.0:
		return
	var period: float = sway_period * randf_range(0.85, 1.15)
	_sway_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sway_tween.tween_method(_set_sway, -sway_degrees, sway_degrees, period * 0.5)
	_sway_tween.tween_method(_set_sway, sway_degrees, -sway_degrees, period * 0.5)
	_sway_tween.custom_step(randf() * period)

func _set_sway(value: float) -> void:
	for sprite: Sprite2D in _juice_sprites:
		sprite.rotation_degrees = art_rotation_degrees + value

func _damage_current_stage(damage: float, score_mult: float = 1.0, via_click: bool = false) -> void:
	if current_stage == GameManager.PhaseType.HEALTH and health_temp - damage <= 0.0:
		dying = true
		if _sway_tween != null:
			_sway_tween.kill()
		_score_stage_damage(damage, score_mult)
		_grant_phase_score(score_mult, via_click)
		PlayerData.update_player_score(PlayerData.SCORE_SEAL_DESTROYED, score_mult)
		var fx: Node2D = brick_destroy_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		_spawn_damage_number(damage)
		cleared.emit(self)
		queue_free()
		return
	super(damage, score_mult, via_click)

func _settle_deal(cost: int, allow_damage: bool = true) -> void:
	if current_stage == GameManager.PhaseType.BARGAINING and _deals_settled + 1 < bargain_deals_required:
		PlayerData.pay_bargain_cost(cost, allow_damage)
		_grant_phase_score(1.0, true)
		var fx: Node2D = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		_deals_settled += 1
		_roll_deal_price()
		return
	super(cost, allow_damage)

func _roll_deal_price() -> void:
	bargain_markup = 0
	health_temp = float(randi_range(deal_price_min, deal_price_max))
	health_max = health_temp
	stages[GameManager.PhaseType.BARGAINING] = health_temp
	_update_damage_cracks()
	_update_stage_label()
