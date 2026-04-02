extends Node2D

var items_looted: int = 0
var max_items: int

func _ready() -> void:	
	max_items = randi() % GameManager.floor_data.free_item_max + 1	

func _on_loot_box_pressed() -> void:	
	if items_looted < max_items:
		items_looted +=1
		var new_item: BaseItem = ItemSpawner.pick_random_item()	
		PlayerData.inventory.add_item(new_item)
	elif items_looted == max_items:
		queue_free()
		
