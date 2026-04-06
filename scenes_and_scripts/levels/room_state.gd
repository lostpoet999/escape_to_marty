class_name RoomState extends Resource

var visited: bool = false
var cleared: bool = false
var loot_taken: bool = false
var shop_generated: bool = false
var clear_count: int = 0
var  loot_items_data: LootItemsData

func generate_item_box()->void:
	if !loot_items_data:
		loot_items_data = LootItemsData.new()
		loot_items_data.generate_item_box()
