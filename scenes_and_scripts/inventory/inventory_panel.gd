class_name InventoryPanel extends MarginContainer

## add a way to get a random item for testing

const BADGE_FONT: FontFile = preload("uid://ce5jk1ok7f4r5") ## PressStart2P
const BADGE_FONT_SIZE: int = 10
const ICON_SIZE: int = 32 ## standard inventory icon dimension; buttons clamp to this so the badge anchors to the icon edge, not the button's padded edge

## banked vouchers are PlayerData counters, not real inventory items — these display-only tickets render them
## as non-removable buttons slotted right after the base-ball anchor (index 1) so a held voucher is always visible.
## tint distinguishes them while real art is pending; mirrors each payload's drop_modulate.
const PICK2_TICKET: BaseItem = preload("uid://cpick2tkt01")
const SHOP_RESTOCK_TICKET: BaseItem = preload("uid://cshoprstkt1")
const PICK2_TINT: Color = Color(0.5, 1, 0.5)
const SHOP_RESTOCK_TINT: Color = Color(1, 0.7, 0.3)
const TICKET_SLOT_START: int = 1 ## index 0 is the base-ball anchor; tickets follow it

const MEMORY_TROPHY_SLOTS: int = 5
const TROPHY_DIM: Color = Color(0.35, 0.35, 0.35)

var buttons: Array[Button]

@onready var inv_grid_container: GridContainer = %InventoryGrid
@onready var core_grid_container: GridContainer = %CoreGrid
@onready var trophy_row: HBoxContainer = %TrophyRow

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Signalbus.inventory_changed.connect(repopulate_inventory)
	Signalbus.pick2_vouchers_changed.connect(_on_vouchers_changed)
	Signalbus.shop_restock_vouchers_changed.connect(_on_vouchers_changed)
	repopulate_inventory()

## memory trophies stay in the inventory only to carry their capability (e.g. minimap),
## so surface them in the dedicated trophy row and keep them out of the standard grid.
func _trophy_paths() -> Dictionary:
	var paths: Dictionary = {}
	for floor_index: int in range(1, MEMORY_TROPHY_SLOTS + 1):
		var path: String = SaveProgression.memory_trophy_path(floor_index)
		if path != "":
			paths[path] = true
	return paths

func _non_trophy_items() -> Array:
	var trophy_paths: Dictionary = _trophy_paths()
	return PlayerInventory.get_instance().get_items().filter(
		func(item: Variant) -> bool:
			return not (item is BaseItem and trophy_paths.has(item.resource_path))
	)

func populate_trophies() -> void:
	for child: Node in trophy_row.get_children():
		child.queue_free()
	for floor_index: int in range(1, MEMORY_TROPHY_SLOTS + 1):
		var cell: CenterContainer = CenterContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(_make_trophy_slot(floor_index))
		trophy_row.add_child(cell)

func _make_trophy_slot(floor_index: int) -> Control:
	var path: String = SaveProgression.memory_trophy_path(floor_index)
	if path == "":
		var number: Label = Label.new()
		number.text = str(floor_index)
		number.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.modulate = TROPHY_DIM
		return number
	var item: BaseItem = load(path) as BaseItem
	var button: Button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	button.icon = item.inventory_icon if item and item.inventory_icon else PlayerInventory.PLACEHOLDER_TEX
	button.tooltip_text = item.powerup_name if item else ""
	if item:
		BaseItem.style_button_with_rarity(button, item.rarity, 2, 4, 2.0)
	return button

func _on_vouchers_changed(_count: int) -> void:
	repopulate_inventory()

func repopulate_inventory() -> void:
	clear_buttons()
	populate_trophies()
	populate_grid(inv_grid_container, _non_trophy_items())
	populate_grid(core_grid_container, PlayerData.inventory.get_core_items())
	add_voucher_tickets()

func add_voucher_tickets() -> void:
	var slot: int = TICKET_SLOT_START
	slot = _add_ticket(PICK2_TICKET, PlayerData.pick2_vouchers, PICK2_TINT, slot)
	slot = _add_ticket(SHOP_RESTOCK_TICKET, PlayerData.shop_restock_vouchers, SHOP_RESTOCK_TINT, slot)

func _add_ticket(ticket: BaseItem, count: int, tint: Color, slot: int) -> int:
	if count <= 0:
		return slot
	var button: Button = init_button_for(ticket)
	button.modulate = tint
	if count > 1:
		add_count_badge(button, count)
	inv_grid_container.add_child(button)
	inv_grid_container.move_child(button, slot)
	return slot + 1

func populate_grid(grid: GridContainer, items: Array) -> void:
	## group duplicates so a stack of 3 shows as one button with "x3" instead of three buttons
	var counts: Dictionary = {}
	for item: Variant in items:
		if counts.has(item):
			counts[item] += 1
		else:
			counts[item] = 1
	for item: Variant in counts:
		var new_button: Button = init_button_for(item)
		if counts[item] > 1:
			add_count_badge(new_button, counts[item])
		grid.add_child(new_button)

func init_button_for(item: Variant) -> Button:
	var icon: Texture2D = get_icon_for_item(item)
	var button: Button = RarityTooltipButton.new()
	button.icon = icon
	button.tooltip_text = get_tooltip_for_item(item)
	button.set_meta(&"Item", item) ## store the variant

	button.flat = true ## change me if you decide to use a theme
	if item is BaseItem:
		BaseItem.style_button_with_rarity(button, item.rarity, 2, 4, 2.0)

	## essential items (basic ball, single-slot bounce) can't be clicked away — skip the use hook
	if item.removable:
		button.pressed.connect(_on_button_pressed.bind(button))
	buttons.push_back(button)
	return button

func get_tooltip_for_item(item: Variant) -> String:
	if not item is BaseItem:
		return ""
	var title_color: String = BaseItem.rarity_color(item.rarity).to_html(false)
	var header: String = "[color=#%s]%s (%s):[/color]" % [title_color, item.powerup_name, BaseItem.rarity_label(item.rarity)]
	## the basic ball is the one non-removable ball passive — report live ball damage on hover
	if item is BallPassive and not item.removable:
		var dmg: float = PlayerInventory.get_instance().get_ball_damage()
		return "%s %s\nBall Damage: %s" % [header, item.shop_description, snappedf(dmg, 0.01)]
	return "%s %s" % [header, item.shop_description]

func add_count_badge(button: Button, count: int) -> void:
	var label: Label = Label.new()
	label.text = "x%d" % count
	label.add_theme_font_override(&"font", BADGE_FONT)
	label.add_theme_font_size_override(&"font_size", BADGE_FONT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	## anchor at button center, then shift down so the label sits just below the icon
	## (icon is 32x32 centered in the button; badge top edge lands on icon's bottom edge)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	var vertical_shift: float = ICON_SIZE / 2.0 + BADGE_FONT_SIZE / 2.0
	label.offset_top = vertical_shift
	label.offset_bottom = vertical_shift

	button.add_child(label)

func get_icon_for_item(item: Variant) -> Texture2D:
	if "inventory_icon" in item:
		if item.inventory_icon:
			return item.inventory_icon
	return PlayerData.inventory.PLACEHOLDER_TEX

func clear_buttons() -> void:
	for button: Button in buttons:
		if is_instance_valid(button):
			button.queue_free()

func _on_button_pressed(button: Button) -> void:
	var item: BaseItem = button.get_meta(&"Item")
	PlayerInventory.get_instance().use_item(item)
