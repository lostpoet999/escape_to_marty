class_name MyDamageEffect extends BaseDamageEffect

#variables from the base class

#var ball_ref: Ball
#var collider_ref: Node2D
#var target: Node2D

#override this if you want to change how targeting works. for example you can add a collider to the scene for an ae effect
#func process_targets() -> void:
#	target = collider_ref #just the thing hit
#	apply_damage(target)

#override this if you want to change how this effect applies damage
#func apply_damage(damage_target: Node2D) -> void:
#	if damage_target.is_in_group("bricks"):
#		damage_target.call("accept_damage", ball_ref.ball_dmg)
#	elif damage_target.is_in_group("DeathWalls"):
#		ball_ref.position_ball_on_paddle()
#		PlayerData.accept_damage(int(ball_ref.ball_dmg))
