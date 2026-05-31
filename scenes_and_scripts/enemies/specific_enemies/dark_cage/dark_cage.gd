class_name DarkCage
extends FallingEnemy

@export var can_damage: bool = true
@export var damage: int = 1
@export var stun_time: float = 1.0
@export var stun_score: int = 5000

func _ready() -> void:
	super()
	SFX.play_sound("cage_spawn")

func on_hit_paddle(paddle: Node) -> void:
	# stop insta-death from damaging every frame
	if paddle.has_method("freeze_paddle_for_time"):
		paddle.freeze_paddle_for_time(stun_time)
	if can_damage:
		PlayerData.accept_damage(damage)
		_pause_falling()
		can_damage = false
		SFX.play_sound("cage_hit")
		queue_free()

func on_hit_enemy(enemy: Node) -> void:
	if enemy.has_method("stun_for_time"):
		enemy.stun_for_time(stun_time)
	if enemy.has_method("take_damage_fx"):
		enemy.take_damage_fx()
	PlayerData.update_player_score(stun_score)
	SFX.play_sound("cage_hit")
	on_fall_landed()
