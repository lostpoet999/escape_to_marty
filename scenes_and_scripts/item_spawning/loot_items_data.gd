class_name LootItemsData extends Resource

const ITEMS_PER_ROOM: int = 3 ## free-item and shop rooms both offer exactly this many; shop_panel.tscn has a matching fixed slot count

var max_items: int = 0
var items: Array [BaseItem] = []
var pool: Array[BaseItem]
var base_pick_used: bool = false
const ITEM_BOX: PackedScene = preload("uid://165yx2m2saao")


func instantiate_lootbox() -> Node2D:
	return ITEM_BOX.instantiate()

func filter_owned_actives()->void:
	var owned_actives: Array[BaseItem] = PlayerData.inventory.get_core_items()
	pool = pool.filter(func(i: BaseItem) -> bool:
		return not owned_actives.has(i))	

func generate_item_box(pool_override: ItemPool = null)->void:
	items.clear()
	max_items = ITEMS_PER_ROOM
	if pool_override != null:
		pool = pool_override.item_pool.duplicate()
	else:
		@warning_ignore("unsafe_property_access")
		pool = ItemSpawner.item_pool_data.item_pool.duplicate()
	filter_owned_actives()
	for n:int in max_items:
		if pool.is_empty(): break
		var item: BaseItem
		if pool_override != null:
			item = pool.pick_random()
		else:
			# weight by the floor's rarity tiers, but pick from the filtered pool so
			# owned-active filtering and no-duplicates still hold. fall back to a flat
			# pick if the rolled tier has no remaining items.
			var tier: int = ItemSpawner.get_tier(GameManager.floor_data.spawn_weight)
			var tier_pool: Array = pool.filter(func(i: BaseItem) -> bool: return i.rarity == tier)
			item = tier_pool.pick_random() if not tier_pool.is_empty() else pool.pick_random()
		items.push_back(item)
		pool.erase(item)

func generate_boss_drop(config: BossLootConfig)->void:
	items.clear()
	pool = ItemSpawner.item_pool_data.item_pool.duplicate()
	filter_owned_actives()
	# guaranteed items first — bypass weights and owned-active filter
	for guaranteed:BaseItem in config.guaranteed_items:
		items.push_back(guaranteed)
	# weighted random rolls
	for n:int in config.random_drop_count:
		if pool.is_empty(): break
		var rolled:BaseItem = ItemSpawner.pick_random_item(config.tier_weights)
		if rolled != null:
			items.push_back(rolled)
			pool.erase(rolled)
