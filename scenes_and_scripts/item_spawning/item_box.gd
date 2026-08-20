class_name Itembox extends Node2D

var loot_items_data: LootItemsData

func _ready() -> void:
	$LootBox.set_meta(&"click_pickable", true)

func _on_loot_box_pressed() -> void:
	if loot_items_data.items.is_empty():
		queue_free()
		return
	var item: BaseItem = loot_items_data.items.pick_random()
	if not await PlayerData.inventory.add_item(item):
		return
	loot_items_data.items.erase(item)
	if loot_items_data.items.is_empty():
		queue_free()
