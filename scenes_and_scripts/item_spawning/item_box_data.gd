class_name ItemBoxData extends Resource

var max_items: int = 0
var items: Array [BaseItem] = []
var pool: Array[BaseItem]
@export var scene_ref: PackedScene = preload("uid://165yx2m2saao")

func instantiate_scene() -> Node2D:
	return scene_ref.instantiate()

func filter_owned_actives()->void:
	var owned_actives: Array[BaseItem] = PlayerData.inventory.get_core_items()
	pool = pool.filter(func(i: BaseItem) -> bool:
		return not owned_actives.has(i))	

func generate_item_box()->void:
	filter_owned_actives()
	max_items = randi() % GameManager.floor_data.free_item_max + 1
	pool = ItemSpawner.item_pool_data.item_pool.duplicate()
	for n:int in max_items:
		if pool.is_empty(): break			
		var item:BaseItem = pool.pick_random()
		items.push_back(item)
		pool.erase(item)
