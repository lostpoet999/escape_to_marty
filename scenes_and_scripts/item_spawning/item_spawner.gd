extends Node

const MULTIPLIER_SUPPRESSION_PER_COPY: float = 0.15
const MULTIPLIER_REROLL_ATTEMPTS: int = 4

@export var item_pool_data: ItemPool

var type_filter: String

func pick_random_item(weights_override: SpawnWeights = null, candidates: Array[BaseItem] = [])->BaseItem:
	var picked_item: BaseItem = _roll_item(weights_override, candidates)
	for attempt: int in MULTIPLIER_REROLL_ATTEMPTS:
		if picked_item == null or not _multiplier_draw_suppressed(picked_item):
			break
		picked_item = _roll_item(weights_override, candidates)
	return picked_item

func _roll_item(weights_override: SpawnWeights, candidates: Array[BaseItem])->BaseItem:
	var source_pool: Array[BaseItem] = candidates if not candidates.is_empty() else item_pool_data.item_pool
	var tier: int = get_tier(weights_override)
	var list_of_picked_tier: Array = source_pool.filter(
		func(item: BaseItem)->bool: return item.rarity == tier
	)
	if list_of_picked_tier.is_empty() and not candidates.is_empty():
		return candidates.pick_random()
	var picked_item: BaseItem = list_of_picked_tier.pick_random()
	return picked_item

func _multiplier_draw_suppressed(item: BaseItem) -> bool:
	if not _is_multiplier_item(item):
		return false
	var owned: int = _owned_multiplier_count()
	if owned <= 0:
		return false
	return randf() > pow(1.0 - MULTIPLIER_SUPPRESSION_PER_COPY, owned)

func _is_multiplier_item(item: BaseItem) -> bool:
	var passive: BallPassive = item as BallPassive
	return passive != null and passive.global_multi > 1.0

func _owned_multiplier_count() -> int:
	if PlayerData.inventory == null:
		return 0
	var count: int = 0
	for item: BaseItem in PlayerData.inventory.get_items():
		if _is_multiplier_item(item):
			count += 1
	return count

func get_tier(weights_override: SpawnWeights = null)->int:
	# read the current floor's weights live (no cache) so a floor change always takes effect;
	# pass weights_override to roll against a specific table (e.g. a boss's tier_weights)
	var source: SpawnWeights = weights_override if weights_override != null else GameManager.floor_data.spawn_weight
	var weights: Dictionary[int, float] = {
		BaseItem.RarityType.COMMON : source.common,
		BaseItem.RarityType.UNCOMMON : source.uncommon,
		BaseItem.RarityType.RARE : source.rare,
		BaseItem.RarityType.VERY_RARE : source.very_rare,
	}
	#get spawn-tier
	var rand: float = randf_range(0.0, 100.0)
	var cummulative: float = 0.0
	for tier_key:int in weights:
		cummulative += weights[tier_key]
		if rand < cummulative:
			return tier_key
	return BaseItem.RarityType.VERY_RARE

func normalize_spawn_weights()->void: #TODO: create method to normalize the spawn weights when an item changes the spawn rate of a particular tier
	pass
