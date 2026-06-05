class_name FreeItemPanel extends ItemSelectorPanelBase

@onready var footer_label: Label = $VBoxContainer/Footer

func _ready() -> void:
	_configure_grid()
	_refresh()

# one free pick per room (spent on the first take), plus one extra pick per banked voucher
func _picks_available() -> int:
	var base_pick: int = 0 if loot_items_data.base_pick_used else 1
	return base_pick + PlayerData.pick2_vouchers

func _refresh() -> void:
	_clear_slots()
	var can_pick: bool = _picks_available() > 0
	for item: BaseItem in loot_items_data.items:
		var button: Button = _make_slot_button(item)
		button.disabled = not can_pick
		button.pressed.connect(_on_slot_pressed.bind(item))
		item_grid.add_child(button)
	_update_footer()

func _on_slot_pressed(item: BaseItem) -> void:
	if _picks_available() <= 0:
		return
	# base pick first; only consume a voucher once the free pick is gone (never wasted)
	if loot_items_data.base_pick_used:
		if not PlayerData.consume_pick2_voucher():
			return
	else:
		loot_items_data.base_pick_used = true
	loot_items_data.items.erase(item)
	PlayerData.inventory.add_item(item)
	_refresh()

func _update_footer() -> void:
	var free_pick: int = 0 if loot_items_data.base_pick_used else 1
	footer_label.text = "x%d free pick + %d pick tickets" % [free_pick, PlayerData.pick2_vouchers]
	footer_label.visible = true
