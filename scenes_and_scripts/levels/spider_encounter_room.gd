class_name SpiderEncounterRoom
extends EncounterRoomBase

const POUCH_SIZE: int = 3
const TEST_STOLEN_GOLD: int = 20

@export var max_live_red_coins: int = 3 ## Cap on red spit coins in flight at once, encounter-wide; spiders with a full board idle their spit tick instead.
@export var max_live_webs: int = 2 ## Cap on webs in flight at once, encounter-wide; web-blocked spiders idle their spit tick instead.

var zero_stolen: bool = false
var _unallocated: int = 0
var _live_spiders: int = 0
var _live_coins: int = 0
var _live_red_coins: int = 0
var _spiders_spawned: int = 0

func _ready() -> void:
	_unallocated = TEST_STOLEN_GOLD if GameManager.test_floor_active else PlayerData.spider_stolen_gold
	zero_stolen = _unallocated == 0
	await super()

func allocate_pouch() -> int:
	var coins: int = mini(POUCH_SIZE, _unallocated)
	_unallocated -= coins
	return coins

func has_coins_to_allocate() -> bool:
	return _unallocated > 0

func register_spider() -> void:
	_live_spiders += 1
	_spiders_spawned += 1

func can_spit_coin() -> bool:
	return _live_red_coins < max_live_red_coins

func can_spit_web() -> bool:
	return get_tree().get_nodes_in_group(&"spider_webs").size() < max_live_webs

func register_coin(hurts_on_miss: bool) -> void:
	_live_coins += 1
	if hurts_on_miss:
		_live_red_coins += 1

func coin_resolved(hurts_on_miss: bool) -> void:
	_live_coins -= 1
	if hurts_on_miss:
		_live_red_coins -= 1
	_check_encounter_done()

func _on_wall_walker_removed(walker: Node2D) -> void:
	super(walker)
	_live_spiders -= 1
	_check_encounter_done()

func _check_encounter_done() -> void:
	if encounter_cleared or _spiders_spawned == 0:
		return
	if _unallocated == 0 and _live_spiders <= 0 and _live_coins <= 0:
		clear_encounter()
