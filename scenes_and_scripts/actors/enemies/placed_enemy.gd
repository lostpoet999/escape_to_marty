class_name PlacedEnemy
extends CharacterBody2D

const DAMAGE_NUMBER: PackedScene = preload("uid://bedvoohhfbi03")

@export var action_pool: Array [EnemyActions]
@export var action_timer: float
@export var is_blocker: bool
var timer: Timer
signal ready_to_remove(enemy: PlacedEnemy)

@onready var foot_1: Marker2D = $Foot1
@onready var foot_2: Marker2D = $Foot2
@onready var denial_active: bool = true
@export var denial_health: int = 3
@export var right_clamp_offset: int
@export var left_clamp_offset: int
var current_action: EnemyActions

func _ready()->void:
	if denial_active == true:
		self.modulate = Color.BLACK
		self.modulate.a = .2	
	Signalbus.jump_landed.connect(jump_land_shake)
	Signalbus.level_cleared.connect(die)
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

func accept_damage(_damage: float, _dmg_type: Array[GameManager.PhaseType])->void:
	SFX.play_sound("enemy_hurt")
	show_damage_number(1)
	denial_health -= 1
	if denial_health == 0:
		self.modulate = Color.WHITE
		self.modulate.a = 1.0
	elif denial_health <= -1: die()

func show_damage_number(amount: int) -> void:
	var dn: DamageNumber = DAMAGE_NUMBER.instantiate()
	dn.position = global_position
	dn.z_index = 2000
	get_tree().current_scene.add_child(dn)
	dn.show_damage("-" + str(amount), DamageNumber.COLOR_DEALT)


func die()->void:
	# guard against re-entry — boss path calls die() directly then emits level_cleared,
	# and the level_cleared sweep would otherwise re-fire all the side effects on the boss
	if is_queued_for_deletion(): return
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
		current_action = action
		action.execute_action(self)
		if is_blocker:
			if action.action_type == action.ActionTypes.Move: Signalbus.blocker_moved.emit()
		timer.wait_time = action_timer - randf_range(0.3,0.8)

func jump_land_shake()->void:
	get_viewport().get_camera_2d().add_trauma(0.7)

func get_edge(paddle: Paddle) -> float:
	var sprite: Sprite2D = $EnemySprite
	var half_width: float = sprite.texture.get_width() * sprite.scale.x * scale.x / 2.0
	var paddle_half: float = paddle._get_scaled_half_width()	
	if global_position.x < paddle.global_position.x:
		return global_position.x + half_width + paddle_half + left_clamp_offset
	else:
		return global_position.x - half_width - paddle_half - right_clamp_offset

func start_action_timer()->void:
	timer.wait_time = action_timer
	timer.start()

func stun_for_time(duration: float) -> void:
	if timer == null: return
	if current_action != null:
		current_action.cancel_to_origin(self)
	timer.stop()
	var original_modulate: Color = modulate
	var pulse_color: Color = Color(1.0, 0.25, 0.25, original_modulate.a)
	var pulse_tween: Tween = create_tween().set_loops()
	pulse_tween.tween_property(self, "modulate", pulse_color, 0.2)
	pulse_tween.tween_property(self, "modulate", original_modulate, 0.2)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):
		pulse_tween.kill()
		modulate = original_modulate
		start_action_timer()
