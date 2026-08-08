class_name SpiderEncounterRoom
extends EncounterRoomBase

const POUCH_SIZE: int = 3
const REPAYMENT_POOL: int = 25
const HEART_HIT_SPACING_MIN: float = 0.25
const HEART_HIT_SPACING_MAX: float = 0.4

@export var max_live_red_coins: int = 3 ## Cap on red spit coins in flight at once, encounter-wide; spiders with a full board idle their spit tick instead.
@export var max_live_webs: int = 2 ## Cap on webs in flight at once, encounter-wide; web-blocked spiders idle their spit tick instead.

var _next_heart_hit_time: float = 0.0
var _unallocated: int = 0
var _live_spiders: int = 0
var _live_coins: int = 0
var _live_red_coins: int = 0
var _spiders_spawned: int = 0
var _initial_pool: int = 0
var _resolved_coins: int = 0
var _stage_two_max: int = 0

func _ready() -> void:
	_unallocated = REPAYMENT_POOL
	_initial_pool = _unallocated
	await super()
	if not encounter_cleared:
		Signalbus.encounter_progress.emit.call_deferred(1, 2, float(_initial_pool), float(_initial_pool))

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

func claim_heart_hit_delay() -> float:
	var now: float = Time.get_ticks_msec() / 1000.0
	var start: float = maxf(now, _next_heart_hit_time)
	_next_heart_hit_time = start + randf_range(HEART_HIT_SPACING_MIN, HEART_HIT_SPACING_MAX)
	return start - now

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
	_resolved_coins += 1
	_emit_progress()
	_check_encounter_done()

func _on_wall_walker_removed(walker: Node2D) -> void:
	super(walker)
	_live_spiders -= 1
	_emit_progress()
	_check_encounter_done()

func _emit_progress() -> void:
	if encounter_cleared:
		return
	var unresolved: int = _initial_pool - _resolved_coins
	if unresolved > 0:
		Signalbus.encounter_progress.emit(1, 2, float(unresolved), float(_initial_pool))
		return
	if _stage_two_max == 0:
		_stage_two_max = maxi(_live_spiders, 1)
	Signalbus.encounter_progress.emit(2, 2, float(maxi(_live_spiders, 0)), float(_stage_two_max))

func _check_encounter_done() -> void:
	if encounter_cleared or _spiders_spawned == 0:
		return
	if _unallocated == 0 and _live_spiders <= 0 and _live_coins <= 0:
		clear_encounter()
