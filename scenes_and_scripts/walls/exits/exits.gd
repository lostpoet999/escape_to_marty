extends Node2D

@onready var room_ref = GameManager.room_data_for_floor #dictionary of room entries
@onready var walls_no_door: Node2D = $walls_no_door
@onready var exit_barrier_closed: ColorRect = $ExitBarrier_closed
@onready var exit_barrier_open: ColorRect = $ExitBarrier_open

var room_cleared: bool = false

func _ready():	
	Signalbus.level_cleared.connect(enable_exits)	
	reconcile_exits()

func reconcile_exits():	
	match self.name:
		"NorthExit":
			if room_ref[GameManager.current_room_id].north_exit != "" and room_cleared:
				show_open_door()
			elif room_ref[GameManager.current_room_id].north_exit != "" and !room_cleared:
				show_closed_door()
			elif room_ref[GameManager.current_room_id].north_exit == "":
				show_walls()
		"SouthExit":
			if room_ref[GameManager.current_room_id].south_exit != "" and room_cleared:
				show_open_door()
			elif room_ref[GameManager.current_room_id].south_exit != "" and !room_cleared:
				show_closed_door()
			elif room_ref[GameManager.current_room_id].south_exit == "":
				show_walls()
		"EastExit":
			if room_ref[GameManager.current_room_id].east_exit != "" and room_cleared:
				show_open_door()
			elif room_ref[GameManager.current_room_id].east_exit != "" and !room_cleared:
				show_closed_door()
			elif room_ref[GameManager.current_room_id].east_exit == "":
				show_walls()
		"WestExit":
			if room_ref[GameManager.current_room_id].west_exit != "" and room_cleared:
				show_open_door()
			elif room_ref[GameManager.current_room_id].west_exit != "" and !room_cleared:
				show_closed_door()
			elif room_ref[GameManager.current_room_id].west_exit == "":
				show_walls()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_exit_clicked()

func _on_exit_clicked():
	if !room_cleared:
		return
	
	var target_id: String = ""
	var current_entry = room_ref[GameManager.current_room_id]
	
	match self.name:
		"NorthExit":
			target_id = current_entry.north_exit
		"SouthExit":
			target_id = current_entry.south_exit
		"EastExit":
			target_id = current_entry.east_exit
		"WestExit":
			target_id = current_entry.west_exit
	
	if target_id == "":
		return
	
	var target_room = room_ref[target_id]
	GameManager.current_room_id = target_id
	GameManager.scene_ref = target_room.room_scene
	GameManager.change_state(GameManager.GameState.BALL_ON_PADDLE)
	get_tree().change_scene_to_packed(target_room.room_scene)

func show_closed_door():
	walls_no_door.hide()
	exit_barrier_closed.show()
	exit_barrier_open.hide()
	self.input_pickable = false
	
func show_open_door():
	walls_no_door.hide()
	exit_barrier_closed.hide()
	exit_barrier_open.show()
	self.input_pickable = true
		
func show_walls():
	walls_no_door.show()	
	exit_barrier_closed.hide()
	exit_barrier_open.hide()
	self.input_pickable = false

func enable_exits(): 	
	room_cleared = true
	reconcile_exits()
