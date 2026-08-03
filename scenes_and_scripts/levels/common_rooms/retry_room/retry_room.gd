extends RoomBase

var _panel: FreeItemPanel

@onready var _portal: FloorPortal = $PlayArea/FloorPortal

func _ready() -> void:
	await super()
	paddle.set_paddle_hidden(true, true)
	_portal.portal_clicked.connect(_on_portal_clicked)
	_panel = _find_free_item_panel()
	if _panel == null:
		set_process(false)
		_show_portal()
		return
	var title: Label = _panel.get_node("VBoxContainer/PanelLabel") as Label
	title.text = "You must pick one."
	_panel.footer_label.hide()

func _process(delta: float) -> void:
	super(delta)
	if room_state == null or room_state.loot_items_data == null:
		return
	if room_state.loot_items_data.base_pick_used:
		set_process(false)
		if is_instance_valid(_panel):
			_panel.queue_free()
		_show_portal()

func _find_free_item_panel() -> FreeItemPanel:
	for child: Node in $PlayArea.get_children():
		if child is FreeItemPanel:
			return child
	return null

func _show_portal() -> void:
	_portal.show_dormant()
	_portal.set_travel_ready(true)

func _on_portal_clicked() -> void:
	GameManager.write_run_checkpoint()
	GameManager.exit_retry_room()
