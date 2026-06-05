class_name ItemSelectorPanelBase extends Control

const SLOT_MIN_SIZE: Vector2 = Vector2(200, 200)
const SLOT_SEPARATION: int = 140

@onready var item_grid: GridContainer = $VBoxContainer/ItemGrid

var loot_items_data: LootItemsData

func setup(data: LootItemsData) -> void:
	loot_items_data = data

func _configure_grid() -> void:
	# hug the buttons' total width and center the group, so it doesn't touch the panel edges
	item_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item_grid.add_theme_constant_override(&"h_separation", SLOT_SEPARATION)
	item_grid.add_theme_constant_override(&"v_separation", SLOT_SEPARATION)

func _clear_slots() -> void:
	for child: Node in item_grid.get_children():
		child.queue_free()

func _make_slot_button(item: BaseItem) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = SLOT_MIN_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.icon = _icon_for(item)
	button.tooltip_text = item.powerup_name
	button.set_meta(&"item", item)
	return button

func _icon_for(item: BaseItem) -> Texture2D:
	if item and item.inventory_icon:
		return item.inventory_icon
	return PlayerData.inventory.PLACEHOLDER_TEX
