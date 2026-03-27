extends Control

@onready var item_pool_panel: GridContainer = $Panel/HBoxContainer/ItemSpawning/VBoxContainer/ItemPoolPanel
@onready var tracked_variables: VBoxContainer = $Panel/HBoxContainer/TrackedVariables/VBoxContainer/TrackedVariables

@onready var items = ItemSpawner.item_pool_data.item_pool
var old_state: GameManager.GameState
var tracked: Array = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	old_state = GameManager.current_state

func track(label: String, obj: Object, variable: String, enum_map: Dictionary = {}) -> void:
	tracked.append({label = label, obj = obj, variable = variable, enum_map = enum_map})

func populate_tracked_variables() -> void:
	for child in tracked_variables.get_children():
		child.queue_free()
	for entry in tracked:
		if not is_instance_valid(entry.obj): continue
		var value = entry.obj.get(entry.variable)
		var display: String
		if not entry.enum_map.is_empty():
			display = entry.enum_map.find_key(value)
		else:
			display = str(value)
		var lbl := Label.new()
		lbl.text = "%s: %s" % [entry.label, display]
		tracked_variables.add_child(lbl)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("activate_exits"):
		_on_enable_exits_btn_pressed()
	if event.is_action_pressed("toggle_debug_panel"):
		if visible:
			hide()
			GameManager.change_state(old_state)	
		else:
			old_state = GameManager.current_state
			show()
			GameManager.change_state(GameManager.GameState.DEBUG_PANEL)
			populate_item_pool_panel()
			populate_tracked_variables()

func make_item_button(item)-> Button:
	var icon: Texture2D = get_icon_for_item(item)
	var button: Button = Button.new()
	button.icon = icon
	button.tooltip_text = item.powerup_name
	button.set_meta(&"Item", item) ## store the variant
	
	button.flat = true ## change me if you decide to use a theme
	
	button.pressed.connect(func() -> void:PlayerData.inventory.add_item(item))	
	return button

func clear_buttons() -> void:
	for button in item_pool_panel.get_children():
		if is_instance_valid(button):
			button.queue_free()

func get_icon_for_item(item: Variant) -> Texture2D:
	if "inventory_icon" in item:
		if item.inventory_icon:
			return item.inventory_icon
	return PlayerData.inventory.PLACEHOLDER_TEX

func populate_item_pool_panel()->void:
	clear_buttons()
	for item in items:
		var btn: Button = make_item_button(item)
		item_pool_panel.add_child(btn)


func _on_enable_exits_btn_pressed() -> void:
	Signalbus.level_cleared.emit()
	old_state = GameManager.GameState.LEVEL_CLEARED
	GameManager.change_state(old_state)
	hide()


func _on_give_stars_btn_pressed() -> void:
	PlayerData.change_player_stars(100)
