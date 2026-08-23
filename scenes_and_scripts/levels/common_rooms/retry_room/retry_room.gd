extends RoomBase

var _panel: FreeItemPanel

@onready var _portal: FloorPortal = $PlayArea/FloorPortal

func _ready() -> void:
	await super()
	paddle.set_paddle_hidden(true, true)
	_portal.portal_clicked.connect(_on_portal_clicked)
	var kiosk: RoomKiosk = _find_kiosk()
	if SettingsManager.difficulty == 2 and kiosk != null:
		kiosk.queue_free()
		kiosk = null
	if kiosk == null:
		set_process(false)
		_show_portal()

func _process(delta: float) -> void:
	super(delta)
	if room_state == null or room_state.loot_items_data == null:
		return
	if room_state.loot_items_data.base_pick_used:
		set_process(false)
		if is_instance_valid(_panel):
			_panel.queue_free()
		_show_portal()

func _on_free_item_kiosk_activated(kiosk: RoomKiosk) -> void:
	super(kiosk)
	_panel = _find_free_item_panel()
	if _panel == null:
		return
	var title: Label = _panel.get_node("VBoxContainer/PanelLabel") as Label
	title.text = "You must pick one."
	_panel.footer_label.hide()

func _find_kiosk() -> RoomKiosk:
	for child: Node in $PlayArea.get_children():
		if child is RoomKiosk:
			return child
	return null

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
