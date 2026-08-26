class_name InventoryPanel extends MarginContainer

## add a way to get a random item for testing

const BADGE_FONT: FontFile = preload("uid://ce5jk1ok7f4r5") ## PressStart2P
const BADGE_FONT_SIZE: int = 10
const ICON_SIZE: int = 32 ## standard inventory icon dimension; buttons clamp to this so the badge anchors to the icon edge, not the button's padded edge
const SLOT_SIZE: int = ICON_SIZE + 4 ## uniform button footprint: ICON_SIZE plus the rarity stylebox's 2px content margin per side; keeps mixed-size icon art rendering at exactly ICON_SIZE

## banked vouchers are PlayerData counters, not real inventory items — these display-only tickets render them
## as non-removable buttons slotted right after the base-ball anchor (index 1) so a held voucher is always visible.
## each ticket carries the matching payload's drop art as its inventory_icon, so the falling pickup and the slot read the same.
const PICK2_TICKET: BaseItem = preload("uid://cpick2tkt01")
const SHOP_RESTOCK_TICKET: BaseItem = preload("uid://cshoprstkt1")
const TICKET_SLOT_START: int = 1 ## index 0 is the base-ball anchor; tickets follow it

const MEMORY_TROPHY_SLOTS: int = 4
const TROPHY_DIM: Color = Color(0.35, 0.35, 0.35)
const TROPHY_RARITY: BaseItem.RarityType = BaseItem.RarityType.VERY_RARE

const REMOVE_HOLD_SECONDS: float = 1.5

var buttons: Array[Button]

@onready var inv_grid_container: GridContainer = %InventoryGrid
@onready var core_grid_container: GridContainer = %CoreGrid
@onready var trophy_row: HBoxContainer = %TrophyRow
@onready var remove_hold_prompt: Control = %RemoveHoldPrompt
@onready var remove_hold_name: Label = %RemoveHoldPrompt/ItemName
@onready var remove_hold_bar: ProgressBar = %RemoveHoldPrompt/Bar

var _hold_tween: Tween
var _hold_button: Button

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
			if not item is BaseItem:
				return true
			var base: BaseItem = item as BaseItem
			return base.trophy_floor <= 0 and not trophy_paths.has(base.resource_path)
	)

func populate_trophies() -> void:
	for child: Node in trophy_row.get_children():
		child.queue_free()
	for floor_index: int in range(1, MEMORY_TROPHY_SLOTS + 1):
		trophy_row.add_child(_make_trophy_slot(floor_index))

func _trophy_item_for_floor(floor_index: int) -> BaseItem:
	var inventory: PlayerInventory = PlayerInventory.get_instance()
	for entry: Variant in inventory.get_items() + inventory.get_core_items():
		var held: BaseItem = entry as BaseItem
		if held != null and held.trophy_floor == floor_index:
			return held
	var saved_path: String = SaveProgression.memory_trophy_path(floor_index)
	if saved_path == "":
		return null
	return load(saved_path) as BaseItem

func _make_trophy_slot(floor_index: int) -> Control:
	var trophy: BaseItem = _trophy_item_for_floor(floor_index)
	if trophy == null:
		var number: Label = Label.new()
		number.text = str(floor_index)
		number.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.modulate = TROPHY_DIM
		return number
	var button: RarityTooltipButton = RarityTooltipButton.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	button.expand_icon = true
	button.icon = trophy.inventory_icon if trophy.inventory_icon else PlayerInventory.PLACEHOLDER_TEX
	button.tooltip_text = get_tooltip_for_item(trophy, TROPHY_RARITY)
	button.set_meta(&"Item", trophy)
	button.set_meta(&"click_pickable", true)
	BaseItem.style_button_with_rarity(button, TROPHY_RARITY, 2, 4, 2.0)
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
	slot = _add_ticket(PICK2_TICKET, PlayerData.pick2_vouchers, slot)
	slot = _add_ticket(SHOP_RESTOCK_TICKET, PlayerData.shop_restock_vouchers, slot)

func _add_ticket(ticket: BaseItem, count: int, slot: int) -> int:
	if count <= 0:
		return slot
	var button: Button = init_button_for(ticket)
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
	button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	button.expand_icon = true
	button.icon = icon
	button.tooltip_text = get_tooltip_for_item(item)
	button.set_meta(&"Item", item) ## store the variant
	button.set_meta(&"click_pickable", true)

	button.flat = true ## change me if you decide to use a theme
	if item is BaseItem:
		BaseItem.style_button_with_rarity(button, item.rarity, 2, 4, 2.0, item is BallActive or item is PaddleActive, item.emphasis_color)

	## essential items (basic ball, single-slot bounce) can't be clicked away — skip the use hook
	if item.removable:
		button.button_down.connect(_on_remove_hold_started.bind(button))
		button.button_up.connect(_cancel_remove_hold)
	buttons.push_back(button)
	return button

func get_tooltip_for_item(item: Variant, rarity_override: int = -1) -> String:
	if not item is BaseItem:
		return ""
	var rarity: BaseItem.RarityType = item.rarity if rarity_override < 0 else rarity_override as BaseItem.RarityType
	var title_color: String = BaseItem.rarity_color(rarity).to_html(false)
	var header: String = "[color=#%s]%s (%s):[/color]" % [title_color, item.powerup_name, BaseItem.rarity_label(rarity)]
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

func _on_remove_hold_started(button: Button) -> void:
	_cancel_remove_hold()
	_hold_button = button
	remove_hold_bar.value = 0.0
	var item: BaseItem = button.get_meta(&"Item") as BaseItem
	remove_hold_name.text = item.powerup_name
	remove_hold_name.add_theme_color_override(&"font_color", BaseItem.rarity_color(item.rarity))
	remove_hold_prompt.visible = true
	_hold_tween = create_tween()
	_hold_tween.tween_property(remove_hold_bar, "value", 1.0, REMOVE_HOLD_SECONDS)
	_hold_tween.tween_callback(_finish_remove_hold)

func _cancel_remove_hold() -> void:
	if _hold_tween != null and _hold_tween.is_valid():
		_hold_tween.kill()
	_hold_tween = null
	_hold_button = null
	remove_hold_prompt.visible = false

func _finish_remove_hold() -> void:
	var button: Button = _hold_button
	_hold_tween = null
	_hold_button = null
	remove_hold_prompt.visible = false
	if button == null or not is_instance_valid(button):
		return
	PlayerInventory.get_instance().use_item(button.get_meta(&"Item"))
