extends Node

@export var item_pool_data: ItemPool

var spawn_weights: Dictionary[int,float]
var type_filter: String

func _ready() -> void:
	initialize_spawn_weights()

func initialize_spawn_weights()->void:
	spawn_weights = {
		BaseItem.RarityType.COMMON : GameManager.floor_data.spawn_weight.common,
		BaseItem.RarityType.UNCOMMON : GameManager.floor_data.spawn_weight.uncommon,
		BaseItem.RarityType.RARE : GameManager.floor_data.spawn_weight.rare,
		BaseItem.RarityType.VERY_RARE : GameManager.floor_data.spawn_weight.very_rare
	}

func pick_random_item(weights_override: SpawnWeights = null)->BaseItem:
	var tier: int = get_tier(weights_override)
	var list_of_picked_tier: Array = item_pool_data.item_pool.filter(
		func(item: BaseItem)->bool: return item.rarity == tier
	)

	var picked_item: BaseItem = list_of_picked_tier.pick_random()
	return picked_item

func get_tier(weights_override: SpawnWeights = null)->int:
	var weights: Dictionary[int, float] = spawn_weights
	if weights_override != null:
		weights = {
			BaseItem.RarityType.COMMON : weights_override.common,
			BaseItem.RarityType.UNCOMMON : weights_override.uncommon,
			BaseItem.RarityType.RARE : weights_override.rare,
			BaseItem.RarityType.VERY_RARE : weights_override.very_rare,
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
