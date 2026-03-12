class_name BallPowerUp extends BaseItem

@export_group("Base Stats")
@export var global_damage_bonus: float
@export var global_damage_multi: float
@export var local_damage_bonus: float
@export var local_damage_multi: float


@export_group("Damage Effects")
@export var attached_effects: Array[DamageEffectRef]

func _to_string() -> String:
	return powerup_name + powerup_name
