extends Node

@export var item_pool_data: ItemPool

var type_filter: String

func pick_random_item(weights_override: SpawnWeights = null)->BaseItem:
	var tier: int = get_tier(weights_override)
	var list_of_picked_tier: Array = item_pool_data.item_pool.filter(
		func(item: BaseItem)->bool: return item.rarity == tier
	)

	var picked_item: BaseItem = list_of_picked_tier.pick_random()
	return picked_item

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
