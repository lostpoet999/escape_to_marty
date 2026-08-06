class_name PracticeSeal
extends BaseSeal

@export var respawn_delay: float = 1.5

var _practice_stages: Dictionary[GameManager.PhaseType, float]
var _practice_armed: bool = false

func _ready() -> void:
	add_to_group(&"practice_seal")
	super()
	_practice_stages = stages.duplicate()
	_practice_armed = true

func pick_random_stage() -> void:
	if _practice_armed and stages.is_empty():
		_practice_poof()
		return
	super()

func _grant_score(_stage: GameManager.PhaseType) -> void:
	pass

func _practice_poof() -> void:
	dying = true
	if brick_destroy_fx != null:
		var fx: Node2D = brick_destroy_fx.instantiate()
		fx.position = global_position
		get_tree().current_scene.add_child(fx)
	if _knockback_tween != null:
		_knockback_tween.kill()
	if _glow_tween != null:
		_glow_tween.kill()
	_set_visual_offset(Vector2.ZERO)
	_set_glow(1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.1).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(hide)
	tween.tween_interval(respawn_delay)
	tween.tween_callback(_practice_respawn)

func _practice_respawn() -> void:
	stages = _practice_stages.duplicate()
	scale = Vector2.ONE
	show()
	dying = false
	pick_random_stage()
	_update_stage_label()
	_start_glow_breathe()
