class_name BaseSeal
extends Area2D

const STAR_COLLECTIBLE: PackedScene = preload("uid://cfjv2f23gme53")
const BONUS_DROP: PackedScene = preload("res://scenes_and_scripts/collectibles/bonus_drop.tscn")
const BONUS_POOL: BonusDropPool = preload("res://scenes_and_scripts/collectibles/bonus_drops/bonus_drop_pool.tres")
const DAMAGE_NUMBER: PackedScene = preload("uid://bedvoohhfbi03")


const PHASE_SCORES: Dictionary[GameManager.PhaseType, int] = {
	GameManager.PhaseType.DENIAL: 100,
	GameManager.PhaseType.ANGER: 150,
	GameManager.PhaseType.BARGAINING: 200,
	GameManager.PhaseType.DEPRESSION: 250,
	GameManager.PhaseType.ACCEPTANCE: 300,
	GameManager.PhaseType.HEALTH: 500,
}

enum BargainOutcome { OVERPAY, DEAL, WHIFF, INSULT }

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
	
@export var brick_health: int = 1
var health_temp: float
@export var brick_damage_fx: PackedScene
@export var brick_destroy_fx: PackedScene

@export_category("Bargain")
@export var bargain_sweet_spot: float = 0.5
@export var bargain_sweet_spot_width: float = 0.128
@export var bargain_discount: float = 0.0
@export var bargain_undercut_chance_near: float = 0.5
@export var bargain_undercut_chance_mid: float = 0.2
@export var bargain_undercut_chance_far: float = 0.1

var bargain_markup: int = 0
var bargain_sweet_spot_bonus: float = 0.0
var bargain_discount_bonus: float = 0.0

@export_category("Depression")
## Phase-HP per second the exposed DEPRESSION phase regrows while it sits unlit. Snuffing a light lets cleared progress melt back into the dark.
@export var depression_regen_rate: float = 0.6
## When true, a seal whose DEPRESSION was fully cleared slides BACK into depression if left dark too long (the snuff-trap). Off until the light-snuff enemy exists; flip on per-seal to feel it.
@export var depression_reseeds_when_dark: bool = false
## Seconds a cleared seal must stay unlit before DEPRESSION reseeds (only when depression_reseeds_when_dark).
@export var depression_reseed_delay: float = 3.0
const _LIT_GRACE: float = 0.12
var _lit_cooldown: float = 0.0
var _depression_max: float = 0.0
var _had_depression: bool = false
var _reseed_timer: float = 0.0

func pick_random_stage() -> void:
	if stages.is_empty():
		current_stage = GameManager.PhaseType.HEALTH
		health_temp = brick_health
		setup_visuals()
		return
	
	var non_health_stages: Array = stages.keys().filter(func(k:GameManager.PhaseType)->bool: return k != GameManager.PhaseType.HEALTH)
	
	if non_health_stages.is_empty():
		current_stage = GameManager.PhaseType.HEALTH
	else:
		current_stage = non_health_stages.pick_random()
	
	health_temp = stages[current_stage]
	setup_visuals()

func setup_visuals()->void:
	match current_stage:
		GameManager.PhaseType.DENIAL:
			gemstone_facets.modulate = Color(0.58, 0.37, 0.81)
		GameManager.PhaseType.ANGER:
			gemstone_facets.modulate = Color.RED
		GameManager.PhaseType.BARGAINING:
			gemstone_facets.modulate = Color.DARK_KHAKI
		GameManager.PhaseType.DEPRESSION:
			gemstone_facets.modulate = Color.DARK_GRAY
		GameManager.PhaseType.ACCEPTANCE:
			gemstone_facets.modulate = Color.LIME_GREEN
		GameManager.PhaseType.HEALTH:
			gemstone_facets.modulate = Color.BLUE
			
func _ready() -> void:	
	if initialize_brick_on_leveldata:#default is populate stages based on level stats		
		stages.clear()
		stages = SealInitializer.initialize_seal()

	_depression_max = stages.get(GameManager.PhaseType.DEPRESSION, 0.0)
	_had_depression = _depression_max > 0.0
	pick_random_stage()
	_update_stage_label()
	input_pickable = true
	damage_cracks_1.visible = false
	damage_cracks_2.visible = false
	damage_cracks_3.visible = false

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
		var damage_number = DAMAGE_NUMBER.instantiate()
		damage_number.position = global_position
		damage_number.show_damage("denied", DamageNumber.COLOR_DEALT)
		get_tree().current_scene.add_child(damage_number)
	_feedback_damaged = false
	_feedback_pending = false

func _damage_current_stage(damage: float) -> void:
	if health_temp - damage <= 0:
		var fx: Node2D
		if current_stage == GameManager.PhaseType.HEALTH:
			fx = brick_destroy_fx.instantiate()
		else: fx = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		PlayerData.update_player_score(PHASE_SCORES[current_stage])
		if current_stage == GameManager.PhaseType.HEALTH:
			dying = true
			pop_tween()
		else:
			stages.erase(current_stage)
			pick_random_stage()
			_update_stage_label()
	else:
		if !damage_cracks_1.visible: damage_cracks_1.visible = true
		if damage_cracks_1.visible: damage_cracks_2.visible = true
		if damage_cracks_2.visible: damage_cracks_3.visible = true

		var fx: Node2D = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		health_temp -= damage
		_update_stage_label()
	_spawn_damage_number(damage)

func _spawn_damage_number(damage: float) -> void:
	var damage_number = DAMAGE_NUMBER.instantiate()
	damage_number.position = global_position
	damage_number.show_damage("-" + str(int(round(damage))), DamageNumber.COLOR_DEALT)
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
		brick_health_label.text = str(health_temp)

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
			_update_stage_label()
	elif depression_reseeds_when_dark and _had_depression and not stages.has(GameManager.PhaseType.DEPRESSION):
		_reseed_timer += delta
		if _reseed_timer >= depression_reseed_delay:
			_reseed_depression()

func _reseed_depression() -> void:
	_reseed_timer = 0.0
	stages[GameManager.PhaseType.DEPRESSION] = _depression_max
	current_stage = GameManager.PhaseType.DEPRESSION
	health_temp = _depression_max
	setup_visuals()
	_update_stage_label()

func resolve_bargain(bid: float) -> BargainOutcome:
	var sweet: Vector2 = bargain_sweet_range()
	var price: int = _bargain_price()
	if bid < sweet.x:
		return _resolve_undercut(bid, sweet.x, price)
	if bid <= sweet.y:
		var discount: float = clampf(bargain_discount + bargain_discount_bonus, 0.0, 0.95)
		_settle_deal(int(round(price * (1.0 - discount))))
		return BargainOutcome.DEAL
	_settle_deal(price + int(round((bid - sweet.y) * price)))
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
		_settle_deal(int(round(price * (1.0 - clampf(depth, 0.0, 0.9)))))
		Signalbus.screen_flash.emit(Color.GOLD)
		return BargainOutcome.DEAL
	bargain_markup += penalty
	_update_stage_label()
	return BargainOutcome.INSULT if penalty == 3 else BargainOutcome.WHIFF

func _settle_deal(cost: int) -> void:
	PlayerData.pay_bargain_cost(cost)
	PlayerData.update_player_score(PHASE_SCORES[GameManager.PhaseType.BARGAINING])
	var fx: Node2D = brick_damage_fx.instantiate()
	if fx != null:
		fx.position = global_position
		get_tree().current_scene.add_child(fx)
	stages.erase(current_stage)
	pick_random_stage()
	_update_stage_label()

func pop_tween() -> void:
	var tween: Tween = get_tree().create_tween()

	tween.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(.1, .1), 0.1).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.connect("finished", Callable(self, "_on_tween_finished").bind(self))

#cleanup brick collision after tween finishes
func _on_tween_finished(collider: Area2D) -> void:
	if is_instance_valid(collider):
		collider.queue_free()
		var drop: Area2D = _make_drop()
		collider.get_parent().add_child(drop)
		drop.position = collider.position
		Signalbus.star_spawned.emit(1)
		Signalbus.enemy_requested.emit(collider)
		Signalbus.brick_destroyed.emit()

func _make_drop() -> Area2D:
	if randf() < BONUS_POOL.drop_chance:
		var payload: BonusPayload = BONUS_POOL.pick_random()
		if payload != null:
			var bonus: BonusDrop = BONUS_DROP.instantiate()
			bonus.payload = payload
			return bonus
	return STAR_COLLECTIBLE.instantiate()
