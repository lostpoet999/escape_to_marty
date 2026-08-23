class_name LootItemsData extends Resource

const ITEMS_PER_ROOM: int = 3 ## free-item and shop rooms both offer exactly this many; shop_panel.tscn has a matching fixed slot count

var max_items: int = 0
var items: Array [BaseItem] = []
var pool: Array[BaseItem]
var base_pick_used: bool = false
var flat_pick: bool = false
const ITEM_BOX: PackedScene = preload("uid://165yx2m2saao")


func instantiate_lootbox() -> Node2D:
	return ITEM_BOX.instantiate()

func free_picks_available() -> int:
	var base_pick: int = 0 if base_pick_used else 1
	return base_pick + PlayerData.pick2_vouchers

func free_pick_exhausted() -> bool:
	return items.is_empty() or free_picks_available() <= 0

func shop_exhausted() -> bool:
	return items.is_empty() and PlayerData.shop_restock_vouchers <= 0

func filter_owned_actives()->void:
	var owned_actives: Array[BaseItem] = PlayerData.inventory.get_core_items()
	pool = pool.filter(func(i: BaseItem) -> bool:
		return not owned_actives.has(i))

func filter_maxed_types()->void:
	var owned: Array = PlayerData.inventory.get_items()
	pool = pool.filter(func(i: BaseItem) -> bool:
		var type_item: BallDamageType = i as BallDamageType
		if type_item == null:
			return true
		return owned.count(type_item) < type_item.max_copies)

func filter_capped_outside_shops()->void:
	var owned: Array = PlayerData.inventory.get_items()
	pool = pool.filter(func(i: BaseItem) -> bool:
		return owned.count(i) < i.max_copies_outside_shops)

func generate_item_box(pool_override: ItemPool = null, for_shop: bool = false)->void:
	items.clear()
	max_items = ITEMS_PER_ROOM
	flat_pick = pool_override != null
	if pool_override != null:
		pool = pool_override.item_pool.duplicate()
	else:
		@warning_ignore("unsafe_property_access")
		pool = ItemSpawner.item_pool_data.item_pool.duplicate()
	filter_owned_actives()
	filter_maxed_types()
	if not for_shop:
		filter_capped_outside_shops()
	for n:int in max_items:
		if pool.is_empty(): break
		var item: BaseItem = draw_one()
		items.push_back(item)
		pool.erase(item)

func draw_one() -> BaseItem:
	if pool.is_empty():
		return null
	if flat_pick:
		return pool.pick_random()
	# weight by the floor's rarity tiers, but pick from the filtered pool so
	# owned-active filtering and no-duplicates still hold. fall back to a flat
	# pick if the rolled tier has no remaining items.
	var tier: int = ItemSpawner.get_tier(GameManager.floor_data.spawn_weight)
	var tier_pool: Array = pool.filter(func(i: BaseItem) -> bool: return i.rarity == tier)
	return tier_pool.pick_random() if not tier_pool.is_empty() else pool.pick_random()

func reroll_slot(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	var item: BaseItem = draw_one()
	if item == null:
		return false
	items[index] = item
	pool.erase(item)
	return true

func generate_boss_drop(config: BossLootConfig)->void:
	items.clear()
	pool = ItemSpawner.item_pool_data.item_pool.duplicate()
	filter_owned_actives()
	filter_maxed_types()
	filter_capped_outside_shops()
	# guaranteed items first — bypass weights and owned-active filter
	for guaranteed:BaseItem in config.guaranteed_items:
		items.push_back(guaranteed)
		pool.erase(guaranteed)
	# weighted random rolls
	for n:int in config.random_drop_count:
		if pool.is_empty(): break
		var rolled:BaseItem = ItemSpawner.pick_random_item(config.tier_weights, pool)
		if rolled != null:
			items.push_back(rolled)
			pool.erase(rolled)
