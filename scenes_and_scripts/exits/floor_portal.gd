class_name FloorPortal extends Area2D

func _ready() -> void:
	deactivate()

func activate() -> void:
	visible = true
	input_pickable = true

func deactivate() -> void:
	visible = false
	input_pickable = false

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not input_pickable:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			Signalbus.floor_cleared.emit()
