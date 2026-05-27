class_name BaseSeal
extends Area2D

const STAR_COLLECTIBLE: PackedScene = preload("uid://cfjv2f23gme53")
const DAMAGE_NUMBER: PackedScene = preload("res://scenes_and_scripts/enemies/vfx/damage_number.tscn")

const PHASE_SCORES: Dictionary[GameManager.PhaseType, int] = {
	GameManager.PhaseType.DENIAL: 100,
	GameManager.PhaseType.ANGER: 150,
	GameManager.PhaseType.BARGAINING: 200,
	GameManager.PhaseType.DEPRESSION: 250,
	GameManager.PhaseType.ACCEPTANCE: 300,
	GameManager.PhaseType.HEALTH: 500,
}

@onready var brick_health_label: Label = $brick_health

@onready var gemstone_facets: Sprite2D = $"gemstone-facets"

@export var initialize_brick_on_leveldata: bool = true
@export var stages: Dictionary[GameManager.PhaseType, float]
var current_stage: GameManager.PhaseType
	
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
	
	var non_health_stages: Array = stages.keys().filter(func(k:GameManager.PhaseType)->bool: return k != GameManager.PhaseType.HEALTH)
	
	if non_health_stages.is_empty():
		current_stage = GameManager.PhaseType.HEALTH
	else:
		current_stage = non_health_stages.pick_random()
	
	health_temp = stages[current_stage]
	setup_visuals()

func setup_visuals()->void:
	match current_stage:
		GameManager.PhaseType.DENIAL:
			gemstone_facets.modulate = Color(0.1, 0.05, 0.15)
		GameManager.PhaseType.ANGER:
			gemstone_facets.modulate = Color.RED
		GameManager.PhaseType.BARGAINING:
			gemstone_facets.modulate = Color.DARK_KHAKI
		GameManager.PhaseType.DEPRESSION:
			gemstone_facets.modulate = Color.DARK_GRAY
		GameManager.PhaseType.ACCEPTANCE:
			gemstone_facets.modulate = Color.LIME_GREEN
		GameManager.PhaseType.HEALTH:
			gemstone_facets.modulate = Color.BLUE
			
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
		var fx: Node2D
		if current_stage == GameManager.PhaseType.HEALTH:
			fx = brick_destroy_fx.instantiate()
		else: fx = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		PlayerData.update_player_score(PHASE_SCORES[current_stage])
		if current_stage == GameManager.PhaseType.HEALTH:
			pop_tween()
		else:
			stages.erase(current_stage)
			pick_random_stage()
			brick_health_label.text = str(health_temp)
	else:
		var fx: Node2D = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		health_temp -= damage
		brick_health_label.text = str(health_temp)
	var damage_number = DAMAGE_NUMBER.instantiate()
	damage_number.position = global_position
	get_tree().current_scene.add_child(damage_number)
	

func pop_tween() -> void:
	var tween: Tween = get_tree().create_tween()

	tween.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(.1, .1), 0.1).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.connect("finished", Callable(self, "_on_tween_finished").bind(self))

#cleanup brick collision after tween finishes
func _on_tween_finished(collider: Area2D) -> void:
	if is_instance_valid(collider):
		collider.queue_free()
		var star_instance: Area2D = STAR_COLLECTIBLE.instantiate()
		collider.get_parent().add_child(star_instance)
		star_instance.position = collider.position
		Signalbus.star_spawned.emit(1)
		Signalbus.enemy_requested.emit(collider)
		Signalbus.brick_destroyed.emit()
