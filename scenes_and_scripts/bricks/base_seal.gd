class_name BaseSeal
extends Area2D

const BONUS_DROP: PackedScene = preload("res://scenes_and_scripts/collectibles/bonus_drop.tscn")
const BONUS_POOL: BonusDropPool = preload("res://scenes_and_scripts/collectibles/bonus_drops/bonus_drop_pool.tres")
const DAMAGE_NUMBER: PackedScene = preload(DamageNumber.PREFAB_SCENE)

const BARGAIN_EARLY_SOUND: String = "bargain_early"
const BARGAIN_OVERSHOT_SOUND: String = "bargain_overshot"
const DEPRESSION_REVERT_SOUND: String = "depression_revert"

const COIN_WINDFALL_CHANCE: float = 0.05
const COIN_WINDFALL_COUNT: int = 3
const COIN_WINDFALL_SCATTER: float = 14.0


const PHASE_SCORES: Dictionary[GameManager.PhaseType, int] = {
	GameManager.PhaseType.DENIAL: 100,
	GameManager.PhaseType.ANGER: 150,
	GameManager.PhaseType.BARGAINING: 200,
	GameManager.PhaseType.DEPRESSION: 250,
	GameManager.PhaseType.ACCEPTANCE: 300,
	GameManager.PhaseType.HEALTH: 500,
}

enum BargainOutcome { OVERPAY = 0, DEAL = 1, WHIFF = 2, INSULT = 3 }

@onready var brick_health_label: Label = $brick_health

@onready var damage_cracks_1: Sprite2D = $"damage_cracks_1"
@onready var damage_cracks_2: Sprite2D = $"damage_cracks_2"
@onready var damage_cracks_3: Sprite2D = $"damage_cracks_3"
@onready var gemstone_facets: Sprite2D = $"gemstone-facets"

@export var initialize_brick_on_leveldata: bool = true
@export var stages: Dictionary[GameManager.PhaseType, float]
var current_stage: GameManager.PhaseType
var dying: bool = false
var _feedback_pending: bool = false
var _feedback_damaged: bool = false
	
@export var brick_health: int = 1 # default starting health
var health_temp: float # current health
var health_max: float # max health for this stage
var _denial_revert_max: float = 0.0
var _denial_revert_armed_at_ms: int = -1

@export var brick_damage_fx: PackedScene
@export var brick_destroy_fx: PackedScene

# handy for randomized levels: set to less than 100%
@export var chance_it_exists: int = 100

@export_category("Bargain")
@export var bargain_sweet_spot: float = 0.5
@export var bargain_sweet_spot_width: float = 0.128
@export var bargain_discount: float = 0.0
@export var bargain_undercut_chance_near: float = 0.5
@export var bargain_undercut_chance_mid: float = 0.2
@export var bargain_undercut_chance_far: float = 0.1
## Gold paid to the player on a sweet-spot DEAL (the deal itself costs nothing).
@export var bargain_deal_reward: int = 1

var bargain_markup: int = 0
var bargain_sweet_spot_bonus: float = 0.0
var bargain_discount_bonus: float = 0.0

@export_category("Juice")
## Pixels the sprites lurch in the hit direction on a ball strike before settling back (0 disables). Sprites only — collision stays put.
@export var knockback_distance: float = 6.0
## Peak brightness of the idle glow breathe (1.0 disables). Rides on the gemstone's self_modulate, so the phase color set by setup_visuals is untouched.
@export var glow_strength: float = 1.25
## Seconds per full glow breath. Each seal randomizes this ±15% and starts at a random phase so the board never syncs up.
@export var glow_period: float = 2.4
var _juice_sprites: Array[Sprite2D] = []
var _knockback_tween: Tween
var _glow_tween: Tween
var _visual_offset: Vector2 = Vector2.ZERO

@export_category("Depression")
## Phase-HP per second the exposed DEPRESSION phase regrows while it sits unlit. Snuffing a light lets cleared progress melt back into the dark.
@export var depression_regen_rate: float = 0.6
## When true, a seal whose DEPRESSION was fully cleared slides BACK into depression if left dark too long (the snuff-trap). Off until the light-snuff enemy exists; flip on per-seal to feel it.
@export var depression_reseeds_when_dark: bool = false
## Seconds a cleared seal must stay unlit before DEPRESSION reseeds (only when depression_reseeds_when_dark).
@export var depression_reseed_delay: float = 4.32
const _LIT_GRACE: float = 0.12
var _lit_cooldown: float = 0.0
var _depression_max: float = 0.0
var _had_depression: bool = false
var _reseed_timer: float = 0.0
var _interrupted_stage: GameManager.PhaseType = GameManager.PhaseType.HEALTH
var _interrupted_hp: float = 0.0
var _interrupted_max: float = 0.0
var _has_interrupted_stage: bool = false

func pick_random_stage() -> void:
	if stages.is_empty():
		current_stage = GameManager.PhaseType.HEALTH
		health_temp = brick_health
		health_max = health_temp
		_update_damage_cracks()
		setup_visuals()
		return
	
	var non_health_stages: Array = stages.keys().filter(func(k:GameManager.PhaseType)->bool: return k != GameManager.PhaseType.HEALTH)
	
	if non_health_stages.is_empty():
		current_stage = GameManager.PhaseType.HEALTH
	else:
		current_stage = non_health_stages.pick_random()
	
	health_temp = stages[current_stage]
	health_max = health_temp
	_update_damage_cracks()
	setup_visuals()

func setup_visuals()->void:
	match current_stage:
		GameManager.PhaseType.DENIAL:
			gemstone_facets.modulate = Color("a23e8c")
		GameManager.PhaseType.ANGER:
			gemstone_facets.modulate = Color("a53030")
		GameManager.PhaseType.BARGAINING:
			gemstone_facets.modulate = Color("de9e41")
		GameManager.PhaseType.DEPRESSION:
			gemstone_facets.modulate = Color("394a50")
		GameManager.PhaseType.ACCEPTANCE:
			gemstone_facets.modulate = Color("75a743")
		GameManager.PhaseType.HEALTH:
			gemstone_facets.modulate = Color("4f8fba")
			
func _ready() -> void:	
	
	if chance_it_exists < 100: 	# for random levels only
		if randi_range(1,100) > chance_it_exists:
			queue_free()
			return
	
	if initialize_brick_on_leveldata: #default is populate stages based on level stats		
		stages.clear()
		stages = SealInitializer.initialize_seal()

	_depression_max = stages.get(GameManager.PhaseType.DEPRESSION, 0.0)
	_had_depression = _depression_max > 0.0
	pick_random_stage()
	_update_stage_label()
	input_pickable = true
	if damage_cracks_1: damage_cracks_1.visible = false
	if damage_cracks_2: damage_cracks_2.visible = false
	if damage_cracks_3: damage_cracks_3.visible = false
	for sprite: Sprite2D in [gemstone_facets, damage_cracks_1, damage_cracks_2, damage_cracks_3]:
		if sprite != null:
			_juice_sprites.append(sprite)
	_start_glow_breathe()

func _start_glow_breathe() -> void:
	if glow_strength <= 1.0:
		return
	var period: float = glow_period * randf_range(0.85, 1.15)
	_glow_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_method(_set_glow, 1.0, glow_strength, period * 0.5)
	_glow_tween.tween_method(_set_glow, glow_strength, 1.0, period * 0.5)
	_glow_tween.custom_step(randf() * period)

func _set_glow(value: float) -> void:
	gemstone_facets.self_modulate = Color(value, value, value)

func hit_knockback(direction: Vector2) -> void:
	if dying or knockback_distance <= 0.0 or direction.is_zero_approx():
		return
	if _knockback_tween != null:
		_knockback_tween.kill()
	var lurch: Vector2 = direction.normalized() * knockback_distance
	_knockback_tween = create_tween()
	_knockback_tween.tween_method(_set_visual_offset, _visual_offset, lurch, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_knockback_tween.tween_method(_set_visual_offset, lurch, Vector2.ZERO, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _set_visual_offset(value: Vector2) -> void:
	_visual_offset = value
	for sprite: Sprite2D in _juice_sprites:
		sprite.position = value

func accept_damage(damage: float, damage_types: Array) -> void:
	if dying:
		return
	if damage_types.has(current_stage):
		_damage_current_stage(damage)
		_feedback_damaged = true
	if not _feedback_pending:
		_feedback_pending = true
		_resolve_damage_feedback.call_deferred()

func _resolve_damage_feedback() -> void:
	if not _feedback_damaged:
		var damage_number: DamageNumber = DAMAGE_NUMBER.instantiate()
		damage_number.position = global_position
		damage_number.show_damage("denied", DamageNumber.COLOR_DEALT)
		get_tree().current_scene.add_child(damage_number)
		if current_stage == GameManager.PhaseType.DENIAL:
			DialogDirector.play(&"tutorial_click_mode", self)
	_feedback_damaged = false
	_feedback_pending = false

func _update_damage_cracks() -> void:
	if !damage_cracks_1: return
	if !damage_cracks_2: return
	if !damage_cracks_3: return
	if health_temp >= health_max: # starting health or greater
		damage_cracks_1.visible = false
		damage_cracks_2.visible = false
		damage_cracks_3.visible = false
	if health_temp == health_max-1: # first hit
		damage_cracks_1.visible = true
		damage_cracks_2.visible = false
		damage_cracks_3.visible = false
	if health_temp == health_max-2: # second hit
		damage_cracks_1.visible = false
		damage_cracks_2.visible = true
		damage_cracks_3.visible = false
	if health_temp <= health_max-3: # third and higher hits
		damage_cracks_1.visible = false
		damage_cracks_2.visible = false
		damage_cracks_3.visible = true

func arm_denial_revert(full_health: float) -> void:
	_denial_revert_max = full_health
	_denial_revert_armed_at_ms = Time.get_ticks_msec()

func try_revert_denial(window_seconds: float) -> bool:
	if dying or _denial_revert_armed_at_ms < 0:
		return false
	var armed: bool = _denial_revert_armed(window_seconds)
	_denial_revert_armed_at_ms = -1
	if not armed:
		return false
	restore_denial(_denial_revert_max)
	return true

func _denial_revert_armed(window_seconds: float) -> bool:
	if _denial_revert_armed_at_ms < 0:
		return false
	return Time.get_ticks_msec() - _denial_revert_armed_at_ms <= int(window_seconds * 1000.0)

func responding_gestures(revert_window_seconds: float) -> Array[GameManager.PhaseType]:
	var verbs: Array[GameManager.PhaseType] = []
	if dying:
		return verbs
	if current_stage == GameManager.PhaseType.DENIAL or _denial_revert_armed(revert_window_seconds):
		verbs.append(GameManager.PhaseType.DENIAL)
	if current_stage == GameManager.PhaseType.ANGER:
		verbs.append(GameManager.PhaseType.ANGER)
	if current_stage == GameManager.PhaseType.BARGAINING:
		verbs.append(GameManager.PhaseType.BARGAINING)
	return verbs

func restore_denial(full_health: float) -> void:
	if dying:
		return
	stages[GameManager.PhaseType.DENIAL] = full_health
	current_stage = GameManager.PhaseType.DENIAL
	health_temp = full_health
	health_max = full_health
	_update_damage_cracks()
	setup_visuals()
	_update_stage_label()

func _damage_current_stage(damage: float) -> void:
	if health_temp - damage <= 0:
		# took damage and was destroyed
		var fx: Node2D
		if current_stage == GameManager.PhaseType.HEALTH:
			fx = brick_destroy_fx.instantiate()
		else: fx = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		_grant_score(current_stage)
		if current_stage == GameManager.PhaseType.HEALTH:
			dying = true
			pop_tween()
		else:
			stages.erase(current_stage)
			if current_stage == GameManager.PhaseType.DEPRESSION and _has_interrupted_stage:
				_restore_interrupted_stage()
			else:
				pick_random_stage()
			_update_stage_label()
	else:
		# took damage but not yet destroyed
		var fx: Node2D = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		health_temp -= damage
		_update_damage_cracks()
		_update_stage_label()

	_spawn_damage_number(damage)

func force_clear() -> void:
	if dying:
		return
	_collapse_stages_to_health()
	accept_damage(health_temp, [GameManager.PhaseType.HEALTH])

func _collapse_stages_to_health() -> void:
	for stage: GameManager.PhaseType in stages.keys():
		if stage != GameManager.PhaseType.HEALTH:
			stages.erase(stage)
	pick_random_stage()
	_update_stage_label()

func _grant_score(stage: GameManager.PhaseType) -> void:
	PlayerData.update_player_score(PHASE_SCORES[stage])

func _spawn_damage_number(damage: float) -> void:
	var damage_number: DamageNumber = DAMAGE_NUMBER.instantiate()
	damage_number.position = global_position
	damage_number.show_damage("-" + DamageNumber.format_amount(damage), DamageNumber.COLOR_DEALT)
	get_tree().current_scene.add_child(damage_number)


func bargain_sweet_range() -> Vector2:
	var half: float = (bargain_sweet_spot_width + bargain_sweet_spot_bonus) * 0.5
	return Vector2(bargain_sweet_spot - half, bargain_sweet_spot + half)

func apply_bargain_modifiers(sweet_spot_bonus: float, discount_bonus: float) -> void:
	bargain_sweet_spot_bonus = sweet_spot_bonus
	bargain_discount_bonus = discount_bonus

func _bargain_price() -> int:
	return roundi(health_temp) + bargain_markup

func _update_stage_label() -> void:
	if current_stage == GameManager.PhaseType.BARGAINING:
		brick_health_label.text = str(_bargain_price())
	else:
		brick_health_label.text = DamageNumber.format_amount(health_temp)

## Called each frame by a DepressionLight covering this seal; holds back the dark.
func illuminate(grace: float = _LIT_GRACE) -> void:
	_lit_cooldown = maxf(_lit_cooldown, grace)
	_reseed_timer = 0.0

func _process(delta: float) -> void:
	if dying:
		return
	if _lit_cooldown > 0.0:
		_lit_cooldown -= delta
		return
	if current_stage == GameManager.PhaseType.DEPRESSION:
		if health_temp < _depression_max:
			health_temp = minf(health_temp + depression_regen_rate * delta, _depression_max)
			_update_damage_cracks()
			_update_stage_label()
	elif depression_reseeds_when_dark and _had_depression and not stages.has(GameManager.PhaseType.DEPRESSION):
		_reseed_timer += delta
		if _reseed_timer >= depression_reseed_delay:
			_reseed_depression()

func _reseed_depression() -> void:
	_reseed_timer = 0.0
	SFX.play_sound(DEPRESSION_REVERT_SOUND)
	_interrupted_stage = current_stage
	_interrupted_hp = health_temp
	_interrupted_max = health_max
	_has_interrupted_stage = true
	stages[GameManager.PhaseType.DEPRESSION] = _depression_max
	current_stage = GameManager.PhaseType.DEPRESSION
	health_temp = _depression_max
	health_max = _depression_max
	_update_damage_cracks()
	setup_visuals()
	_update_stage_label()

func _restore_interrupted_stage() -> void:
	_has_interrupted_stage = false
	current_stage = _interrupted_stage
	health_temp = _interrupted_hp
	health_max = _interrupted_max
	_update_damage_cracks()
	setup_visuals()

func resolve_bargain(bid: float) -> BargainOutcome:
	var sweet: Vector2 = bargain_sweet_range()
	var price: int = _bargain_price()
	if bid < sweet.x:
		return _resolve_undercut(bid, sweet.x, price)
	if bid <= sweet.y:
		_settle_deal(0, false)
		PlayerData.grant_gold_over_time(bargain_deal_reward, 0.0)
		return BargainOutcome.DEAL
	var discount: float = clampf(bargain_discount + bargain_discount_bonus, 0.0, 0.95)
	_settle_deal(roundi((price + (bid - sweet.y) * price) * (1.0 - discount)))
	SFX.play_sound(BARGAIN_OVERSHOT_SOUND)
	return BargainOutcome.OVERPAY

func _resolve_undercut(bid: float, sweet_low: float, price: int) -> BargainOutcome:
	var depth: float = (sweet_low - bid) / sweet_low
	var chance: float
	var penalty: int
	if depth < 1.0 / 3.0:
		chance = bargain_undercut_chance_near
		penalty = 1
	elif depth < 2.0 / 3.0:
		chance = bargain_undercut_chance_mid
		penalty = 2
	else:
		chance = bargain_undercut_chance_far
		penalty = 3
	if randf() < chance:
		_settle_deal(roundi(price * (1.0 - clampf(depth, 0.0, 0.9))))
		Signalbus.screen_flash.emit(Color.GOLD)
		return BargainOutcome.DEAL
	bargain_markup += penalty
	_update_stage_label()
	SFX.play_sound(BARGAIN_EARLY_SOUND)
	return BargainOutcome.INSULT if penalty == 3 else BargainOutcome.WHIFF

func _settle_deal(cost: int, allow_damage: bool = true) -> void:
	PlayerData.pay_bargain_cost(cost, allow_damage)
	_grant_score(GameManager.PhaseType.BARGAINING)
	var fx: Node2D = brick_damage_fx.instantiate()
	if fx != null:
		fx.position = global_position
		get_tree().current_scene.add_child(fx)
	stages.erase(current_stage)
	pick_random_stage()
	_update_stage_label()

func pop_tween() -> void:
	if _knockback_tween != null:
		_knockback_tween.kill()
	if _glow_tween != null:
		_glow_tween.kill()
	_set_visual_offset(Vector2.ZERO)
	_set_glow(1.0)
	var tween: Tween = get_tree().create_tween()

	tween.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(.1, .1), 0.1).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.connect("finished", Callable(self, "_on_tween_finished").bind(self))

#cleanup brick collision after tween finishes
func _on_tween_finished(collider: Area2D) -> void:
	if is_instance_valid(collider):
		var parent: Node = collider.get_parent()
		var spawn_position: Vector2 = collider.position
		collider.queue_free()
		var payload: BonusPayload = BONUS_POOL.pick_weighted()
		var count: int = 1
		if payload is CurrencyPayload and randf() < COIN_WINDFALL_CHANCE:
			count = COIN_WINDFALL_COUNT
			SFX.play_sound("win_sting")
		for i: int in count:
			var drop: BonusDrop = _make_drop(payload)
			parent.add_child(drop)
			drop.position = spawn_position
			if count > 1:
				drop.position += Vector2(randf_range(-COIN_WINDFALL_SCATTER, COIN_WINDFALL_SCATTER), randf_range(-COIN_WINDFALL_SCATTER, COIN_WINDFALL_SCATTER))
			Signalbus.gold_spawned.emit(1)
		Signalbus.enemy_requested.emit(collider)
		Signalbus.brick_destroyed.emit()

func _make_drop(payload: BonusPayload) -> BonusDrop:
	var bonus: BonusDrop = BONUS_DROP.instantiate()
	bonus.payload = payload
	return bonus
