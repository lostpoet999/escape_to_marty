class_name InventoryPanel extends MarginContainer

## add a way to get a random item for testing

const PLACEHOLDER_TEX: Texture2D = preload("uid://cn44s8tnj8dg2")

var buttons: Array[Button]

@onready var grid_container: GridContainer = %GridContainer

func _ready() -> void:
	Signalbus.inventory_changed.connect(repopulate_inventory)
	repopulate_inventory()
	
func repopulate_inventory() -> void:
	clear_buttons()
	var items: Array = PlayerInventory.get_instance().get_items()
	for item: Variant in items:
		var new_button: Button = init_button_for(item)
		grid_container.add_child(new_button)

func init_button_for(item: Variant) -> Button:
	var icon: Texture2D = get_icon_for_item(item)
	var button: Button = Button.new()
	button.icon = icon
	button.tooltip_text = item.powerup_name
	button.set_meta(&"Item", item) ## store the variant
	
	button.flat = true ## change me if you decide to use a theme
	
	button.pressed.connect(_on_button_pressed.bind(button))
	buttons.push_back(button)
	return button

func get_icon_for_item(item: Variant) -> Texture2D:
	if "inventory_icon" in item:
		if item.inventory_icon:
			return item.inventory_icon
	return PLACEHOLDER_TEX

func clear_buttons() -> void:
	for button: Button in buttons:
		button.queue_free()
		
func _on_button_pressed(button: Button) -> void:
	var item: Variant = button.get_meta(&"Item")
	PlayerInventory.get_instance().use_item(item)
