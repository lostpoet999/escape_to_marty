class_name FloorPortal extends Area2D

signal portal_clicked

## Off = antechamber mode: clicks only emit portal_clicked, never floor_cleared,
## and the memory gate plus its locked-click bark are skipped.
@export var advances_floor: bool = true

var _travel_ready: bool = false

@onready var _visual: PortalVisual = $Visual

func _ready() -> void:
	deactivate()

func activate() -> void:
	visible = true
	input_pickable = true
	set_travel_ready(not GameManager.floor_memories_outstanding())

func show_dormant(pickable: bool = true) -> void:
	visible = true
	input_pickable = pickable
	set_travel_ready(false)

func set_travel_ready(ready: bool) -> void:
	_travel_ready = ready
	_visual.set_dormant(not ready)

func deactivate() -> void:
	visible = false
	input_pickable = false

## Lights up the click-mode cursor on hover (see MouseGestures._is_hover_responsive);
## pickable only after the encounter clears, so the tell matches clickability.
func is_click_responsive() -> bool:
	return input_pickable

func handle_gesture_click() -> void:
	if not input_pickable:
		return
	if not _travel_ready:
		if advances_floor:
			DialogDirector.play(&"floor_portal_locked")
		return
	portal_clicked.emit()
	if advances_floor:
		Signalbus.floor_cleared.emit()
