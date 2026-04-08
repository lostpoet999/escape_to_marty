class_name LootItemsData extends Resource

var max_items: int = 0
var items: Array [BaseItem] = []
var pool: Array[BaseItem]
const ITEM_BOX: PackedScene = preload("uid://165yx2m2saao")
const SHOP: PackedScene = preload("uid://bn3va5ib8tytd")


func instantiate_lootbox() -> Node2D:
	return ITEM_BOX.instantiate()

func instantiate_shop() -> Node2D:
	return SHOP.instantiate()

func filter_owned_actives()->void:
	var owned_actives: Array[BaseItem] = PlayerData.inventory.get_core_items()
	pool = pool.filter(func(i: BaseItem) -> bool:
		return not owned_actives.has(i))	

func generate_item_box()->void:
	filter_owned_actives()
	var room_entry:RoomEntry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	if room_entry.room_type == RoomEntry.ROOM_TYPES.free_item:
		max_items = randi() % GameManager.floor_data.free_item_max + 2
	elif room_entry.room_type == RoomEntry.ROOM_TYPES.shop:
		max_items = GameManager.floor_data.shop_items
	@warning_ignore("unsafe_property_access")
	pool = ItemSpawner.item_pool_data.item_pool.duplicate()
	for n:int in max_items:
		if pool.is_empty(): break			
		var item:BaseItem = pool.pick_random()
		items.push_back(item)
		pool.erase(item)
