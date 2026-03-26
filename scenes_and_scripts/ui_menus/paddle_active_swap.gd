extends Control
@onready var old_item_btn: Button = $OldItem
@onready var new_item_btn: Button = $NewItem

@onready var old_active_ref: PaddleActive
@onready var new_active_ref: PaddleActive

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	Signalbus.paddle_active_swap_needed.connect(_on_swap_needed)


func _on_swap_needed(old_item:PaddleActive, new_item: PaddleActive)->void:
	old_active_ref = old_item
	new_active_ref = new_item
	process_mode = Node.PROCESS_MODE_ALWAYS
	if !get_tree().paused:
		get_tree().paused
	setup_buttons()
	show()

func setup_buttons()->void:
	#old button
	if "inventory_icon" in old_active_ref:
		old_item_btn.icon = old_active_ref.inventory_icon
	else:
		old_item_btn.icon = PlayerData.inventory.PLACEHOLDER_TEX
	old_item_btn.tooltip_text = old_active_ref.powerup_name
	
	#new button
	if "inventory_icon" in new_active_ref:
		new_item_btn.icon = new_active_ref.inventory_icon
	else:
		new_item_btn.icon = PlayerData.inventory.PLACEHOLDER_TEX	
	new_item_btn.tooltip_text = new_active_ref.powerup_name

func _on_old_item_pressed() -> void:
	hide()
	get_tree().paused = !get_tree().paused # no change


func _on_new_item_pressed() -> void:
	hide()
	get_tree().paused = !get_tree().paused
	Signalbus.paddle_swap_resolved.emit(new_active_ref)
