class_name ShopPanel extends ItemSelectorPanelBase

@onready var reroll_button: Button = $VBoxContainer/Footer/RerollButton
@onready var reroll_count_label: Label = $VBoxContainer/Footer/RerollCountLabel

var slots: Array[Control] = []

func _ready() -> void:
	_style_item_description()
	for child: Node in item_grid.get_children():
		if child is Control:
			slots.append(child)
	for i: int in slots.size():
		_buy_button(i).pressed.connect(_on_buy_pressed.bind(i))
		_item_button(i).mouse_entered.connect(_on_mouse_entered_item.bind(i))
		_buy_button(i).mouse_entered.connect(_on_mouse_entered_item.bind(i))
		slots[i].mouse_entered.connect(_on_mouse_entered_item.bind(i))
	reroll_button.pressed.connect(_on_reroll_pressed)
	_refresh()

func _item_button(i: int) -> Button:
	return slots[i].get_node("ItemButton") as Button

func _buy_button(i: int) -> Button:
	return slots[i].get_node("BuyButton") as Button

func _cost_label(i: int) -> Label:
	return slots[i].get_node("CostLabel") as Label

func _refresh() -> void:
	for i: int in slots.size():
		if i < loot_items_data.items.size():
			var item: BaseItem = loot_items_data.items[i]
			slots[i].visible = true
			var icon_btn: Button = _item_button(i)
			icon_btn.icon = _icon_for(item)
			icon_btn.expand_icon = true
			icon_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			icon_btn.tooltip_text = item.powerup_name
			BaseItem.style_button_with_rarity(icon_btn, item.rarity)
			_cost_label(i).text = "%d" % item.cost
			_buy_button(i).disabled = item.cost > PlayerData.stars_collected
		else:
			slots[i].visible = false
	_update_reroll()

func _on_buy_pressed(i: int) -> void:
	if i >= loot_items_data.items.size():
		return
	var item: BaseItem = loot_items_data.items[i]
	if item.cost > PlayerData.stars_collected:
		return
	PlayerData.change_player_stars(-item.cost)
	PlayerData.inventory.add_item(item)
	loot_items_data.items.erase(item)
	_refresh()

# restock + reroll: a voucher regenerates the full fresh shelf (never a star cost)
func _on_reroll_pressed() -> void:
	if not PlayerData.consume_shop_restock_voucher():
		return
	loot_items_data.generate_item_box()
	_refresh()

func _update_reroll() -> void:
	reroll_count_label.text = "x%d" % PlayerData.shop_restock_vouchers
	reroll_button.disabled = PlayerData.shop_restock_vouchers <= 0

func _on_mouse_entered_item(i: int) -> void:
	_show_item_description(loot_items_data.items[i])
