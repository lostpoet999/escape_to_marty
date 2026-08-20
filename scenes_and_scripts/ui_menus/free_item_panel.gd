class_name FreeItemPanel extends ItemSelectorPanelBase

signal closed

@onready var footer_label: Label = $VBoxContainer/Footer
@onready var exit_button: Button = $VBoxContainer/ExitButton

func _ready() -> void:
	_style_item_description()
	_configure_grid()
	exit_button.pressed.connect(_on_exit_pressed)
	exit_button.set_meta(&"click_pickable", true)
	ApolloPalette.style_menu_button(exit_button)
	_refresh()
	_play_open_juice()

func _on_exit_pressed() -> void:
	closed.emit()
	queue_free()

func _picks_available() -> int:
	return loot_items_data.free_picks_available()

func _refresh() -> void:
	if loot_items_data.free_pick_exhausted():
		closed.emit()
		queue_free()
		return
	_clear_slots()
	var can_pick: bool = _picks_available() > 0
	for item: BaseItem in loot_items_data.items:
		var button: Button = _make_slot_button(item)
		button.disabled = not can_pick
		button.pressed.connect(_on_slot_pressed.bind(item))
		button.mouse_entered.connect(_show_item_description.bind(item))
		item_grid.add_child(button)
	_update_footer()

func _on_slot_pressed(item: BaseItem) -> void:
	if _picks_available() <= 0:
		return
	if not await PlayerData.inventory.add_item(item):
		return
	if loot_items_data.base_pick_used:
		if not PlayerData.consume_pick2_voucher():
			return
	else:
		loot_items_data.base_pick_used = true
	loot_items_data.items.erase(item)
	_refresh()

func _update_footer() -> void:
	var free_pick: int = 0 if loot_items_data.base_pick_used else 1
	footer_label.text = "x%d free pick + %d pick tickets" % [free_pick, PlayerData.pick2_vouchers]
	footer_label.visible = true
