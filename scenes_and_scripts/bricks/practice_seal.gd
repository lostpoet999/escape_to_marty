class_name PracticeSeal
extends BaseSeal

const LINGER_GRACE: float = 0.15
const DEFAULT_REVERT_WINDOW: float = 1.0

@export var respawn_delay: float = 1.5
## Starts invisible, uncollidable, and OUT of the practice_seal group until reveal() is called — for rooms where a cutscene owns the early clicks.
@export var starts_hidden: bool = false

var _practice_stages: Dictionary[GameManager.PhaseType, float]
var _practice_armed: bool = false
var _poof_tween: Tween

@onready var _practice_collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if not starts_hidden:
		add_to_group(&"practice_seal")
	super()
	_practice_stages = stages.duplicate()
	_practice_armed = true
	if starts_hidden:
		hide()
		_practice_collision.set_deferred("disabled", true)

func reveal() -> void:
	if is_in_group(&"practice_seal"):
		return
	add_to_group(&"practice_seal")
	show()
	_practice_collision.set_deferred("disabled", false)

func pick_random_stage() -> void:
	super()
	if _practice_armed and stages.is_empty():
		_begin_practice_linger()

func accept_damage(damage: float, damage_types: Array) -> void:
	if _poof_pending() and damage_types.has(GameManager.PhaseType.HEALTH):
		super(damage, [])
		return
	super(damage, damage_types)

func restore_denial(full_health: float) -> void:
	_kill_poof_tween()
	super(full_health)

func _begin_practice_linger() -> void:
	_kill_poof_tween()
	_poof_tween = create_tween()
	_poof_tween.tween_interval(_revert_window() + LINGER_GRACE)
	_poof_tween.tween_callback(_practice_poof)

func _revert_window() -> float:
	var gestures: MouseGestures = get_tree().get_first_node_in_group(&"mouse_gestures") as MouseGestures
	if gestures == null:
		return DEFAULT_REVERT_WINDOW
	return gestures.denial_revert_window

func _poof_pending() -> bool:
	return _poof_tween != null and _poof_tween.is_valid()

func _kill_poof_tween() -> void:
	if _poof_pending():
		_poof_tween.kill()
	_poof_tween = null

func _grant_score(_stage: GameManager.PhaseType) -> void:
	pass

func resolve_bargain(bid: float) -> BargainOutcome:
	var sweet: Vector2 = bargain_sweet_range()
	var outcome: BargainOutcome = super(bid)
	if outcome == BargainOutcome.DEAL and bid >= sweet.x and bid <= sweet.y:
		PlayerData.play_gold_pickup_sfx()
	return outcome

func _practice_poof() -> void:
	_poof_tween = null
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
