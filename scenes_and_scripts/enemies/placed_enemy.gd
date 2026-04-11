class_name PlacedEnemy
extends CharacterBody2D

@export var action_pool: Array [EnemyActions]
@export var action_timer: float
@export var is_blocker: bool
@export var suppressed_on_respawn: bool
var timer: Timer
signal ready_to_remove(enemy: PlacedEnemy)

func _ready()->void:
	if is_blocker: Signalbus.blocker_added.emit(self)
	var duped: Array[EnemyActions] = []
	for action:EnemyActions in action_pool:
		duped.append(action.duplicate(true))
	action_pool = duped
	if timer == null:
		timer = Timer.new()
		self.add_child(timer)
	timer.timeout.connect(pick_action)
	timer.wait_time = action_timer	
	start_action_timer()

func _process(_delta: float) -> void:	
	if GameManager.current_state == GameManager.GameState.LEVEL_CLEARED:
		die()

func die()->void:
	if is_blocker: 
		Signalbus.blocker_removed.emit(self)
		ready_to_remove.emit(self)
		@warning_ignore("unsafe_method_access")
		get_viewport().get_camera_2d().add_trauma(2.0)
		SFX.play_sound("deon_die")
		queue_free()

func pick_action()->void:	
	if !action_pool.is_empty():
		var action:EnemyActions = action_pool.pick_random()
		action.execute_action(self)
		if is_blocker:
			if action.action_type == action.ActionTypes.Move: Signalbus.blocker_moved.emit()
		timer.wait_time = action_timer

func get_edge(paddle: Paddle) -> float:
	var sprite: Sprite2D = $EnemySprite
	var half_width: float = sprite.texture.get_width() * sprite.scale.x * scale.x / 2.0
	var paddle_half: float = paddle._get_scaled_half_width()	
	if global_position.x < paddle.global_position.x:
		return global_position.x + half_width + paddle_half
	else:
		return global_position.x - half_width - paddle_half

func start_action_timer()->void:
	timer.wait_time = action_timer
	timer.start()

func _on_ramming_collision_body_entered(body: Node2D) -> void:
	if body is Paddle:
		var paddle: Paddle = body
		if paddle.committed_distance > 300:
			die()	
			
