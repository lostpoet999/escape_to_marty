extends Node2D

@onready var room_ref = GameManager.room_data_for_floor #dictionary of room entries

func _ready():	
	reconcile_exits()

func reconcile_exits():
	print("current_room_id: ", GameManager.current_room_id)
	print("room_ref key: ", room_ref)
	match self.name:
		"NorthExit":
			if room_ref[GameManager.current_room_id].north_exit != "":
				self.hide()
		"SouthExit":
			if room_ref[GameManager.current_room_id].south_exit != "":
				self.hide()
		"EastExit":
			if room_ref[GameManager.current_room_id].east_exit != "":
				self.hide()
		"WestExit":
			if room_ref[GameManager.current_room_id].west_exit != "":
				self.hide()
