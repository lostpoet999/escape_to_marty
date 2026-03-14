extends Node

@export var item_pool_data: ItemPool

var spawn_weights: Dictionary[int,float]
var type_filter: String

func _ready() -> void:
	intitialize_spawn_weights()

func intitialize_spawn_weights()->void:
	spawn_weights = {
		BaseItem.RarityType.COMMON : GameManager.floor_data.spawn_weight.common,
		BaseItem.RarityType.UNCOMMON : GameManager.floor_data.spawn_weight.unconmon,
		BaseItem.RarityType.RARE : GameManager.floor_data.spawn_weight.rare,
		BaseItem.RarityType.VERY_RARE : GameManager.floor_data.spawn_weight.very_rare
	}	

func pick_random_item()->BaseItem:
	var tier: int = get_tier()
	var list_of_picked_tier: Array = item_pool_data.item_pool.filter(
		func(item: BaseItem)->bool: return item.rarity == tier
	)	

	var picked_item: BaseItem = list_of_picked_tier.pick_random()
	return picked_item

func get_tier()->int:
	#get spawn-tier
	var rand: float = randf_range(0.0, 100.0) 
	var cummulative: float = 0.0
	for weights:int in spawn_weights:
		cummulative += spawn_weights[weights]
		if rand < cummulative:
			return weights
	return BaseItem.RarityType.VERY_RARE

func normalize_spawn_weights()->void: #TODO: create method to normalize the spawn weights when an item changes the spawn rate of a particular tier
	pass
