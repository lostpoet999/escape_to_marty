class_name RoomState extends Resource

var visited: bool = false
var cleared: bool = false
var loot_taken: bool = false
var shop_generated: bool = false
var clear_count: int = 0
var  item_box_data: ItemBoxData

func generate_item_box()->void:
	if !item_box_data:
		item_box_data = ItemBoxData.new()
		item_box_data.generate_item_box()
