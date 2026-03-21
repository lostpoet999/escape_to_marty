extends Area2D

const STAR_COLLECTIBLE: PackedScene = preload("uid://cfjv2f23gme53")

@onready var brick_health_label: Label = $brick_health

@onready var border: ColorRect = $border
@onready var fill: ColorRect = $fill


@export var initialize_brick_on_leveldata: bool = true
@export var stages: Dictionary[GameManager.PhaseType, float]
var current_stage: GameManager.PhaseType
	
@export var brick_score_value: int = 5
@export var brick_health: int = 1
var health_temp: float
@export var brick_damage_fx: PackedScene
@export var brick_destroy_fx: PackedScene

func pick_random_stage() -> void:
	if stages.is_empty():
		current_stage = GameManager.PhaseType.HEALTH
		health_temp = brick_health
		setup_visuals()
		return
	
	var non_health_stages = stages.keys().filter(func(k): return k != GameManager.PhaseType.HEALTH)
	
	if non_health_stages.is_empty():
		current_stage = GameManager.PhaseType.HEALTH
	else:
		current_stage = non_health_stages.pick_random()
	
	health_temp = stages[current_stage]
	setup_visuals()

func setup_visuals()->void:
	match current_stage:
		GameManager.PhaseType.DENIAL:
			border.color = Color.DARK_GRAY
			fill.color = Color.BLACK
			return
		GameManager.PhaseType.ANGER:
			border.color = Color.LIGHT_PINK
			fill.color = Color.RED
			return
		GameManager.PhaseType.BARGAINING:
			border.color = Color.DARK_GOLDENROD
			fill.color = Color.DARK_KHAKI
		GameManager.PhaseType.DEPRESSION:
			border.color = Color.LIGHT_GRAY
			fill.color = Color.DARK_GRAY
		GameManager.PhaseType.ACCEPTANCE:
			border.color = Color.DARK_SEA_GREEN
			fill.color = Color.LIME_GREEN
		GameManager.PhaseType.HEALTH:
			border.color = Color.LIGHT_BLUE
			fill.color = Color.BLUE
			return
			
func _ready() -> void:	
	if initialize_brick_on_leveldata:#default is populate stages based on level stats		
		stages.clear()
		stages = SealInitializer.initialize_seal()		

	pick_random_stage()
	brick_health_label.text = str(health_temp)
	input_pickable = true	

func accept_damage(damage: float, damage_types: Array) -> void:
	if damage_types.has(current_stage):
		_damage_current_stage(damage)

func _damage_current_stage(damage: float) -> void:
	if health_temp - damage <= 0:
		var fx
		if current_stage == GameManager.PhaseType.HEALTH:
			fx = brick_destroy_fx.instantiate()
		else: fx = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		if current_stage == GameManager.PhaseType.HEALTH:
			pop_tween()
		else:
			stages.erase(current_stage)
			pick_random_stage()
			brick_health_label.text = str(health_temp)
	else:
		var fx = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		health_temp -= damage
		brick_health_label.text = str(health_temp)
	

func pop_tween() -> void:
	var tween: Tween = get_tree().create_tween()

	tween.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(.1, .1), 0.1).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.connect("finished", Callable(self, "_on_tween_finished").bind(self))

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		var click_dmg_type: Array[GameManager.PhaseType] = [GameManager.PhaseType.DENIAL, GameManager.PhaseType.ANGER]
		accept_damage(1, click_dmg_type)

#cleanup brick collision after tween finishes
func _on_tween_finished(collider: Area2D) -> void:
	if is_instance_valid(collider):
		PlayerData.update_player_score(brick_score_value)
		collider.queue_free()
		var star_instance: Area2D = STAR_COLLECTIBLE.instantiate()
		collider.get_parent().add_child(star_instance)
		star_instance.position = collider.position
		Signalbus.star_spawned.emit(1)
		Signalbus.brick_destroyed.emit()
