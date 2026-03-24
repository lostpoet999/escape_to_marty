extends Node2D


func _on_loot_box_pressed() -> void:
	var new_item: BaseItem = ItemSpawner.pick_random_item()	
	PlayerData.inventory.add_item(new_item)
