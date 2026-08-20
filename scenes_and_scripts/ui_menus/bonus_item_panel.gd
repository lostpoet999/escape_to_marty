class_name BonusItemPanel extends ItemSelectorPanelBase

signal item_taken(item: BaseItem)

func _ready() -> void:
	_style_item_description()
	_configure_grid()
	_refresh()
	_play_open_juice()

func _refresh() -> void:
	_clear_slots()
	for item: BaseItem in loot_items_data.items:
		var button: Button = _make_slot_button(item)
		button.pressed.connect(_on_slot_pressed.bind(item))
		button.mouse_entered.connect(_show_item_description.bind(item))
		item_grid.add_child(button)

func _on_slot_pressed(item: BaseItem) -> void:
	if not await PlayerData.inventory.add_item(item):
		return
	loot_items_data.items.erase(item)
	item_taken.emit(item)
	_refresh()
