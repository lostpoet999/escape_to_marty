class_name RoomState extends Resource

var visited: bool = false
var cleared: bool = false
var loot_taken: bool = false
var shop_generated: bool = false
var clear_count: int = 0
var practice_cleared: bool = false
var revealed_exits: Array[StringName] = [] #directions (e.g. &"north") whose secret exit the player has revealed this run
var  loot_items_data: LootItemsData
var spawn_rolls: Dictionary[String, bool] = {}

func generate_item_box(pool_override: ItemPool = null, for_shop: bool = false)->void:
	if !loot_items_data:
		loot_items_data = LootItemsData.new()
		loot_items_data.generate_item_box(pool_override, for_shop)

func should_exist(key: String, chance: int) -> bool:
	if chance >= 100:
		return true
	if !spawn_rolls.has(key):
		spawn_rolls[key] = randi_range(1, 100) <= chance
	return spawn_rolls[key]
