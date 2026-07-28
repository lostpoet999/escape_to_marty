class_name RepaymentSpider
extends MoneyThiefSpider

const SPIT_COIN: PackedScene = preload("res://scenes_and_scripts/actors/enemies/specific_enemies/repayment_spider/spit_coin.tscn")
const SPIDER_WEB: PackedScene = preload("res://scenes_and_scripts/actors/enemies/specific_enemies/repayment_spider/spider_web.tscn")
const GOLD_PAYLOAD: BonusPayload = preload("res://scenes_and_scripts/collectibles/bonus_drops/currency_payload.tres")
const WEB_FORM_TEXTURE: Texture2D = preload("res://scenes_and_scripts/actors/enemies/specific_enemies/money_thief_spider/spider_2.png")
const COIN_ARC_SPEED_MIN: float = 155.0
const COIN_ARC_SPEED_MAX: float = 250.0
const COIN_ARC_LIFT_MIN: float = 200.0
const COIN_ARC_LIFT_MAX: float = 380.0
const COIN_DROP_SPEED: float = 145.0
const WEB_SPEED_MIN: float = 125.0
const WEB_SPEED_MAX: float = 195.0
const WALL_CLEARANCE: float = 130.0
const SPREAD_ATTEMPTS: int = 14
const HEALTH_MIN: float = 15.0
const HEALTH_MAX: float = 25.0

var _pays_out: bool = false
var _room: SpiderEncounterRoom

func _ready() -> void:
	super()
	health = randf_range(HEALTH_MIN, HEALTH_MAX)
	_spread_along_wall()
	_room = get_tree().current_scene as SpiderEncounterRoom
	if _room != null:
		for i: int in _room.allocate_pouch():
			hoard.append(GOLD_PAYLOAD)
		_room.register_spider()
	_pays_out = not hoard.is_empty()
	if _pays_out:
		_escape_timer.stop()
		if _escape_bar != null:
			_escape_bar.visible = false

func _spread_along_wall() -> void:
	var crawl: WallCrawl = null
	for action: EnemyActions in action_pool:
		crawl = action as WallCrawl
		if crawl != null:
			break
	if crawl == null:
		return
	var axis_is_y: bool = wall_side != WallSide.TOP
	var occupied: Array[float] = []
	for other: Node in get_tree().get_nodes_in_group(&"wall_walkers"):
		var o: WallWalker = other as WallWalker
		if o == null or o == self or o.wall_side != wall_side or o.is_queued_for_deletion():
			continue
		occupied.append(o.global_position.y if axis_is_y else o.global_position.x)
	var current: float = global_position.y if axis_is_y else global_position.x
	if _spot_is_clear(current, occupied):
		return
	for i: int in SPREAD_ATTEMPTS:
		var candidate: float = randf_range(crawl.crawl_min, crawl.crawl_max)
		if _spot_is_clear(candidate, occupied):
			if axis_is_y:
				global_position.y = candidate
			else:
				global_position.x = candidate
			return

func _spot_is_clear(pos: float, occupied: Array[float]) -> bool:
	for o_pos: float in occupied:
		if absf(pos - o_pos) < WALL_CLEARANCE:
			return false
	return true

func perform_spit() -> void:
	if _escaping or not _pays_out:
		return
	if not hoard.is_empty():
		if _room == null or _room.can_spit_coin():
			_spit_coin()
			_eat_pulse()
	elif _room == null or _room.can_spit_web():
		_spit_web()
		_eat_pulse()

func _spit_coin() -> void:
	var payload: BonusPayload = hoard[hoard.size() - 1]
	hoard.resize(hoard.size() - 1)
	if hoard.is_empty():
		_show_web_form()
	var coin: SpitCoin = SPIT_COIN.instantiate()
	coin.payload = payload
	coin.hurts_on_miss = true
	coin.launch_velocity = _coin_launch_velocity()
	get_parent().add_child(coin)
	coin.global_position = global_position
	Signalbus.gold_spawned.emit(1)

func _show_web_form() -> void:
	var sprite: Sprite2D = get_node_or_null("EnemySprite")
	if sprite != null:
		sprite.texture = WEB_FORM_TEXTURE

func _coin_launch_velocity() -> Vector2:
	match wall_side:
		WallSide.LEFT:
			return Vector2(randf_range(COIN_ARC_SPEED_MIN, COIN_ARC_SPEED_MAX), -randf_range(COIN_ARC_LIFT_MIN, COIN_ARC_LIFT_MAX))
		WallSide.RIGHT:
			return Vector2(-randf_range(COIN_ARC_SPEED_MIN, COIN_ARC_SPEED_MAX), -randf_range(COIN_ARC_LIFT_MIN, COIN_ARC_LIFT_MAX))
		_:
			return Vector2(0.0, COIN_DROP_SPEED)

func _spit_web() -> void:
	var paddle: Node2D = get_tree().get_first_node_in_group(GameManager.PADDLE) as Node2D
	if paddle == null:
		return
	var web: SpiderWeb = SPIDER_WEB.instantiate()
	web.target_position = paddle.global_position
	web.speed = randf_range(WEB_SPEED_MIN, WEB_SPEED_MAX)
	get_parent().add_child(web)
	web.global_position = global_position

func _on_death(killed_by_damage: bool) -> void:
	if not killed_by_damage:
		return
	for payload: BonusPayload in hoard:
		var coin: SpitCoin = SPIT_COIN.instantiate()
		coin.payload = payload
		get_parent().add_child(coin)
		coin.global_position = global_position + _scatter_offset()
		Signalbus.gold_spawned.emit(1)
	hoard.clear()
