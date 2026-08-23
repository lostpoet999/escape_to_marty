class_name ShopPanel extends ItemSelectorPanelBase

signal closed

const SLOT_REROLL_COST: int = 100
const SLOT_REROLL_SIZE: Vector2 = Vector2(112, 30)
const SLOT_REROLL_DESCRIPTION: String = "Reroll: swap this item for another, %d gold"

@onready var reroll_button: Button = $VBoxContainer/Footer/RerollButton
@onready var reroll_count_label: Label = $VBoxContainer/Footer/RerollCountLabel
@onready var exit_button: Button = $VBoxContainer/Footer/ExitShopButton

var slots: Array[Control] = []
var slot_reroll_buttons: Array[Button] = []
var default_description_text: String = ""

func _ready() -> void:
	_style_item_description()
	_configure_grid()
	default_description_text = item_description_label.text
	for child: Node in item_grid.get_children():
		if child is Control:
			slots.append(child)
	for i: int in slots.size():
		_buy_button(i).pressed.connect(_on_buy_pressed.bind(i))
		_buy_button(i).set_meta(&"click_pickable", true)
		ApolloPalette.style_menu_button(_buy_button(i))
		_item_button(i).mouse_entered.connect(_on_mouse_entered_item.bind(i))
		_buy_button(i).mouse_entered.connect(_on_mouse_entered_item.bind(i))
		slots[i].mouse_entered.connect(_on_mouse_entered_item.bind(i))
		_item_button(i).mouse_exited.connect(_on_mouse_exited_item)
		_buy_button(i).mouse_exited.connect(_on_mouse_exited_item)
		slots[i].mouse_exited.connect(_on_mouse_exited_item)
		slot_reroll_buttons.append(_make_slot_reroll_button(i))
	reroll_button.text = "Restock All"
	reroll_button.pressed.connect(_on_reroll_pressed)
	reroll_button.set_meta(&"click_pickable", true)
	ApolloPalette.style_menu_button(reroll_button)
	exit_button.pressed.connect(_on_exit_pressed)
	exit_button.set_meta(&"click_pickable", true)
	ApolloPalette.style_menu_button(exit_button)
	_refresh()
	_play_open_juice()

func _make_slot_reroll_button(i: int) -> Button:
	var button: Button = Button.new()
	button.name = "RerollButton"
	button.custom_minimum_size = SLOT_REROLL_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.text = "Reroll %dG" % SLOT_REROLL_COST
	slots[i].add_child(button)
	ApolloPalette.style_small_menu_button(button)
	button.pressed.connect(_on_slot_reroll_pressed.bind(i))
	button.mouse_entered.connect(_on_mouse_entered_slot_reroll)
	button.mouse_exited.connect(_on_mouse_exited_item)
	return button

func _item_button(i: int) -> Button:
	return slots[i].get_node("ItemButton") as Button

func _buy_button(i: int) -> Button:
	return slots[i].get_node("BuyButton") as Button

func _cost_label(i: int) -> Label:
	return slots[i].get_node("CostLabel") as Label

func _refresh() -> void:
	if loot_items_data.shop_exhausted():
		visible = false
		closed.emit()
		queue_free()
		return
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
			BaseItem.style_button_with_rarity(icon_btn, item.rarity, 4, 10, 8.0, item is BallActive or item is PaddleActive, item.emphasis_color)
			_cost_label(i).text = "%dG" % item.cost
			var affordable: bool = item.cost <= PlayerData.gold_collected
			_buy_button(i).disabled = not affordable
			icon_btn.set_meta(&"click_pickable", affordable)
			_update_slot_reroll(i)
		else:
			slots[i].visible = false
	_update_reroll()

func _update_slot_reroll(i: int) -> void:
	if i >= slot_reroll_buttons.size():
		return
	var can_reroll: bool = SLOT_REROLL_COST <= PlayerData.gold_collected and not loot_items_data.pool.is_empty()
	slot_reroll_buttons[i].disabled = not can_reroll
	slot_reroll_buttons[i].set_meta(&"click_pickable", can_reroll)

func _on_buy_pressed(i: int) -> void:
	if i >= loot_items_data.items.size():
		return
	var item: BaseItem = loot_items_data.items[i]
	var price: int = item.cost
	if price > PlayerData.gold_collected:
		return
	if not await PlayerData.inventory.add_item(item):
		return
	PlayerData.change_player_gold(-price)
	loot_items_data.items.erase(item)
	_refresh()

func _on_slot_reroll_pressed(i: int) -> void:
	if i >= loot_items_data.items.size():
		return
	if SLOT_REROLL_COST > PlayerData.gold_collected:
		return
	if not loot_items_data.reroll_slot(i):
		return
	PlayerData.change_player_gold(-SLOT_REROLL_COST)
	_refresh()
	_on_mouse_entered_item(i)

func _on_reroll_pressed() -> void:
	if not PlayerData.consume_shop_restock_voucher():
		return
	loot_items_data.generate_item_box()
	_refresh()

func _on_exit_pressed() -> void:
	closed.emit()
	queue_free()

func _update_reroll() -> void:
	reroll_count_label.text = "x%d" % PlayerData.shop_restock_vouchers
	reroll_button.disabled = PlayerData.shop_restock_vouchers <= 0

func _on_mouse_entered_item(i: int) -> void:
	if i >= loot_items_data.items.size():
		return
	_show_item_description(loot_items_data.items[i])

func _on_mouse_entered_slot_reroll() -> void:
	item_description_label.text = "[center]%s[/center]" % (SLOT_REROLL_DESCRIPTION % SLOT_REROLL_COST)

func _on_mouse_exited_item() -> void:
	item_description_label.text = default_description_text
