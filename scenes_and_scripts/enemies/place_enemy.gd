class_name PlacedEnemy
extends CharacterBody2D

@export var action_pool: Array [EnemyActions]
@export var action_timer: float
@export var is_blocker: bool
var timer: Timer

func _ready()->void:
	if is_blocker: Signalbus.blocker_added.emit(self)
	var duped: Array[EnemyActions] = []
	for action in action_pool:
		duped.append(action.duplicate(true))
	action_pool = duped
	if timer == null:
		timer = Timer.new()
		self.add_child(timer)
	timer.timeout.connect(pick_action)
	timer.wait_time = action_timer
	start_action_timer()

func die()->void:
	if is_blocker: Signalbus.blocker_removed.emit(self)

func pick_action()->void:
	print("pick action entered")
	if !action_pool.is_empty():
		var action = action_pool.pick_random()
		action.execute_action(self)
		if is_blocker:
			if action.action_type == action.ActionTypes.Move: Signalbus.blocker_moved.emit(self)
		timer.wait_time = action_timer

func get_edge():#called from paddle 
	#check if left or right of paddle
	#use position +/- half of width to get edge
	#return edge
	pass

func start_action_timer()->void:
	timer.wait_time = action_timer
	timer.start()
	
