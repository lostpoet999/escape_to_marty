class_name ShopGrid extends GridContainer
@onready var shop_grid: GridContainer = $"."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	populate_shop_panel()
	Signalbus.db_panel_closed.connect(populate_shop_panel)

func clear_shop_btns():
	for btn in shop_grid.get_children():
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
	return button

func buy_item(item, button):
	PlayerData.inventory.add_item(item)
	PlayerData.stars_collected -= item.cost
	Signalbus.stars_updated.emit()
	button.queue_free()
	

func populate_shop_panel()->void:
	clear_shop_btns()
	for i:int in GameManager.floor_data.shop_items:
		var item = ItemSpawner.pick_random_item()
		var btn: Button = make_item_button(item)
		if item.cost > PlayerData.stars_collected: btn.disabled = true
		shop_grid.add_child(btn)
