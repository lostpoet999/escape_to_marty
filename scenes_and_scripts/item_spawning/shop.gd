class_name ShopGrid extends Node2D
@onready var shop_grid: GridContainer = $ShopGrid

var loot_items_data: LootItemsData
var shop_list: Array[BaseItem]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	populate_shop_panel()
	Signalbus.db_panel_closed.connect(populate_shop_panel)

func clear_shop_btns()->void:
	for btn: Button in shop_grid.get_children():
		btn.queue_free()

func get_icon_for_item(item: Variant) -> Texture2D:
	if "inventory_icon" in item:
		if item.inventory_icon:
			return item.inventory_icon
	return PlayerData.inventory.PLACEHOLDER_TEX

func make_item_button(item: BaseItem)-> Button:
	var icon: Texture2D = get_icon_for_item(item)
	var button: Button = Button.new()
	button.icon = icon
	button.tooltip_text = item.powerup_name
	button.set_meta(&"Item", item) ## store the variant
	
	button.flat = true ## change me if you decide to use a theme
	
	button.pressed.connect(buy_item.bind(item,button))
	if item.cost > PlayerData.stars_collected: button.disabled = true
	return button

func buy_item(item: BaseItem, button: Button)->void:
	PlayerData.inventory.add_item(item)
	loot_items_data.items.erase(item)
	PlayerData.stars_collected -= item.cost
	Signalbus.stars_updated.emit()
	button.queue_free()
	populate_shop_panel()
	

func populate_shop_panel()->void:
	clear_shop_btns()	
	for i:int in loot_items_data.items.size():
		var item: BaseItem = loot_items_data.items[i]
		var btn: Button = make_item_button(item)
		if item.cost > PlayerData.stars_collected: btn.disabled = true
		shop_grid.add_child(btn)
