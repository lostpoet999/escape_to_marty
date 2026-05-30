class_name BallPassive extends BaseItem

# global magnitude levers — lift the shared ball_dmg pool that every behavior draws from.
@export_group("Global Damage")
@export var global_bonus: float = 0.0       # additive
@export var global_multi: float = 1.0       # multiplicative (default 1.0 — never zero the ball)

# what this passive does on a ball hit. layering = more behaviors here, not one behavior reconciling many.
@export_group("Behaviors")
@export var on_hit: Array[HitBehavior]

func _to_string() -> String:
	return powerup_name
