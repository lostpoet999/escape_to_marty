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
	if !action_pool.is_empty():
		var action = action_pool.pick_random()
		action.execute_action(self)
		if is_blocker:
			if action.action_type == action.ActionTypes.Move: Signalbus.blocker_moved.emit()
		timer.wait_time = action_timer

func get_edge(paddle: Paddle) -> float:
	var half_width: float = $EnemySprite.texture.get_width() * $EnemySprite.scale.x * scale.x / 2.0
	var paddle_half: float = paddle._get_scaled_half_width()
	var sprite_half: float = $EnemySprite.texture.get_width() * $EnemySprite.scale.x * scale.x / 2.0	
	print("sprite_half: ", sprite_half)
	print("paddle_half: ", paddle_half)
	print("total: ", sprite_half + paddle_half)
	print("deon global_pos: ", global_position.x)
	print("paddle global_pos: ", paddle.global_position.x)
	print("actual gap: ", paddle.global_position.x - global_position.x)
	if global_position.x < paddle.global_position.x:
		return global_position.x + half_width + paddle_half
	else:
		return global_position.x - half_width - paddle_half

func start_action_timer()->void:
	timer.wait_time = action_timer
	timer.start()
	
