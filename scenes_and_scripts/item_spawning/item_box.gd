class_name Itembox extends Node2D

var item_box_data: ItemBoxData

func _on_loot_box_pressed() -> void:
	if item_box_data.items.is_empty():
		queue_free()
		return
	var item: BaseItem = item_box_data.items.pick_random()
	item_box_data.items.erase(item)
	PlayerData.inventory.add_item(item)
	if item_box_data.items.is_empty():
		queue_free()
