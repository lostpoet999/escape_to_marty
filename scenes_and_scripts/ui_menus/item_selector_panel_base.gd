class_name ItemSelectorPanelBase extends Control

const SLOT_MIN_SIZE: Vector2 = Vector2(200, 200)
const SLOT_SEPARATION: int = 140
const DESCRIPTION_SETTINGS: LabelSettings = preload("res://label_settings_and_fonts/yellow_40.tres")

@onready var item_grid: GridContainer = $VBoxContainer/ItemGrid
@onready var item_description_label: RichTextLabel = $VBoxContainer/ItemDescription

var loot_items_data: LootItemsData

func setup(data: LootItemsData) -> void:
	loot_items_data = data

func _style_item_description() -> void:
	item_description_label.add_theme_font_override(&"normal_font", DESCRIPTION_SETTINGS.font)
	item_description_label.add_theme_font_size_override(&"normal_font_size", DESCRIPTION_SETTINGS.font_size)
	item_description_label.add_theme_color_override(&"default_color", DESCRIPTION_SETTINGS.font_color)

func _show_item_description(item: BaseItem) -> void:
	var title_color: String = BaseItem.rarity_color(item.rarity).to_html(false)
	var rarity_name: String = BaseItem.rarity_label(item.rarity)
	item_description_label.text = "[center][color=#%s]%s (%s):[/color] %s[/center]" % [title_color, item.powerup_name, rarity_name, item.shop_description]

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
	BaseItem.style_button_with_rarity(button, item.rarity)
	return button

func _icon_for(item: BaseItem) -> Texture2D:
	if item and item.inventory_icon:
		return item.inventory_icon
	return PlayerData.inventory.PLACEHOLDER_TEX
